"""
Invoicing app models - With Dynamic Balance Calculation + DISCOUNT SUPPORT
Date: 2026-02-02
UPDATED: Added discount field to InvoiceItem + Added PRODUCT to item_type choices
"""

from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from decimal import Decimal
from core.managers import TenantManager


class Invoice(models.Model):
    """GST-Compliant Invoice"""
    
    tenant = models.ForeignKey('core.Tenant', on_delete=models.CASCADE, related_name='invoices')
    invoice_number = models.CharField(max_length=50, unique=True, verbose_name='Invoice Number')
    invoice_date = models.DateField(default=timezone.now, verbose_name='Invoice Date')
    customer = models.ForeignKey('orders.Customer', on_delete=models.PROTECT, related_name='invoices')
    
    order = models.OneToOneField(
        'orders.Order',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='invoice',
        verbose_name='Order'
    )
    
    STATUS_CHOICES = [('DRAFT', 'Draft'), ('ISSUED', 'Issued'), ('PAID', 'Paid'), ('CANCELLED', 'Cancelled')]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    
    # Billing/Shipping fields
    billing_name = models.CharField(max_length=200)
    billing_address = models.TextField()
    billing_city = models.CharField(max_length=100, blank=True)
    billing_state = models.CharField(max_length=100)
    billing_pincode = models.CharField(max_length=10, blank=True)
    billing_gstin = models.CharField(max_length=15, blank=True)
    shipping_name = models.CharField(max_length=200, blank=True)
    shipping_address = models.TextField(blank=True)
    shipping_city = models.CharField(max_length=100, blank=True)
    shipping_state = models.CharField(max_length=100, blank=True)
    shipping_pincode = models.CharField(max_length=10, blank=True)
    
    TAX_TYPE_CHOICES = [('INTRASTATE', 'Intrastate'), ('INTERSTATE', 'Interstate'), ('ZERO', 'Zero GST')]
    tax_type = models.CharField(max_length=20, choices=TAX_TYPE_CHOICES)
    
    # Amounts
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_cgst = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_sgst = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_igst = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    grand_total = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    
    # These will be updated by calculate_totals()
    total_advance_adjusted = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    balance_due = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_paid = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    remaining_balance = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    
    PAYMENT_STATUS_CHOICES = [('UNPAID', 'Unpaid'), ('PARTIAL', 'Partially Paid'), ('PAID', 'Paid')]
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='UNPAID')
    
    notes = models.TextField(blank=True)
    terms_and_conditions = models.TextField(blank=True)
    created_by = models.ForeignKey('core.User', on_delete=models.SET_NULL, null=True, related_name='invoices_created')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Invoice"
        verbose_name_plural = "Invoices"
        ordering = ['-invoice_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'invoice_number']),
            models.Index(fields=['tenant', 'customer']),
            models.Index(fields=['tenant', 'status']),
            models.Index(fields=['tenant', 'invoice_date']),
        ]
    
    def __str__(self):
        return f"{self.invoice_number} - {self.customer.name}"
    
    def save(self, *args, **kwargs):
            """
            Auto-generate FY-based invoice number if not provided
            Format: INV[FY]-[SEQ]
            
            Financial Year in India: April 1 to March 31
            Example:
            - Feb 2026 → FY 2025-26 → INV2526-1
            - Apr 2026 → FY 2026-27 → INV2627-1
            """
            if not self.invoice_number:
                from django.utils import timezone
                
                today = timezone.now().date()
                
                # Calculate Financial Year
                if today.month >= 4:  # April or later
                    fy_start = today.year
                    fy_end = today.year + 1
                else:  # January to March
                    fy_start = today.year - 1
                    fy_end = today.year
                
                # Format: Last 2 digits of each year (e.g., 2526 for 2025-26)
                fy_code = f"{fy_start % 100}{fy_end % 100}"
                
                # Get last invoice for this FY
                last_invoice = Invoice.objects.filter(
                    tenant=self.tenant,
                    invoice_number__startswith=f'INV{fy_code}-'
                ).order_by('-invoice_number').first()
                
                # Calculate next sequence number
                if last_invoice:
                    # Extract sequence from "INV2526-15" → 15
                    try:
                        last_seq = int(last_invoice.invoice_number.split('-')[-1])
                        new_seq = last_seq + 1
                    except (ValueError, IndexError):
                        new_seq = 1
                else:
                    # First invoice of this FY
                    new_seq = 1
                
                # Generate invoice number: INV2526-1
                self.invoice_number = f'INV{fy_code}-{new_seq}'
            
            # Auto-detect tax type from billing state
            if self.billing_state and hasattr(self.tenant, 'state'):
                if self.billing_state == self.tenant.state:
                    self.tax_type = 'INTRASTATE'
                else:
                    self.tax_type = 'INTERSTATE'
            
            # Check if GST is enabled
            if not hasattr(self.tenant, 'gst_enabled') or not self.tenant.gst_enabled:
                self.tax_type = 'ZERO'
            
            super().save(*args, **kwargs)
            
    def calculate_totals(self):
        """✅ FIXED: Calculate all totals dynamically including advances and refunds"""
        from financials.models import ReceiptVoucher, Payment, RefundVoucher
        
        # Calculate from items
        items = self.items.all()
        self.subtotal = sum(item.subtotal for item in items)
        self.total_cgst = sum(item.cgst_amount for item in items)
        self.total_sgst = sum(item.sgst_amount for item in items)
        self.total_igst = sum(item.igst_amount for item in items)
        self.grand_total = self.subtotal + self.total_cgst + self.total_sgst + self.total_igst
        
        # Calculate advances (receipts - refunds)
        advances = Decimal('0.00')
        if self.order:
            receipts = ReceiptVoucher.objects.filter(order=self.order, tenant=self.tenant)
            for receipt in receipts:
                advances += receipt.total_amount
            
            # ✅ Subtract refunds
            refunds = RefundVoucher.objects.filter(receipt_voucher__order=self.order, tenant=self.tenant)
            for refund in refunds:
                advances -= refund.total_refund
        
        self.total_advance_adjusted = advances
        self.balance_due = self.grand_total - self.total_advance_adjusted
        
        # Calculate invoice payments
        payments = Payment.objects.filter(invoice=self, tenant=self.tenant)
        self.total_paid = sum(p.amount for p in payments)
        
        # Calculate remaining balance
        self.remaining_balance = self.balance_due - self.total_paid
        
        # Update payment status
        if self.total_paid == 0:
            self.payment_status = 'UNPAID'
        elif self.total_paid < self.balance_due:
            self.payment_status = 'PARTIAL'
        else:
            self.payment_status = 'PAID'
            if self.status == 'ISSUED':
                self.status = 'PAID'
        
        self.save()


class InvoiceItem(models.Model):
    """Invoice line items - UPDATED with discount support"""
    
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='items')
    item = models.ForeignKey('orders.Item', on_delete=models.PROTECT, null=True, blank=True, related_name='invoice_items')
    item_description = models.CharField(max_length=255)
    hsn_sac_code = models.CharField(max_length=20, blank=True)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('1.00'), validators=[MinValueValidator(Decimal('0.01'))])
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'), validators=[MinValueValidator(Decimal('0.00'))])
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'), validators=[MinValueValidator(Decimal('0.00'))])  # ✅ ADDED
    gst_rate = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'), validators=[MinValueValidator(Decimal('0.00'))])
    
    ITEM_TYPE_CHOICES = [('PRODUCT', 'Product'), ('SERVICE', 'Service')]  # ✅ SIMPLIFIED: Only PRODUCT and SERVICE
    item_type = models.CharField(max_length=10, choices=ITEM_TYPE_CHOICES, default='SERVICE')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Invoice Item"
        verbose_name_plural = "Invoice Items"
        ordering = ['id']
    
    def __str__(self):
        return f"{self.invoice.invoice_number} - {self.item_description}"
    
    @property
    def subtotal(self):
        """Subtotal after discount: (qty × price) - discount"""
        return (self.quantity * self.unit_price) - self.discount  # ✅ UPDATED
    
    @property
    def cgst_amount(self):
        if self.invoice.tax_type == 'INTRASTATE' and self.gst_rate > 0:
            return (self.subtotal * self.gst_rate / 2) / Decimal('100')
        return Decimal('0.00')
    
    @property
    def sgst_amount(self):
        if self.invoice.tax_type == 'INTRASTATE' and self.gst_rate > 0:
            return (self.subtotal * self.gst_rate / 2) / Decimal('100')
        return Decimal('0.00')
    
    @property
    def igst_amount(self):
        if self.invoice.tax_type == 'INTERSTATE' and self.gst_rate > 0:
            return (self.subtotal * self.gst_rate) / Decimal('100')
        return Decimal('0.00')
    
    @property
    def total_tax(self):
        return self.cgst_amount + self.sgst_amount + self.igst_amount
    
    @property
    def total_amount(self):
        return self.subtotal + self.total_tax
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self.invoice.calculate_totals()