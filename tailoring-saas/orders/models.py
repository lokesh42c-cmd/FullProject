"""
Orders app models - GST Compliant Redesign
Date: 2026-01-03
Simplified: Customer with measurements, Order for work tracking
Financial tracking moved to 'financials' app
Invoicing moved to 'invoicing' app
"""

from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from decimal import Decimal
from core.managers import TenantManager


# ==================== VALIDATORS ====================

def validate_phone_number(value):
    """Validate 10-digit Indian phone number"""
    if not value:
        return
    cleaned = value.strip()
    if not cleaned.isdigit():
        raise ValidationError('Phone number must contain only digits (0-9).', code='invalid_phone_format')
    if len(cleaned) != 10:
        raise ValidationError(f'Phone number must be exactly 10 digits. You entered {len(cleaned)} digits.', code='invalid_phone_length')


# ==================== CUSTOMER MODEL ====================

class Customer(models.Model):
    """
    Customer model - Simplified with measurements
    Removed: FamilyMember logic, billing address duplication, alternate_phone
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='customers'
    )
    
    CUSTOMER_TYPE_CHOICES = [
        ('INDIVIDUAL', 'Individual (B2C)'),
        ('BUSINESS', 'Business (B2B/GST Customer)'),
    ]
    customer_type = models.CharField(
        max_length=20,
        choices=CUSTOMER_TYPE_CHOICES,
        default='INDIVIDUAL',
        verbose_name="Customer Type"
    )
    
    # Basic Info
    name = models.CharField(max_length=100, verbose_name="Customer Name")
    
    phone = models.CharField(
        max_length=15,
        validators=[validate_phone_number],
        verbose_name='Phone Number',
        help_text='Primary contact number (10 digits)'
    )
    
    whatsapp_number = models.CharField(
        max_length=15,
        blank=True,
        validators=[validate_phone_number],
        verbose_name='WhatsApp Number',
        help_text='WhatsApp number (defaults to phone if not provided)'
    )
    
    email = models.EmailField(blank=True, null=True, verbose_name="Email")
    
    # Gender for tailoring
    GENDER_CHOICES = [
        ('MALE', 'Male'),
        ('FEMALE', 'Female'),
        ('OTHER', 'Other'),
        ('NOT_APPLICABLE', 'Not Applicable'),
    ]
    gender = models.CharField(
        max_length=20,
        choices=GENDER_CHOICES,
        default='NOT_APPLICABLE',
        null=True,
        blank=True,
        help_text='Gender for tailoring measurements'
    )
    
    # Business Info (for B2B/GST)
    business_name = models.CharField(max_length=200, blank=True, null=True, verbose_name="Business Name")
    gstin = models.CharField(max_length=15, blank=True, null=True, verbose_name="GSTIN")
    pan = models.CharField(max_length=10, blank=True, null=True, verbose_name="PAN")
    
    # Address (Single address - billing/shipping addresses stored in Invoice)
    address_line1 = models.CharField(max_length=255, blank=True, null=True, verbose_name="Address Line 1")
    address_line2 = models.CharField(max_length=255, blank=True, null=True, verbose_name="Address Line 2")
    city = models.CharField(max_length=100, blank=True, null=True, verbose_name="City")
    state = models.CharField(max_length=100, blank=True, null=True, verbose_name="State")
    country = models.CharField(max_length=100, default='India', blank=True, null=True, verbose_name="Country")
    pincode = models.CharField(max_length=6, blank=True, null=True, verbose_name="Pincode")
    
    # Measurements - Aligned with Flutter measurement.dart
    # Basic & Common Measurements
    height = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Height (cm)')
    weight = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Weight (kg)')
    shoulder_width = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Shoulder Width')
    bust_chest = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Bust/Chest')
    waist = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Waist')
    hip = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Hip')
    shoulder = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Shoulder')
    sleeve_length = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Sleeve Length')
    armhole = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Armhole')
    garment_length = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Garment Length')
    
    # Women-Specific Measurements
    front_neck_depth = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Front Neck Depth')
    back_neck_depth = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Back Neck Depth')
    upper_chest = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Upper Chest')
    under_bust = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Under Bust')
    shoulder_to_apex = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Shoulder to Apex')
    bust_point_distance = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Bust Point Distance')
    front_cross = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Front Cross')
    back_cross = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Back Cross')
    lehenga_length = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Lehenga Length')
    pant_waist = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Pant Waist')
    ankle_opening = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Ankle Opening')
    
    # Men-Specific Measurements
    neck_round = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Neck Round')
    stomach_round = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Stomach Round')
    yoke_width = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Yoke Width')
    front_width = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Front Width')
    back_width = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Back Width')
    trouser_waist = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Trouser Waist')
    front_rise = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Front Rise')
    back_rise = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Back Rise')
    bottom_opening = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Bottom Opening')
    
    # Sleeves & Legs Measurements
    upper_arm_bicep = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Upper Arm/Bicep')
    sleeve_loose = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Sleeve Loose')
    wrist_round = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Wrist Round')
    thigh = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Thigh')
    knee = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Knee')
    ankle = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Ankle')
    rise = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Rise')
    inseam = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Inseam')
    outseam = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, verbose_name='Outseam')
    
    # Custom measurements (10 fields for tenant-specific measurements)
    custom_field_1 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_2 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_3 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_4 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_5 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_6 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_7 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_8 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_9 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_field_10 = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    
    # Measurement notes
    measurement_notes = models.TextField(blank=True, verbose_name='Measurement Notes')
    
    # Additional
    notes = models.TextField(blank=True, null=True, verbose_name="Notes")
    is_active = models.BooleanField(default=True, verbose_name="Active")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Customer"
        verbose_name_plural = "Customers"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tenant', 'phone']),
            models.Index(fields=['tenant', 'name']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.phone}"
    
    @property
    def display_name(self):
        """Display name with business name if applicable"""
        if self.customer_type == 'BUSINESS' and self.business_name:
            return f"{self.business_name} ({self.name})"
        return self.name
    
    @property
    def whatsapp_display(self):
        """Return WhatsApp number or default to phone"""
        return self.whatsapp_number if self.whatsapp_number else self.phone


# ==================== ORDER MODEL ====================

class Order(models.Model):
    """
    Order model - Work tracking only
    Financial tracking moved to 'financials' app (ReceiptVoucher, Payment)
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='orders'
    )
    
    customer = models.ForeignKey(
        Customer,
        on_delete=models.PROTECT,
        related_name='orders',
        verbose_name='Customer'
    )
    
    # Order Identity
    order_number = models.CharField(max_length=50, unique=True, verbose_name='Order Number')
    order_date = models.DateField(default=timezone.now, verbose_name='Order Date')
    
    # Delivery Tracking
    expected_delivery_date = models.DateField(null=True, blank=True, verbose_name='Expected Delivery Date')
    actual_delivery_date = models.DateField(null=True, blank=True, verbose_name='Actual Delivery Date')
    
    DELIVERY_STATUS_CHOICES = [
        ('NOT_STARTED', 'Not Started'),
        ('PARTIAL', 'Partial Delivery'),
        ('DELIVERED', 'Fully Delivered'),
    ]
    delivery_status = models.CharField(
        max_length=20,
        choices=DELIVERY_STATUS_CHOICES,
        default='NOT_STARTED',
        verbose_name='Delivery Status'
    )
    
    # Order Status
    ORDER_STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('CONFIRMED', 'Confirmed'),
        ('IN_PROGRESS', 'In Progress'),
        ('READY', 'Ready for Delivery'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]
    order_status = models.CharField(
        max_length=20,
        choices=ORDER_STATUS_CHOICES,
        default='DRAFT',
        verbose_name='Order Status'
    )
    
    # Pricing (Estimated)
    estimated_total = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Estimated Total'
    )
    
    # Payment Terms
    payment_terms = models.TextField(
        blank=True,
        verbose_name='Payment Terms',
        help_text='e.g., 50% advance, balance on delivery'
    )
    
    # Order Details
    order_summary = models.TextField(blank=True, verbose_name='Order Summary')
    customer_instructions = models.TextField(blank=True, verbose_name='Customer Instructions')
    
    # Work Assignment
    assigned_to = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_orders',
        verbose_name="Assigned To",
        help_text="Assign order to specific employee"
    )
    
    # QR Code for order tracking
    qr_code = models.ImageField(
        upload_to='orders/qr_codes/',
        null=True,
        blank=True,
        verbose_name='Order QR Code'
    )
    
    # Lock order after invoicing starts
    is_locked = models.BooleanField(default=False, verbose_name='Locked')
    
    # Audit Trail
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='orders_created',
        verbose_name='Created By'
    )
    updated_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='orders_updated',
        verbose_name='Updated By'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Order"
        verbose_name_plural = "Orders"
        ordering = ['-order_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'order_number']),
            models.Index(fields=['tenant', 'customer']),
            models.Index(fields=['tenant', 'order_status']),
            models.Index(fields=['tenant', 'expected_delivery_date']),
        ]
    
    def __str__(self):
        return f"{self.order_number} - {self.customer.name}"
    
    def save(self, *args, **kwargs):
        # Auto-generate order number if not provided
        if not self.order_number:
            from django.utils import timezone
            year_month = timezone.now().strftime('%Y%m')
            last_order = Order.objects.filter(
                tenant=self.tenant,
                order_number__startswith=f'ORD-{year_month}'
            ).order_by('-order_number').first()
            
            if last_order:
                last_num = int(last_order.order_number.split('-')[-1])
                new_num = last_num + 1
            else:
                new_num = 1
            
            self.order_number = f'ORD-{year_month}-{new_num:05d}'
        
        super().save(*args, **kwargs)
        
        # Generate QR code after first save (when order_number is set)
        if not self.qr_code and self.order_number:
            self.generate_qr_code()
            super().save(update_fields=['qr_code'])
    
    def generate_qr_code(self):
        """Generate QR code for order tracking"""
        if not self.order_number:
            return
        
        import qrcode
        from io import BytesIO
        from django.core.files import File
        
        # QR Code data - contains order number and ID
        qr_data = f"ORDER:{self.order_number}:{self.id}"
        
        # Create QR code instance
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        
        # Add data and generate
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        # Create image
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save to BytesIO
        buffer = BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        
        # Generate filename
        file_name = f'qr_order_{self.order_number}.png'
        
        # Save to model field
        self.qr_code.save(file_name, File(buffer), save=False)
        buffer.close()
    
    @property
    def is_overdue(self):
        """Check if order is overdue"""
        if self.expected_delivery_date and self.order_status not in ['COMPLETED', 'CANCELLED']:
            return timezone.now().date() > self.expected_delivery_date
        return False
    
    @property
    def days_until_delivery(self):
        """Days remaining until delivery"""
        if self.expected_delivery_date:
            delta = self.expected_delivery_date - timezone.now().date()
            return delta.days
        return None


# ==================== ORDER ITEM MODEL ====================

class OrderItem(models.Model):
    """Order line items"""
    
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name='Order'
    )
    
    ITEM_TYPE_CHOICES = [
        ('PRODUCT', 'Product'),
        ('SERVICE', 'Service'),
    ]
    item_type = models.CharField(
        max_length=10,
        choices=ITEM_TYPE_CHOICES,
        default='SERVICE',
        verbose_name='Item Type'
    )
    
    # Link to Item master (from orders.Item model - non-inventory items)
    item = models.ForeignKey(
        'Item',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='order_items',
        verbose_name='Item'
    )
    
    item_description = models.CharField(max_length=255, verbose_name='Description')
    
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
    
    tax_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Tax %'
    )
    
    notes = models.TextField(blank=True, verbose_name='Notes')
    
    # Item Status
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        verbose_name='Status'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Order Item"
        verbose_name_plural = "Order Items"
        ordering = ['id']
    
    def __str__(self):
        return f"{self.order.order_number} - {self.item_description}"
    
    @property
    def subtotal(self):
        """Subtotal before tax"""
        return self.quantity * self.unit_price
    
    @property
    def tax_amount(self):
        """Tax amount"""
        return (self.subtotal * self.tax_percentage) / Decimal('100')
    
    @property
    def total_price(self):
        """Total including tax"""
        return self.subtotal + self.tax_amount


# ==================== ITEM MASTER (Non-Inventory) ====================

class Item(models.Model):
    """
    Unified Item/Service catalog with optional inventory tracking
    """
    
    ITEM_TYPE_CHOICES = [
        ('SERVICE', 'Service'),
        ('PRODUCT', 'Product'),
    ]
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='items'
    )
    
    # Basic Info
    name = models.CharField(max_length=200, verbose_name='Item/Service Name')
    description = models.TextField(blank=True, verbose_name='Description')
    
    # Item Type & Stock Control
    item_type = models.CharField(
        max_length=20,
        choices=ITEM_TYPE_CHOICES,
        default='SERVICE',
        verbose_name='Item Type'
    )
    
    track_stock = models.BooleanField(
        default=False,
        verbose_name='Track Stock',
        help_text='Enable inventory tracking for this item'
    )
    
    allow_negative_stock = models.BooleanField(
        default=True,
        verbose_name='Allow Negative Stock',
        help_text='Allow orders even when stock is insufficient'
    )
    
    # Unit
    unit = models.ForeignKey(
        'masters.ItemUnit',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='master_items',
        verbose_name='Unit'
    )
    
    # Stock Fields
    opening_stock = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Opening Stock',
        help_text='Set only once during creation'
    )
    
    current_stock = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Current Stock',
        help_text='Auto-calculated from transactions'
    )
    
    min_stock_level = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Minimum Stock Level',
        help_text='Alert when stock falls below this level'
    )
    
    # Pricing (Both Optional)
    purchase_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Purchase Price',
        help_text='Cost price (optional)'
    )
    
    selling_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Selling Price',
        help_text='Default selling price (optional)'
    )
    
    # GST Details
    hsn_sac_code = models.CharField(
        max_length=20,
        blank=True,
        verbose_name='HSN/SAC Code',
        help_text='HSN for goods, SAC for services'
    )
    
    tax_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Tax %',
        help_text='GST rate (0, 5, 12, 18, 28)'
    )
    
    # Barcode
    barcode = models.CharField(
        max_length=50,
        unique=True,
        null=True,
        blank=True,
        verbose_name='Barcode'
    )
    
    # Usage Tracking (for edit restrictions)
    has_been_used = models.BooleanField(
        default=False,
        verbose_name='Has Been Used',
        help_text='Auto-set when item appears in orders/invoices'
    )
    
    # Soft Delete
    is_active = models.BooleanField(default=True, verbose_name='Active')
    deleted_at = models.DateTimeField(null=True, blank=True, verbose_name='Deleted At')
    
    # Audit
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Item"
        verbose_name_plural = "Items"
        ordering = ['name']
        indexes = [
            models.Index(fields=['tenant', 'is_active']),
            models.Index(fields=['tenant', 'track_stock']),
        ]
    
    def __str__(self):
        return self.name
    
    @property
    def is_low_stock(self):
        """Check if stock is below minimum level"""
        if not self.track_stock:
            return False
        return self.current_stock <= self.min_stock_level
    
    @property
    def stock_value(self):
        """Calculate total stock value at purchase price"""
        if self.purchase_price:
            return self.current_stock * self.purchase_price
        return Decimal('0.00')
    
    def save(self, *args, **kwargs):
        # Initialize current_stock from opening_stock on creation
        if not self.pk and self.opening_stock:
            self.current_stock = self.opening_stock
        super().save(*args, **kwargs)


# ==================== STOCK TRANSACTION MODEL ====================

class StockTransaction(models.Model):
    """
    Simple stock movement audit trail
    """
    
    TRANSACTION_TYPE_CHOICES = [
        ('IN', 'Stock In'),
        ('OUT', 'Stock Out'),
        ('ADJUSTMENT', 'Adjustment'),
    ]
    
    REFERENCE_TYPE_CHOICES = [
        ('ORDER', 'Order'),
        ('PURCHASE', 'Purchase'),
        ('ADJUSTMENT', 'Manual Adjustment'),
    ]
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='stock_transactions'
    )
    
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        related_name='stock_transactions',
        verbose_name='Item'
    )
    
    transaction_type = models.CharField(
        max_length=20,
        choices=TRANSACTION_TYPE_CHOICES,
        verbose_name='Transaction Type'
    )
    
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name='Quantity',
        help_text='Positive for IN, Negative for OUT'
    )
    
    stock_before = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name='Stock Before'
    )
    
    stock_after = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name='Stock After'
    )
    
    reference_type = models.CharField(
        max_length=20,
        choices=REFERENCE_TYPE_CHOICES,
        verbose_name='Reference Type'
    )
    
    reference_id = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        verbose_name='Reference ID',
        help_text='Order number, Invoice number, etc.'
    )
    
    notes = models.TextField(blank=True, verbose_name='Notes')
    
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='stock_transactions_created',
        verbose_name='Created By'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Stock Transaction"
        verbose_name_plural = "Stock Transactions"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tenant', 'item', '-created_at']),
            models.Index(fields=['tenant', 'transaction_type']),
        ]
    
    def __str__(self):
        return f"{self.transaction_type} - {self.item.name} - {self.quantity}"


# ==================== ORDER REFERENCE PHOTO MODEL ====================

class OrderReferencePhoto(models.Model):
    """Multiple reference photos for design inspiration per order"""
    
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='reference_photos',
        verbose_name='Order'
    )
    
    photo = models.ImageField(
        upload_to='orders/reference_photos/',
        verbose_name='Reference Photo'
    )
    
    description = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Description',
        help_text='e.g., Blouse design, Embroidery pattern, Color reference'
    )
    
    uploaded_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name='Uploaded By'
    )
    
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Order Reference Photo'
        verbose_name_plural = 'Order Reference Photos'
        ordering = ['-uploaded_at']
    
    def __str__(self):
        return f"{self.order.order_number} - Reference Photo {self.id}"


# ==================== DEPRECATED MODELS (COMMENTED OUT) ====================
# TODO: Remove after successful migration and testing

"""
# ==================== DEPRECATED - OLD FAMILY MEMBER LOGIC ====================
# FamilyMember model - DEPRECATED
# Measurements moved to Customer model directly
# Delete after migration complete

class FamilyMember(models.Model):
    # ... all old code commented ...
    pass

class FamilyMemberMeasurement(models.Model):
    # ... all old code commented ...
    pass

# ==================== DEPRECATED - OLD INVOICE/PAYMENT MODELS ====================
# These moved to 'invoicing' and 'financials' apps

class Invoice(models.Model):
    # ... old invoice code ...
    pass

class OrderPayment(models.Model):
    # ... old payment code ...
    pass

class CreditNote(models.Model):
    # ... old credit note code ...
    pass
"""