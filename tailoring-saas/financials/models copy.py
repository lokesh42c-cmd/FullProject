"""
Financials app models - GST Compliant Financial Management
Date: 2026-01-03

Based on complete_understanding_document.pdf
- ReceiptVoucher: Advance payments with GST (before invoice)
- Payment: Payments against invoices (after invoice)
- RefundVoucher: Refunds with GST reversal
"""

from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from decimal import Decimal
from core.managers import TenantManager


# ==================== RECEIPT VOUCHER MODEL ====================

class ReceiptVoucher(models.Model):
    """
    Receipt Voucher - Advance payment with GST
    Collected before or during order creation
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='receipt_vouchers'
    )
    
    # Voucher Identity
    voucher_number = models.CharField(max_length=50, unique=True, verbose_name='Receipt Voucher Number')
    receipt_date = models.DateField(default=timezone.now, verbose_name='Receipt Date')
    
    # Customer
    customer = models.ForeignKey(
        'orders.Customer',
        on_delete=models.PROTECT,
        related_name='receipt_vouchers',
        verbose_name='Customer'
    )
    
    # Optional Order Link (can be collected before order is created)
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='receipt_vouchers',
        verbose_name='Order',
        help_text='Optional - link to order if advance is for specific order'
    )
    
    # Advance Amount (before GST)
    advance_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Advance Amount (excl. GST)'
    )
    
    # GST Calculation
    gst_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('18.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='GST Rate %',
        help_text='GST rate applicable on advance'
    )
    
    # Tax Type (determined by business state vs customer state)
    TAX_TYPE_CHOICES = [
        ('INTRASTATE', 'Intrastate (CGST + SGST)'),
        ('INTERSTATE', 'Interstate (IGST)'),
        ('ZERO', 'Zero GST'),
    ]
    tax_type = models.CharField(
        max_length=20,
        choices=TAX_TYPE_CHOICES,
        verbose_name='Tax Type'
    )
    
    # Tax Amounts
    cgst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='CGST Amount'
    )
    
    sgst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='SGST Amount'
    )
    
    igst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='IGST Amount'
    )
    
    total_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total Amount (incl. GST)'
    )
    
    # Payment Details
    PAYMENT_MODE_CHOICES = [
        ('CASH', 'Cash'),
        ('UPI', 'UPI'),
        ('CARD', 'Card'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('CHEQUE', 'Cheque'),
    ]
    payment_mode = models.CharField(
        max_length=20,
        choices=PAYMENT_MODE_CHOICES,
        verbose_name='Payment Mode'
    )
    
    # For cash payments - track bank deposit
    deposited_to_bank = models.BooleanField(
        default=False,
        verbose_name='Deposited to Bank',
        help_text='For cash payments - mark when deposited to bank'
    )
    deposit_date = models.DateField(
        null=True,
        blank=True,
        verbose_name='Bank Deposit Date'
    )
    
    # Transaction reference
    transaction_reference = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Transaction Reference',
        help_text='UPI ID, Card last 4 digits, Cheque number, etc.'
    )
    
    # Adjustment tracking
    adjusted_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Amount Adjusted'
    )
    
    remaining_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Remaining Amount'
    )
    
    # Notes
    notes = models.TextField(blank=True, verbose_name='Notes')
    
    # Immutability - cannot edit after issue
    is_issued = models.BooleanField(default=True, verbose_name='Issued')
    
    # Audit Trail
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='receipts_created',
        verbose_name='Created By'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Receipt Voucher"
        verbose_name_plural = "Receipt Vouchers"
        ordering = ['-receipt_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'voucher_number']),
            models.Index(fields=['tenant', 'customer']),
            models.Index(fields=['tenant', 'receipt_date']),
        ]
    
    def __str__(self):
        return f"{self.voucher_number} - {self.customer.name} - ₹{self.total_amount}"
    
    @property
    def is_adjusted(self):
        """Check if advance has been adjusted"""
        return self.adjusted_amount > Decimal('0.00')
    
    def save(self, *args, **kwargs):
        # Auto-generate voucher number if not provided
        if not self.voucher_number:
            from django.utils import timezone
            year_month = timezone.now().strftime('%Y%m')
            last_voucher = ReceiptVoucher.objects.filter(
                tenant=self.tenant,
                voucher_number__startswith=f'RV-{year_month}'
            ).order_by('-voucher_number').first()
            
            if last_voucher:
                last_num = int(last_voucher.voucher_number.split('-')[-1])
                new_num = last_num + 1
            else:
                new_num = 1
            
            self.voucher_number = f'RV-{year_month}-{new_num:05d}'
        
        # Determine tax type based on states
        if self.customer.state and hasattr(self.tenant, 'state'):
            if self.customer.state == self.tenant.state:
                self.tax_type = 'INTRASTATE'
            else:
                self.tax_type = 'INTERSTATE'
        
        # Check if GST applies based on tenant and rate
        if not hasattr(self.tenant, 'gst_enabled') or not self.tenant.gst_enabled or self.gst_rate == 0:
            self.tax_type = 'ZERO'
        
        # Calculate GST amounts
        if self.tax_type == 'INTRASTATE':
            # Split GST into CGST and SGST
            half_rate = self.gst_rate / 2
            self.cgst_amount = (self.advance_amount * half_rate) / Decimal('100')
            self.sgst_amount = (self.advance_amount * half_rate) / Decimal('100')
            self.igst_amount = Decimal('0.00')
        elif self.tax_type == 'INTERSTATE':
            # Full GST as IGST
            self.cgst_amount = Decimal('0.00')
            self.sgst_amount = Decimal('0.00')
            self.igst_amount = (self.advance_amount * self.gst_rate) / Decimal('100')
        else:  # ZERO
            self.cgst_amount = Decimal('0.00')
            self.sgst_amount = Decimal('0.00')
            self.igst_amount = Decimal('0.00')
        
        # Calculate total
        self.total_amount = self.advance_amount + self.cgst_amount + self.sgst_amount + self.igst_amount
        
        # Calculate remaining amount
        self.remaining_amount = self.total_amount - self.adjusted_amount
        
        super().save(*args, **kwargs)


# ==================== PAYMENT MODEL ====================

class Payment(models.Model):
    """
    Payment against invoice
    Tracks payments received after invoice is issued
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='payments'
    )
    
    # Payment Identity
    payment_number = models.CharField(max_length=50, unique=True, verbose_name='Payment Number')
    payment_date = models.DateField(default=timezone.now, verbose_name='Payment Date')
    
    # Invoice Link
    invoice = models.ForeignKey(
        'invoicing.Invoice',
        on_delete=models.PROTECT,
        related_name='payments',
        verbose_name='Invoice'
    )
    
    # Payment Amount
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Payment Amount'
    )
    
    # Payment Details
    PAYMENT_MODE_CHOICES = [
        ('CASH', 'Cash'),
        ('UPI', 'UPI'),
        ('CARD', 'Card'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('CHEQUE', 'Cheque'),
    ]
    payment_mode = models.CharField(
        max_length=20,
        choices=PAYMENT_MODE_CHOICES,
        verbose_name='Payment Mode'
    )
    
    # For cash payments - track bank deposit
    deposited_to_bank = models.BooleanField(
        default=False,
        verbose_name='Deposited to Bank',
        help_text='For cash payments - mark when deposited to bank'
    )
    deposit_date = models.DateField(
        null=True,
        blank=True,
        verbose_name='Bank Deposit Date'
    )
    
    # Transaction reference
    transaction_reference = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Transaction Reference',
        help_text='UPI ID, Card last 4 digits, Cheque number, etc.'
    )
    
    # Notes
    notes = models.TextField(blank=True, verbose_name='Notes')
    
    # Audit Trail
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='payments_created',
        verbose_name='Created By'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Payment"
        verbose_name_plural = "Payments"
        ordering = ['-payment_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'payment_number']),
            models.Index(fields=['tenant', 'invoice']),
            models.Index(fields=['tenant', 'payment_date']),
        ]
    
    def __str__(self):
        return f"{self.payment_number} - {self.invoice.invoice_number} - ₹{self.amount}"
    
    def save(self, *args, **kwargs):
        # Auto-generate payment number if not provided
        if not self.payment_number:
            from django.utils import timezone
            year_month = timezone.now().strftime('%Y%m')
            last_payment = Payment.objects.filter(
                tenant=self.tenant,
                payment_number__startswith=f'PAY-{year_month}'
            ).order_by('-payment_number').first()
            
            if last_payment:
                last_num = int(last_payment.payment_number.split('-')[-1])
                new_num = last_num + 1
            else:
                new_num = 1
            
            self.payment_number = f'PAY-{year_month}-{new_num:05d}'
        
        super().save(*args, **kwargs)
        
        # Update invoice payment tracking
        self.invoice.total_paid = self.invoice.payments.aggregate(
            total=models.Sum('amount')
        )['total'] or Decimal('0.00')
        self.invoice.calculate_totals()


# ==================== REFUND VOUCHER MODEL ====================

class RefundVoucher(models.Model):
    """
    Refund Voucher - GST Credit Note for advances
    Reverses GST when refunding advance payments
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='refund_vouchers'
    )
    
    # Voucher Identity
    refund_number = models.CharField(max_length=50, unique=True, verbose_name='Refund Voucher Number')
    refund_date = models.DateField(default=timezone.now, verbose_name='Refund Date')
    
    # Original Receipt Voucher
    receipt_voucher = models.ForeignKey(
        ReceiptVoucher,
        on_delete=models.PROTECT,
        related_name='refunds',
        verbose_name='Original Receipt Voucher'
    )
    
    # Customer
    customer = models.ForeignKey(
        'orders.Customer',
        on_delete=models.PROTECT,
        related_name='refunds',
        verbose_name='Customer'
    )
    
    # Refund Amount (before GST reversal)
    refund_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Refund Amount (excl. GST)'
    )
    
    # GST Reversal (copied from original receipt)
    gst_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        verbose_name='GST Rate %'
    )
    
    tax_type = models.CharField(
        max_length=20,
        choices=ReceiptVoucher.TAX_TYPE_CHOICES,
        verbose_name='Tax Type'
    )
    
    # Tax Amounts (reversal)
    cgst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='CGST Amount (Reversed)'
    )
    
    sgst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='SGST Amount (Reversed)'
    )
    
    igst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='IGST Amount (Reversed)'
    )
    
    total_refund = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total Refund (incl. GST reversal)'
    )
    
    # Refund Method
    REFUND_MODE_CHOICES = [
        ('CASH', 'Cash'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('UPI', 'UPI'),
    ]
    refund_mode = models.CharField(
        max_length=20,
        choices=REFUND_MODE_CHOICES,
        verbose_name='Refund Mode'
    )
    
    # Transaction reference
    transaction_reference = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Transaction Reference'
    )
    
    # Reason for refund
    reason = models.TextField(verbose_name='Reason for Refund')
    
    # Notes
    notes = models.TextField(blank=True, verbose_name='Notes')
    
    # Audit Trail
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='refunds_created',
        verbose_name='Created By'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Refund Voucher"
        verbose_name_plural = "Refund Vouchers"
        ordering = ['-refund_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'refund_number']),
            models.Index(fields=['tenant', 'customer']),
            models.Index(fields=['tenant', 'refund_date']),
        ]
    
    def __str__(self):
        return f"{self.refund_number} - {self.customer.name} - ₹{self.total_refund}"
    
    def save(self, *args, **kwargs):
        # Auto-generate refund number if not provided
        if not self.refund_number:
            from django.utils import timezone
            year_month = timezone.now().strftime('%Y%m')
            last_refund = RefundVoucher.objects.filter(
                tenant=self.tenant,
                refund_number__startswith=f'RF-{year_month}'
            ).order_by('-refund_number').first()
            
            if last_refund:
                last_num = int(last_refund.refund_number.split('-')[-1])
                new_num = last_num + 1
            else:
                new_num = 1
            
            self.refund_number = f'RF-{year_month}-{new_num:05d}'
        
        # Copy tax details from receipt voucher
        self.gst_rate = self.receipt_voucher.gst_rate
        self.tax_type = self.receipt_voucher.tax_type
        
        # Calculate GST reversal
        if self.tax_type == 'INTRASTATE':
            half_rate = self.gst_rate / 2
            self.cgst_amount = (self.refund_amount * half_rate) / Decimal('100')
            self.sgst_amount = (self.refund_amount * half_rate) / Decimal('100')
            self.igst_amount = Decimal('0.00')
        elif self.tax_type == 'INTERSTATE':
            self.cgst_amount = Decimal('0.00')
            self.sgst_amount = Decimal('0.00')
            self.igst_amount = (self.refund_amount * self.gst_rate) / Decimal('100')
        else:  # ZERO
            self.cgst_amount = Decimal('0.00')
            self.sgst_amount = Decimal('0.00')
            self.igst_amount = Decimal('0.00')
        
        # Calculate total refund
        self.total_refund = self.refund_amount + self.cgst_amount + self.sgst_amount + self.igst_amount
        
        super().save(*args, **kwargs)