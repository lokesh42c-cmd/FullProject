"""
Purchase Management Models
Complete implementation following TailorPro standards
Created: 30-Dec-2025
"""

from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator, FileExtensionValidator
from django.core.exceptions import ValidationError
from decimal import Decimal
from core.managers import TenantManager
from datetime import date


def validate_phone_number(value):
    """
    Validate phone number:
    - Must be exactly 10 digits
    - Only numbers allowed
    - Empty is OK for optional fields
    """
    if not value:
        return  # Allow empty for optional fields
    
    # Remove whitespace
    cleaned = value.strip()
    
    # Check if only digits
    if not cleaned.isdigit():
        raise ValidationError(
            'Phone number must contain only digits (0-9).',
            code='invalid_phone_format'
        )
    
    # Check length
    if len(cleaned) != 10:
        raise ValidationError(
            f'Phone number must be exactly 10 digits. You entered {len(cleaned)} digits.',
            code='invalid_phone_length'
        )


def validate_image_size(image):
    """Validate image file size - max 5MB"""
    max_size_mb = 5
    if image.size > max_size_mb * 1024 * 1024:
        raise ValidationError(
            f'Image file size cannot exceed {max_size_mb}MB. Current size: {image.size / (1024 * 1024):.2f}MB'
        )


# ==================== VENDOR MODEL ====================

class Vendor(models.Model):
    """
    Vendor/Supplier Model
    Stores vendor information and tracks outstanding balances
    """
    
    # Tenant (CRITICAL - Multi-tenant)
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='vendors',
        verbose_name='Tenant'
    )
    
    # Basic Information
    name = models.CharField(
        max_length=200,
        verbose_name='Vendor Name',
        help_text='Primary contact person name'
    )
    
    phone = models.CharField(
        max_length=15,
        blank=True,  # Optional as per requirement
        validators=[validate_phone_number],
        verbose_name='Phone Number',
        help_text='Primary contact number (10 digits, optional)'
    )
    
    alternate_phone = models.CharField(
        max_length=15,
        blank=True,
        validators=[validate_phone_number],
        verbose_name='Alternate Phone',
        help_text='Alternate contact number (10 digits, optional)'
    )
    
    email = models.EmailField(
        blank=True,
        null=True,
        verbose_name='Email'
    )
    
    # Business Information
    business_name = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Business Name',
        help_text='Company/Shop name'
    )
    
    gstin = models.CharField(
        max_length=15,
        blank=True,
        null=True,
        verbose_name='GSTIN',
        help_text='GST Identification Number'
    )
    
    pan = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        verbose_name='PAN',
        help_text='PAN Number'
    )
    
    # Address
    address_line1 = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='Address Line 1'
    )
    
    address_line2 = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='Address Line 2'
    )
    
    city = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='City'
    )
    
    state = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='State'
    )
    
    pincode = models.CharField(
        max_length=6,
        blank=True,
        verbose_name='Pincode'
    )
    
    # Payment Terms
    payment_terms_days = models.IntegerField(
        default=0,
        verbose_name='Payment Terms',
        help_text='Payment due in days (0 = immediate)'
    )
    
    # Calculated Fields (updated by signals)
    total_purchases = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total Purchases',
        help_text='Total amount of all bills'
    )
    
    total_paid = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total Paid',
        help_text='Total amount paid to vendor'
    )
    
    outstanding_balance = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Outstanding Balance',
        help_text='Amount still owed to vendor'
    )
    
    # Meta
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active',
        help_text='Inactive vendors are hidden from selection'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Managers
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Vendor'
        verbose_name_plural = 'Vendors'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tenant', 'name']),
            models.Index(fields=['tenant', 'phone']),
            models.Index(fields=['tenant', 'is_active']),
        ]
    
    def __str__(self):
        if self.business_name:
            return f"{self.business_name} ({self.name})"
        return self.name
    
    @property
    def display_name(self):
        """Display name with business name if available"""
        if self.business_name:
            return f"{self.business_name} ({self.name})"
        return self.name
    
    @property
    def has_outstanding(self):
        """Check if vendor has outstanding balance"""
        return self.outstanding_balance > 0
    
    @property
    def total_bills(self):
        """Total number of bills"""
        return self.bills.count()


# ==================== PURCHASE BILL MODEL ====================

class PurchaseBill(models.Model):
    """
    Purchase Bill/Invoice Model
    Records vendor bills with payment tracking
    """
    
    class PaymentStatus(models.TextChoices):
        UNPAID = 'UNPAID', 'Unpaid'
        PARTIALLY_PAID = 'PARTIALLY_PAID', 'Partially Paid'
        FULLY_PAID = 'FULLY_PAID', 'Fully Paid'
    
    # Tenant (CRITICAL)
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='purchase_bills',
        verbose_name='Tenant'
    )
    
    # Bill Information
    bill_number = models.CharField(
        max_length=100,
        verbose_name='Bill/Invoice Number',
        help_text='Vendor bill number'
    )
    
    bill_date = models.DateField(
        default=timezone.now,
        verbose_name='Bill Date'
    )
    
    vendor = models.ForeignKey(
        Vendor,
        on_delete=models.PROTECT,  # Cannot delete vendor with bills
        related_name='bills',
        verbose_name='Vendor'
    )
    
    # Amounts
    bill_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Bill Amount',
        help_text='Total bill amount'
    )
    
    paid_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Paid Amount',
        help_text='Amount paid so far (auto-calculated)'
    )
    
    balance_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Balance Amount',
        help_text='Remaining amount to pay (auto-calculated)'
    )
    
    # Status
    payment_status = models.CharField(
        max_length=20,
        choices=PaymentStatus.choices,
        default=PaymentStatus.UNPAID,
        verbose_name='Payment Status'
    )
    
    # Bill Details
    description = models.TextField(
        blank=True,
        verbose_name='Bill Description/Items',
        help_text='What was purchased (fabrics, threads, accessories, etc.)'
    )
    
    bill_image = models.ImageField(
        upload_to='purchase_bills/%Y/%m/',
        blank=True,
        null=True,
        validators=[
            validate_image_size,
            FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'pdf'])
        ],
        verbose_name='Bill Photo/Scan',
        help_text='Upload bill image (max 5MB)'
    )
    
    # Meta
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Managers
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Purchase Bill'
        verbose_name_plural = 'Purchase Bills'
        ordering = ['-bill_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'vendor']),
            models.Index(fields=['tenant', 'bill_date']),
            models.Index(fields=['tenant', 'payment_status']),
        ]
        unique_together = [['tenant', 'bill_number', 'vendor']]  # Unique bill per vendor
    
    def __str__(self):
        return f"Bill #{self.bill_number} - {self.vendor.name}"
    
    def save(self, *args, **kwargs):
        # Calculate balance on save
        self.balance_amount = self.bill_amount - self.paid_amount
        super().save(*args, **kwargs)
    
    @property
    def is_overdue(self):
        """Check if payment is overdue (basic version)"""
        if self.payment_status == self.PaymentStatus.FULLY_PAID:
            return False
        # Can add due date logic with payment_terms_days later
        return False
    
    @property
    def payment_percentage(self):
        """Calculate payment completion percentage"""
        if self.bill_amount > 0:
            return (self.paid_amount / self.bill_amount) * 100
        return 0


# ==================== EXPENSE MODEL ====================

class Expense(models.Model):
    """
    Daily Expense Model
    Records operational business expenses
    """
    
    class ExpenseCategory(models.TextChoices):
        RENT = 'RENT', 'Rent'
        ELECTRICITY = 'ELECTRICITY', 'Electricity'
        WATER = 'WATER', 'Water'
        TEA_SNACKS = 'TEA_SNACKS', 'Tea/Snacks'
        TRANSPORT = 'TRANSPORT', 'Transport'
        REPAIRS = 'REPAIRS', 'Repairs & Maintenance'
        SUPPLIES = 'SUPPLIES', 'Office Supplies'
        SALARY_ADVANCE = 'SALARY_ADVANCE', 'Salary Advance'
        INTERNET = 'INTERNET', 'Internet/Phone'
        CLEANING = 'CLEANING', 'Cleaning'
        MARKETING = 'MARKETING', 'Marketing/Advertising'
        OTHER = 'OTHER', 'Other'
    
    class PaymentStatus(models.TextChoices):
        UNPAID = 'UNPAID', 'Unpaid'
        PARTIALLY_PAID = 'PARTIALLY_PAID', 'Partially Paid'
        FULLY_PAID = 'FULLY_PAID', 'Fully Paid'
    
    # Tenant (CRITICAL)
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='expenses',
        verbose_name='Tenant'
    )
    
    # Expense Information
    expense_date = models.DateField(
        default=timezone.now,
        verbose_name='Expense Date'
    )
    
    category = models.CharField(
        max_length=20,
        choices=ExpenseCategory.choices,
        verbose_name='Expense Category'
    )
    
    # Amounts
    expense_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Expense Amount',
        help_text='Total expense amount'
    )
    
    paid_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Paid Amount',
        help_text='Amount paid so far (auto-calculated)'
    )
    
    balance_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Balance Amount',
        help_text='Remaining amount to pay (auto-calculated)'
    )
    
    # Status
    payment_status = models.CharField(
        max_length=20,
        choices=PaymentStatus.choices,
        default=PaymentStatus.UNPAID,
        verbose_name='Payment Status'
    )
    
    # Details
    description = models.TextField(
        blank=True,
        verbose_name='Description',
        help_text='Expense details'
    )
    
    receipt_image = models.ImageField(
        upload_to='expense_receipts/%Y/%m/',
        blank=True,
        null=True,
        validators=[
            validate_image_size,
            FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'pdf'])
        ],
        verbose_name='Receipt Photo',
        help_text='Upload receipt (max 5MB)'
    )
    
    # Meta
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Managers
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Expense'
        verbose_name_plural = 'Expenses'
        ordering = ['-expense_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'expense_date']),
            models.Index(fields=['tenant', 'category']),
            models.Index(fields=['tenant', 'payment_status']),
        ]
    
    def __str__(self):
        return f"{self.get_category_display()} - ₹{self.expense_amount} ({self.expense_date})"
    
    def save(self, *args, **kwargs):
        # Calculate balance on save
        self.balance_amount = self.expense_amount - self.paid_amount
        super().save(*args, **kwargs)


# ==================== PAYMENT MODEL ====================

class Payment(models.Model):
    """
    Payment Model
    Records all payments made (to vendors and for expenses)
    """
    
    class PaymentType(models.TextChoices):
        PURCHASE_BILL = 'PURCHASE_BILL', 'Purchase Bill Payment'
        EXPENSE = 'EXPENSE', 'Expense Payment'
    
    class PaymentMethod(models.TextChoices):
        CASH = 'CASH', 'Cash'
        UPI = 'UPI', 'UPI'
        BANK_TRANSFER = 'BANK_TRANSFER', 'Bank Transfer'
        CARD = 'CARD', 'Card'
        CHEQUE = 'CHEQUE', 'Cheque'
    
    # Tenant (CRITICAL)
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='payments',
        verbose_name='Tenant'
    )
    
    # Payment Information
    payment_date = models.DateField(
        default=timezone.now,
        verbose_name='Payment Date'
    )
    
    payment_number = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        verbose_name='Payment Number',
        help_text='Auto-generated payment reference'
    )
    
    # Payment Type
    payment_type = models.CharField(
        max_length=20,
        choices=PaymentType.choices,
        verbose_name='Payment Type'
    )
    
    # Links (Only one will be filled based on payment_type)
    purchase_bill = models.ForeignKey(
        PurchaseBill,
        on_delete=models.CASCADE,
        related_name='payments',
        null=True,
        blank=True,
        verbose_name='Purchase Bill'
    )
    
    expense = models.ForeignKey(
        Expense,
        on_delete=models.CASCADE,
        related_name='payments',
        null=True,
        blank=True,
        verbose_name='Expense'
    )
    
    # Amount
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Payment Amount'
    )
    
    # Payment Method
    payment_method = models.CharField(
        max_length=20,
        choices=PaymentMethod.choices,
        verbose_name='Payment Method'
    )
    
    # Additional Details
    reference_number = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Reference/Transaction Number',
        help_text='UPI Transaction ID, Cheque Number, etc.'
    )
    
    # Meta
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Managers
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Payment'
        verbose_name_plural = 'Payments'
        ordering = ['-payment_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'payment_date']),
            models.Index(fields=['tenant', 'payment_type']),
            models.Index(fields=['tenant', 'payment_method']),
        ]
    
    def __str__(self):
        return f"{self.payment_number} - ₹{self.amount} ({self.get_payment_method_display()})"
    
    def clean(self):
        """Validate that only one link is set based on payment_type"""
        if self.payment_type == self.PaymentType.PURCHASE_BILL:
            if not self.purchase_bill:
                raise ValidationError('Purchase bill is required for purchase bill payment')
            if self.expense:
                raise ValidationError('Cannot link expense for purchase bill payment')
        
        elif self.payment_type == self.PaymentType.EXPENSE:
            if not self.expense:
                raise ValidationError('Expense is required for expense payment')
            if self.purchase_bill:
                raise ValidationError('Cannot link purchase bill for expense payment')
        
        # Validate payment amount doesn't exceed balance
        if self.payment_type == self.PaymentType.PURCHASE_BILL and self.purchase_bill:
            remaining = self.purchase_bill.bill_amount - self.purchase_bill.paid_amount
            if self.amount > remaining:
                raise ValidationError(
                    f'Payment amount (₹{self.amount}) exceeds remaining balance (₹{remaining})'
                )
        
        elif self.payment_type == self.PaymentType.EXPENSE and self.expense:
            remaining = self.expense.expense_amount - self.expense.paid_amount
            if self.amount > remaining:
                raise ValidationError(
                    f'Payment amount (₹{self.amount}) exceeds remaining balance (₹{remaining})'
                )
    
    def save(self, *args, **kwargs):
        # Auto-generate payment number if not exists
        if not self.payment_number:
            today = date.today()
            prefix = f"PAY-{today.strftime('%Y%m%d')}"
            
            # Get last payment for today
            last = Payment.objects.filter(
                tenant=self.tenant,
                payment_number__startswith=prefix
            ).order_by('-payment_number').first()
            
            if last:
                try:
                    last_num = int(last.payment_number.split('-')[-1])
                    new_num = last_num + 1
                except (ValueError, IndexError):
                    new_num = 1
            else:
                new_num = 1
            
            self.payment_number = f"{prefix}-{new_num:04d}"
        
        super().save(*args, **kwargs)
    
    @property
    def vendor_name(self):
        """Get vendor name if purchase bill payment"""
        if self.payment_type == self.PaymentType.PURCHASE_BILL and self.purchase_bill:
            return self.purchase_bill.vendor.name
        return None
    
    @property
    def display_reference(self):
        """Display reference for listing"""
        if self.payment_type == self.PaymentType.PURCHASE_BILL and self.purchase_bill:
            return f"Bill #{self.purchase_bill.bill_number}"
        elif self.payment_type == self.PaymentType.EXPENSE and self.expense:
            return f"{self.expense.get_category_display()}"
        return "N/A"