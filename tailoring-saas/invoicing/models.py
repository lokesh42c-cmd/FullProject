"""
Invoicing app models - GST Compliant Invoice Management
Date: 2026-01-03

Based on complete_understanding_document.pdf
- Invoice is the final GST-compliant bill
- Can be created from Order OR standalone (walk-in)
- Links to ReceiptVouchers for advance adjustment
- Payments tracked separately in financials app
"""

from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from decimal import Decimal
from core.managers import TenantManager


# ==================== INVOICE MODEL ====================

class Invoice(models.Model):
    """
    GST-Compliant Invoice
    Final bill for goods/services delivered
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='invoices'
    )
    
    # Invoice Identity
    invoice_number = models.CharField(max_length=50, unique=True, verbose_name='Invoice Number')
    invoice_date = models.DateField(default=timezone.now, verbose_name='Invoice Date')
    
    # Customer
    customer = models.ForeignKey(
        'orders.Customer',
        on_delete=models.PROTECT,
        related_name='invoices',
        verbose_name='Customer'
    )
    
    # Optional Order Link (null for walk-in invoices)
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='invoices',
        verbose_name='Order',
        help_text='Optional - link to order if invoice created from order'
    )
    
    # Invoice Status
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('ISSUED', 'Issued'),
        ('PAID', 'Paid'),
        ('CANCELLED', 'Cancelled'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='DRAFT',
        verbose_name='Invoice Status'
    )
    
    # Billing Address (stored at invoice time for immutability)
    billing_name = models.CharField(max_length=200, verbose_name='Billing Name')
    billing_address = models.TextField(verbose_name='Billing Address')
    billing_city = models.CharField(max_length=100, blank=True)
    billing_state = models.CharField(max_length=100, verbose_name='Billing State')
    billing_pincode = models.CharField(max_length=10, blank=True)
    billing_gstin = models.CharField(max_length=15, blank=True, verbose_name='Customer GSTIN')
    
    # Shipping Address (can be same as billing or different)
    shipping_name = models.CharField(max_length=200, blank=True, verbose_name='Shipping Name')
    shipping_address = models.TextField(blank=True, verbose_name='Shipping Address')
    shipping_city = models.CharField(max_length=100, blank=True)
    shipping_state = models.CharField(max_length=100, blank=True, verbose_name='Shipping State')
    shipping_pincode = models.CharField(max_length=10, blank=True)
    
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
    
    # Amounts (calculated from items)
    subtotal = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Subtotal (before tax)'
    )
    
    total_cgst = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total CGST'
    )
    
    total_sgst = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total SGST'
    )
    
    total_igst = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total IGST'
    )
    
    grand_total = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Grand Total'
    )
    
    # Advance Adjustment (from ReceiptVouchers)
    total_advance_adjusted = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total Advance Adjusted'
    )
    
    # Balance Due (grand_total - total_advance_adjusted - total_paid)
    balance_due = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Balance Due'
    )
    
    # Payment Tracking (from financials.Payment)
    total_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total Paid'
    )
    
    remaining_balance = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Remaining Balance'
    )
    
    # Payment Status (calculated)
    PAYMENT_STATUS_CHOICES = [
        ('UNPAID', 'Unpaid'),
        ('PARTIAL', 'Partially Paid'),
        ('PAID', 'Paid'),
    ]
    payment_status = models.CharField(
        max_length=20,
        choices=PAYMENT_STATUS_CHOICES,
        default='UNPAID',
        verbose_name='Payment Status'
    )
    
    # Notes
    notes = models.TextField(blank=True, verbose_name='Notes')
    terms_and_conditions = models.TextField(blank=True, verbose_name='Terms & Conditions')
    
    # Audit Trail
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='invoices_created',
        verbose_name='Created By'
    )
    
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
        # Auto-generate invoice number if not provided
        if not self.invoice_number:
            from django.utils import timezone
            year_month = timezone.now().strftime('%Y%m')
            last_invoice = Invoice.objects.filter(
                tenant=self.tenant,
                invoice_number__startswith=f'INV-{year_month}'
            ).order_by('-invoice_number').first()
            
            if last_invoice:
                last_num = int(last_invoice.invoice_number.split('-')[-1])
                new_num = last_num + 1
            else:
                new_num = 1
            
            self.invoice_number = f'INV-{year_month}-{new_num:05d}'
        
        # Determine tax type based on states
        if self.billing_state and hasattr(self.tenant, 'state'):
            if self.billing_state == self.tenant.state:
                self.tax_type = 'INTRASTATE'
            else:
                self.tax_type = 'INTERSTATE'
        
        # Check if GST applies based on tenant GST registration
        if not hasattr(self.tenant, 'gst_enabled') or not self.tenant.gst_enabled:
            self.tax_type = 'ZERO'
        
        super().save(*args, **kwargs)
    
    def calculate_totals(self):
        """Calculate all totals from invoice items"""
        items = self.items.all()
        
        self.subtotal = sum(item.subtotal for item in items)
        self.total_cgst = sum(item.cgst_amount for item in items)
        self.total_sgst = sum(item.sgst_amount for item in items)
        self.total_igst = sum(item.igst_amount for item in items)
        
        self.grand_total = self.subtotal + self.total_cgst + self.total_sgst + self.total_igst
        
        # Calculate balance due
        self.balance_due = self.grand_total - self.total_advance_adjusted
        
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


# ==================== INVOICE ITEM MODEL ====================

class InvoiceItem(models.Model):
    """
    Invoice line items with GST calculation
    """
    
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name='Invoice'
    )
    
    # Item Details
    item = models.ForeignKey(
        'orders.Item',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='invoice_items',
        verbose_name='Item'
    )
    
    item_description = models.CharField(max_length=255, verbose_name='Description')
    hsn_sac_code = models.CharField(max_length=20, blank=True, verbose_name='HSN/SAC Code')
    
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('1.00'),
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Quantity'
    )
    
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Unit Price'
    )
    
    # GST Rate (percentage)
    gst_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='GST Rate %'
    )
    
    # Item Type (for GST calculation)
    ITEM_TYPE_CHOICES = [
        ('GOODS', 'Goods'),
        ('SERVICE', 'Service'),
    ]
    item_type = models.CharField(
        max_length=10,
        choices=ITEM_TYPE_CHOICES,
        default='SERVICE',
        verbose_name='Item Type'
    )
    
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
        """Subtotal before tax"""
        return self.quantity * self.unit_price
    
    @property
    def cgst_amount(self):
        """CGST amount (for intrastate)"""
        if self.invoice.tax_type == 'INTRASTATE' and self.gst_rate > 0:
            return (self.subtotal * self.gst_rate / 2) / Decimal('100')
        return Decimal('0.00')
    
    @property
    def sgst_amount(self):
        """SGST amount (for intrastate)"""
        if self.invoice.tax_type == 'INTRASTATE' and self.gst_rate > 0:
            return (self.subtotal * self.gst_rate / 2) / Decimal('100')
        return Decimal('0.00')
    
    @property
    def igst_amount(self):
        """IGST amount (for interstate)"""
        if self.invoice.tax_type == 'INTERSTATE' and self.gst_rate > 0:
            return (self.subtotal * self.gst_rate) / Decimal('100')
        return Decimal('0.00')
    
    @property
    def total_tax(self):
        """Total tax amount"""
        return self.cgst_amount + self.sgst_amount + self.igst_amount
    
    @property
    def total_amount(self):
        """Total including tax"""
        return self.subtotal + self.total_tax
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Recalculate invoice totals when item changes
        self.invoice.calculate_totals()