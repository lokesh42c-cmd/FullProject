"""
Masters app models for categories, measurements, and units.
Supports both system-wide (Super Admin) and tenant-specific data.
"""
from django.db import models
from django.core.validators import RegexValidator
from core.models import Tenant

#this is not in scope now. we have created separate tabke called items for regular works and inventroy module for inventroy
class ItemCategory(models.Model):
    """
    Item Categories - can be system-wide or tenant-specific
    Types: GARMENT, FABRIC, ACCESSORY
    """
    CATEGORY_TYPE_CHOICES = [
        ('GARMENT', 'Garment'),
        ('FABRIC', 'Fabric'),
        ('ACCESSORY', 'Accessory'),
    ]
    
    # Identity
    name = models.CharField(max_length=100, help_text="Category name")
    category_type = models.CharField(
        max_length=20,
        choices=CATEGORY_TYPE_CHOICES,
        help_text="Type of category"
    )
    description = models.TextField(blank=True, null=True)

    default_hsn_code = models.CharField(
        max_length=10,
        blank=True,
        default='',
        verbose_name="Default HSN Code",
        help_text="Default HSN/SAC code for items in this category"
    )
    
    # Tenant Relationship (NULL = system-wide category)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name='categories',
        null=True,
        blank=True,
        help_text="If NULL, this is a system-wide category available to all tenants"
    )
    
    # System-wide flag
    is_system_wide = models.BooleanField(
        default=False,
        help_text="If True, this category is created by Super Admin and available to all tenants"
    )
    
    # Status
    is_active = models.BooleanField(default=True)
    
    # Display
    display_order = models.IntegerField(default=0, help_text="Order in lists")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    
    
    class Meta:
        db_table = 'item_categories'
        ordering = ['category_type', 'display_order', 'name']
        verbose_name = 'Item Category'
        verbose_name_plural = 'Item Categories'
        # Ensure unique names per type, either system-wide or per tenant
        unique_together = [
            ['name', 'category_type', 'tenant'],
        ]
    
    def __str__(self):
        if self.is_system_wide:
            return f"{self.name} ({self.category_type}) [System]"
        elif self.tenant:
            return f"{self.name} ({self.category_type}) - {self.tenant.name}"
        return f"{self.name} ({self.category_type})"
    
    
    
class Unit(models.Model):
    """
    Measurement units (inches, cm, meters, etc.)
    System-wide only
    """
    name = models.CharField(max_length=50, unique=True, help_text="Unit name (e.g., inches)")
    symbol = models.CharField(max_length=10, help_text="Unit symbol (e.g., in, cm)")
    is_active = models.BooleanField(default=True)
    display_order = models.IntegerField(default=0)
    
    class Meta:
        db_table = 'units'
        ordering = ['display_order', 'name']
        verbose_name = 'Unit'
        verbose_name_plural = 'Units'
    
    def __str__(self):
        return f"{self.name} ({self.symbol})"


class MeasurementField(models.Model):
    """
    Measurement fields for categories (e.g., bust, waist, hip for Lehenga)
    Can be system-wide or tenant-specific
    """
    FIELD_TYPE_CHOICES = [
        ('NUMBER', 'Number'),
        ('TEXT', 'Text'),
        ('DROPDOWN', 'Dropdown'),
    ]
    
    # Relationship
    category = models.ForeignKey(
        ItemCategory,
        on_delete=models.CASCADE,
        related_name='measurement_fields',
        help_text="Category this measurement belongs to"
    )
    
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name='measurement_fields',
        null=True,
        blank=True,
        help_text="If NULL, this is a system-wide field"
    )
    
    # Field Details
    field_name = models.CharField(
        max_length=100,
        help_text="Internal field name (e.g., bust, waist)"
    )
    field_label = models.CharField(
        max_length=100,
        help_text="Display label (e.g., Bust, Waist)"
    )
    field_type = models.CharField(
        max_length=20,
        choices=FIELD_TYPE_CHOICES,
        default='NUMBER'
    )
    
    # Units (for NUMBER fields)
    unit_options = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        help_text="Comma-separated unit options (e.g., inches,cm)"
    )
    default_unit = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Default unit to use"
    )
    
    # Dropdown options (for DROPDOWN fields)
    dropdown_options = models.TextField(
        blank=True,
        null=True,
        help_text="Comma-separated dropdown options"
    )
    
    # Validation
    is_required = models.BooleanField(
        default=False,
        help_text="Is this field required when taking measurements?"
    )
    min_value = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Minimum allowed value (for NUMBER fields)"
    )
    max_value = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Maximum allowed value (for NUMBER fields)"
    )
    
    # Display
    display_order = models.IntegerField(default=0, help_text="Order in measurement form")
    help_text = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        help_text="Help text to show users"
    )
    
    # System-wide flag
    is_system_wide = models.BooleanField(
        default=False,
        help_text="If True, this field is available to all tenants"
    )
    
    # Status
    is_active = models.BooleanField(default=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'measurement_fields'
        ordering = ['category', 'display_order', 'field_name']
        verbose_name = 'Measurement Field'
        verbose_name_plural = 'Measurement Fields'
        unique_together = [
            ['category', 'field_name', 'tenant'],
        ]
    
    def __str__(self):
        prefix = "[System]" if self.is_system_wide else f"[{self.tenant.name}]" if self.tenant else ""
        return f"{prefix} {self.category.name} - {self.field_label}"

#this serviceitem is not used any where 
class ServiceItem(models.Model):
    """
    Service Items - Services offered by the tailoring shop
    (e.g., Blouse Stitching, Pant Alteration, etc.)
    Can be system-wide or tenant-specific
    """
    
    # Service Categories
    SERVICE_CATEGORY_CHOICES = [
        ('STITCHING', 'Stitching'),
        ('ALTERATION', 'Alteration'),
        ('EMBROIDERY', 'Embroidery'),
        ('DESIGN', 'Design'),
        ('REPAIR', 'Repair'),
        ('IRONING', 'Ironing'),
        ('DYEING', 'Dyeing'),
        ('OTHER', 'Other'),
    ]
    
    # Pricing Units
    UNIT_CHOICES = [
        ('PER_ITEM', 'Per Item'),
        ('PER_METER', 'Per Meter'),
        ('PER_HOUR', 'Per Hour'),
        ('PER_PIECE', 'Per Piece'),
    ]
    
    # Identity
    name = models.CharField(
        max_length=200,
        help_text='Service name (e.g., Blouse Stitching)'
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text='Detailed description of the service'
    )
    service_category = models.CharField(
        max_length=50,
        choices=SERVICE_CATEGORY_CHOICES,
        default='STITCHING',
        help_text='Service category'
    )
    
    # Tenant Relationship (NULL = system-wide service)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name='service_items',
        null=True,
        blank=True,
        help_text='If NULL, this is a system-wide service available to all tenants'
    )
    
    # System-wide flag
    is_system_wide = models.BooleanField(
        default=False,
        help_text='If True, this service is created by Super Admin and available to all tenants'
    )
    
    # Pricing
    default_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Default/Standard price for this service'
    )
    min_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Minimum price (optional for price range)'
    )
    max_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text='Maximum price (optional for price range)'
    )
    
    # Configuration
    unit = models.CharField(
        max_length=50,
        choices=UNIT_CHOICES,
        default='PER_ITEM',
        help_text='Pricing unit'
    )
    
    # Tax/GST
    tax_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=18.00,
        help_text='Tax/GST rate percentage (e.g., 18.00 for 18%)'
    )
    sac_code  = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        default='',
        verbose_name='SAC Code',
        help_text='SAC code for this service'
    )
    
    # Operational
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this service is currently offered'
    )
    estimated_days = models.PositiveIntegerField(
        blank=True,
        null=True,
        help_text='Typical completion time in days'
    )
    
    # Display
    display_order = models.IntegerField(
        default=0,
        help_text='Order in lists'
    )
    
    # Additional info
    notes = models.TextField(
        blank=True,
        null=True,
        help_text='Internal notes about this service'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'service_items'
        ordering = ['service_category', 'display_order', 'name']
        verbose_name = 'Service Item'
        verbose_name_plural = 'Service Items'
        unique_together = [
            ['name', 'service_category', 'tenant'],
        ]
        indexes = [
            models.Index(fields=['tenant', 'is_active']),
            models.Index(fields=['tenant', 'service_category']),
            models.Index(fields=['is_system_wide', 'is_active']),
        ]
    
    def __str__(self):
        if self.is_system_wide:
            return f"{self.name} ({self.get_service_category_display()}) [System]"
        elif self.tenant:
            return f"{self.name} ({self.get_service_category_display()}) - {self.tenant.name}"
        return f"{self.name} ({self.get_service_category_display()})"
    
    @property
    def price_display(self):
        """Display price or price range"""
        if self.min_price and self.max_price:
            return f"₹{self.min_price} - ₹{self.max_price}"
        return f"₹{self.default_price}"
    
    @property
    def category_display(self):
        """Get display name for category"""
        return self.get_service_category_display()
    
class TenantMeasurementConfig(models.Model):
    """
    Tenant-specific configuration for measurement fields
    Allows tenants to show/hide or customize system-wide fields
    """
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name='measurement_configs'
    )
    measurement_field = models.ForeignKey(
        MeasurementField,
        on_delete=models.CASCADE,
        related_name='tenant_configs'
    )
    
    # Visibility
    is_visible = models.BooleanField(
        default=True,
        help_text="Show this field in measurement forms?"
    )
    
    # Custom label (override system label)
    custom_label = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="Custom label for this tenant (overrides field_label)"
    )
    
    # Custom help text
    custom_help_text = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        help_text="Custom help text for this tenant"
    )
    
    # Override required
    is_required = models.BooleanField(
        default=None,
        null=True,
        blank=True,
        help_text="Override system required setting (NULL = use default)"
    )
    
    # Display order override
    display_order = models.IntegerField(
        null=True,
        blank=True,
        help_text="Custom display order (NULL = use default)"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'tenant_measurement_configs'
        unique_together = [
            ['tenant', 'measurement_field'],
        ]
        verbose_name = 'Tenant Measurement Config'
        verbose_name_plural = 'Tenant Measurement Configs'
    
    def __str__(self):
        return f"{self.tenant.name} - {self.measurement_field.field_label}"
# This is related to ITEMS used in order creation for product and services     
class ItemUnit(models.Model):
    """
    Units for item pricing and services
    Example: Pieces, Meters, Sets
    """
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name='item_units'
    )
    name = models.CharField(max_length=50)   # Pieces
    code = models.CharField(max_length=10)   # PCS
    is_active = models.BooleanField(default=True)
    display_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'item_units'
        ordering = ['display_order', 'name']
        unique_together = ['tenant', 'code']
        verbose_name = 'Item Unit'
        verbose_name_plural = 'Item Units'

    def __str__(self):
        return f"{self.name} ({self.code})"
