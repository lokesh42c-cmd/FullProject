"""
Orders app models
Phase 3 Finalization - Complete implementation with item-level pricing
UPDATED: Added Family Member support + Enhanced Customer fields
"""

from django.db import models
from django.utils import timezone
from decimal import Decimal
from django.core.validators import MinValueValidator
from PIL import Image
from django.core.exceptions import ValidationError
from core.managers import TenantManager
from masters.models import ItemUnit
import uuid
# Import workflow models
from .workflow_models import (
    WorkflowStage,
    OrderWorkflowStatus,
    TaskAssignment,
    TaskTimeLog,
    TaskComment,
    WorkflowStageHistory,
    QualityCheckResult,
    TrialFeedback
)
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

# ==================== CUSTOMER MODEL - ENHANCED ====================

class Customer(models.Model):
    """Customer model - Enhanced with WhatsApp and Billing Address"""
    
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
        validators=[validate_phone_number],  # ← ADD THIS
        verbose_name='Phone Number',
        help_text='Primary contact number (10 digits)'
    )
    
    alternate_phone = models.CharField(
        max_length=15,
        blank=True,
        validators=[validate_phone_number],  # ← ADD THIS
        verbose_name='Alternate Phone',
        help_text='Alternate contact number (10 digits, optional)'
    )
    # NEW: Gender field
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
        help_text='Gender of customer (for tailoring) or Not Applicable (for fabric sales)'
    )
    # ==================== NEW FIELD ====================
    whatsapp_number = models.CharField(
        max_length=15,
        blank=True,
        validators=[validate_phone_number],
        verbose_name='WhatsApp Number',
        help_text='WhatsApp number (defaults to phone if not provided)'
    )
    # ==================== END NEW FIELD ====================
    
    email = models.EmailField(blank=True, null=True, verbose_name="Email")
    
    # Business Info (for B2B)
    business_name = models.CharField(max_length=200, blank=True, null=True, verbose_name="Business Name")
    gstin = models.CharField(max_length=15, blank=True, null=True, verbose_name="GSTIN")
    pan = models.CharField(max_length=10, blank=True, null=True, verbose_name="PAN")
    
    # Primary Address
    address_line1 = models.CharField(max_length=255, blank=True, null=True, verbose_name="Address Line 1")
    address_line2 = models.CharField(max_length=255, blank=True, null=True, verbose_name="Address Line 2")
    city = models.CharField(max_length=100, blank=True, null=True, verbose_name="City")
    state = models.CharField(max_length=100, blank=True, null=True, verbose_name="State")
    country = models.CharField(max_length=100, default='India', blank=True, null=True, verbose_name="Country")
    pincode = models.CharField(max_length=6, blank=True, null=True, verbose_name="Pincode")
    
    # ==================== NEW FIELDS - BILLING ADDRESS ====================
    billing_address_line1 = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='Billing Address Line 1',
        help_text='Billing address for GST invoices'
    )
    
    billing_address_line2 = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='Billing Address Line 2'
    )
    
    billing_city = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Billing City'
    )
    
    billing_state = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Billing State'
    )
    
    billing_pincode = models.CharField(
        max_length=10,
        blank=True,
        verbose_name='Billing Pincode'
    )
    # ==================== END NEW FIELDS ====================
    
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
    def total_orders(self):
        """Total number of orders"""
        return self.orders.count()
    
    @property
    def whatsapp_display(self):
        """Return WhatsApp number or default to phone"""
        return self.whatsapp_number if self.whatsapp_number else self.phone


class FamilyMember(models.Model):
    """
    Individual person in a customer's family
    Each person can have orders and measurements
    """
    
    RELATIONSHIP_CHOICES = [
        ('SELF', 'Self'),
        ('SPOUSE', 'Spouse'),
        ('SON', 'Son'),
        ('DAUGHTER', 'Daughter'),
        ('MOTHER', 'Mother'),
        ('FATHER', 'Father'),
        ('BROTHER', 'Brother'),
        ('SISTER', 'Sister'),
        ('GRANDMOTHER', 'Grandmother'),
        ('GRANDFATHER', 'Grandfather'),
        ('GRANDSON', 'Grandson'),
        ('GRANDDAUGHTER', 'Granddaughter'),
        ('NEPHEW', 'Nephew'),
        ('NIECE', 'Niece'),
        ('UNCLE', 'Uncle'),
        ('AUNT', 'Aunt'),
        ('COUSIN', 'Cousin'),
        ('FRIEND', 'Friend'),
        ('OTHER', 'Other'),
    ]
    
    GENDER_CHOICES = [
        ('MALE', 'Male'),
        ('FEMALE', 'Female'),
        ('OTHER', 'Other'),
    ]
    
    # Links
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='family_members',
        verbose_name='Tenant'
    )
    
    customer = models.ForeignKey(
        Customer,
        on_delete=models.CASCADE,
        related_name='family_members',
        verbose_name='Customer Account',
        help_text='Main customer account this person belongs to'
    )
    
    # Personal Info
    name = models.CharField(
        max_length=100,
        verbose_name='Name'
    )
    
    relationship = models.CharField(
        max_length=20,
        choices=RELATIONSHIP_CHOICES,
        verbose_name='Relationship',
        help_text='Relationship to main customer'
    )
    
    gender = models.CharField(
        max_length=10,
        choices=GENDER_CHOICES,
        verbose_name='Gender'
    )
    
    date_of_birth = models.DateField(
        null=True,
        blank=True,
        verbose_name='Date of Birth'
    )
    phone = models.CharField(
        max_length=15,
        blank=True,
        validators=[validate_phone_number],
        verbose_name='Phone Number',
        help_text='Contact number for this family member'
    )
    
    email = models.EmailField(
        blank=True,
        verbose_name='Email',
        help_text='Email for this family member'
    )
    
    # Additional
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Managers
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Family Member'
        verbose_name_plural = 'Family Members'
        ordering = ['relationship', 'name']
        indexes = [
            models.Index(fields=['tenant', 'customer']),
            models.Index(fields=['customer', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_relationship_display()}) - {self.customer.name}"
    
    @property
    def age(self):
        """Calculate age from date of birth"""
        if not self.date_of_birth:
            return None
        from django.utils import timezone
        today = timezone.now().date()
        age = today.year - self.date_of_birth.year
        if today.month < self.date_of_birth.month or (
            today.month == self.date_of_birth.month and today.day < self.date_of_birth.day
        ):
            age -= 1
        return age
    
    @property
    def total_orders(self):
        """Count total orders for this family member"""
        return self.order_items.values('order').distinct().count()
    
    @property
    def has_current_measurements(self):
        """Check if this person has current measurements"""
        return self.measurements.filter(is_current=True).exists()


class FamilyMemberMeasurement(models.Model):
    """
    Measurement history for family members
    Tracks all measurements with history
    """
    
    # Links
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='family_member_measurements',
        verbose_name='Tenant'
    )
    
    family_member = models.ForeignKey(
        FamilyMember,
        on_delete=models.CASCADE,
        related_name='measurements',
        verbose_name='Family Member'
    )
    
    # ==================== STANDARD MEASUREMENT FIELDS ====================
    
    # Basic Body Measurements
    height = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Height (cm)',
        help_text='Total height in centimeters'
    )
    
    weight = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Weight (kg)',
        help_text='Body weight in kilograms'
    )
    
    # Upper Body Measurements
    shoulder_width = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Shoulder Width',
        help_text='Shoulder to shoulder measurement'
    )
    
    bust_chest = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Bust/Chest',
        help_text='Bust (female) or Chest (male) measurement'
    )
    
    waist = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Waist',
        help_text='Waist measurement'
    )
    
    hip = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Hip',
        help_text='Hip measurement'
    )
    
    shoulder = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Shoulder',
        help_text='Shoulder measurement for sleeves'
    )
    
    sleeve_length = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Sleeve Length',
        help_text='Full sleeve length'
    )
    
    armhole = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Armhole',
        help_text='Armhole circumference'
    )
    
    front_neck_depth = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Front Neck Depth',
        help_text='Front neck depth measurement'
    )
    
    back_neck_depth = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Back Neck Depth',
        help_text='Back neck depth measurement'
    )
    
    blouse_length = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Blouse/Shirt Length',
        help_text='Length of blouse or shirt'
    )

    # ==================== NEW FIELDS - WOMEN UPPER BODY ====================
    
    upper_chest = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Upper Chest (Above Bust)',
        help_text='Measurement above bust line (inches)'
    )
    
    under_bust = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Under Bust',
        help_text='Measurement below bust line (inches)'
    )
    
    shoulder_to_apex = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Shoulder to Apex',
        help_text='Shoulder point to bust apex (inches)'
    )
    
    bust_point_distance = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Bust Point to Bust Point',
        help_text='Distance between bust points (BP to BP) (inches)'
    )
    
    front_cross = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Front Cross',
        help_text='Front cross measurement (inches)'
    )
    
    back_cross = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Back Cross',
        help_text='Back cross measurement (inches)'
    )
    
    # ==================== NEW FIELDS - SLEEVES (DETAILED) ====================
    
    upper_arm_bicep = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Upper Arm/Bicep',
        help_text='Upper arm circumference (inches)'
    )
    
    elbow_round = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Elbow Round',
        help_text='Elbow circumference (inches)'
    )
    
    wrist_round = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Wrist/Cuff Round',
        help_text='Wrist circumference (inches)'
    )
    
    # ==================== NEW FIELDS - WOMEN LOWER BODY ====================
    
    lehenga_length = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Lehenga/Skirt Length',
        help_text='Lehenga or skirt length (inches)'
    )
    
    pant_waist = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Pant/Lehenga Waist',
        help_text='Lower waist where pant/lehenga sits (inches)'
    )
    
    ankle_opening = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Ankle Opening',
        help_text='Ankle circumference/opening (inches)'
    )
    
    # ==================== NEW FIELDS - MEN SPECIFIC ====================
    
    neck_round = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Neck Round (Collar)',
        help_text='Neck/collar measurement (inches)'
    )
    
    stomach_round = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Stomach/Belly Round',
        help_text='Stomach circumference (inches)'
    )
    
    yoke_width = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Yoke Width',
        help_text='Yoke measurement for shirts (inches)'
    )
    
    front_width = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Front Width',
        help_text='Front body width (inches)'
    )
    
    back_width = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Back Width',
        help_text='Back body width (inches)'
    )
    
    trouser_waist = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Trouser Waist',
        help_text='Waist where trousers sit (inches)'
    )
    
    front_rise = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Front Rise',
        help_text='Front rise for trousers (inches)'
    )
    
    back_rise = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Back Rise',
        help_text='Back rise for trousers (inches)'
    )
    
    bottom_opening = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Bottom/Cuff Opening',
        help_text='Trouser leg opening (inches)'
    )
    
    # Lower Body Measurements
    thigh = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Thigh',
        help_text='Thigh circumference'
    )
    
    knee = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Knee',
        help_text='Knee circumference'
    )
    
    ankle = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Ankle',
        help_text='Ankle circumference'
    )
    
    rise = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Rise',
        help_text='Crotch rise measurement'
    )
    
    inseam = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Inseam',
        help_text='Inner leg length'
    )
    
    outseam = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Outseam',
        help_text='Outer leg length'
    )
    
    # ==================== CUSTOM FIELDS ====================
    # Shop owner can define these via settings
    
    custom_field_1 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 1'
    )
    
    custom_field_2 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 2'
    )
    
    custom_field_3 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 3'
    )
    
    custom_field_4 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 4'
    )
    
    custom_field_5 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 5'
    )
    
    custom_field_6 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 6'
    )
    
    custom_field_7 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 7'
    )
    
    custom_field_8 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 8'
    )
    
    custom_field_9 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 9'
    )
    
    custom_field_10 = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Custom Field 10'
    )
    
    # ==================== METADATA ====================
    
    recorded_date = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Recorded Date'
    )
    
    recorded_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='measurements_recorded',
        verbose_name='Recorded By'
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name='Notes',
        help_text='Any special notes about these measurements'
    )
    
    is_current = models.BooleanField(
        default=True,
        verbose_name='Current Measurement',
        help_text='Is this the current measurement for this person?'
    )
    
    # Timestamps
    updated_at = models.DateTimeField(auto_now=True)
    
    # Managers
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Family Member Measurement'
        verbose_name_plural = 'Family Member Measurements'
        ordering = ['-recorded_date']
        indexes = [
            models.Index(fields=['tenant', 'family_member', '-recorded_date']),
            models.Index(fields=['family_member', 'is_current']),
        ]
    
    def __str__(self):
        status = "Current" if self.is_current else "Historical"
        return f"{self.family_member.name} - {status} ({self.recorded_date.date()})"
    
    def save(self, *args, **kwargs):
        # If this is set as current, mark all others as not current
        if self.is_current:
            FamilyMemberMeasurement.objects.filter(
                family_member=self.family_member,
                is_current=True
            ).exclude(pk=self.pk).update(is_current=False)
        
        super().save(*args, **kwargs)
    
    def to_json(self):
        """Convert measurements to JSON for order snapshot"""
        return {
            'height': float(self.height) if self.height else None,
            'weight': float(self.weight) if self.weight else None,
            'shoulder_width': float(self.shoulder_width) if self.shoulder_width else None,
            'bust_chest': float(self.bust_chest) if self.bust_chest else None,
            'waist': float(self.waist) if self.waist else None,
            'hip': float(self.hip) if self.hip else None,
            'shoulder': float(self.shoulder) if self.shoulder else None,
            'sleeve_length': float(self.sleeve_length) if self.sleeve_length else None,
            'armhole': float(self.armhole) if self.armhole else None,
            'front_neck_depth': float(self.front_neck_depth) if self.front_neck_depth else None,
            'back_neck_depth': float(self.back_neck_depth) if self.back_neck_depth else None,
            'blouse_length': float(self.blouse_length) if self.blouse_length else None,
            'thigh': float(self.thigh) if self.thigh else None,
            'knee': float(self.knee) if self.knee else None,
            'ankle': float(self.ankle) if self.ankle else None,
            'rise': float(self.rise) if self.rise else None,
            'inseam': float(self.inseam) if self.inseam else None,
            'outseam': float(self.outseam) if self.outseam else None,
            'custom_field_1': float(self.custom_field_1) if self.custom_field_1 else None,
            'custom_field_2': float(self.custom_field_2) if self.custom_field_2 else None,
            'custom_field_3': float(self.custom_field_3) if self.custom_field_3 else None,
            'custom_field_4': float(self.custom_field_4) if self.custom_field_4 else None,
            'custom_field_5': float(self.custom_field_5) if self.custom_field_5 else None,
            'custom_field_6': float(self.custom_field_6) if self.custom_field_6 else None,
            'custom_field_7': float(self.custom_field_7) if self.custom_field_7 else None,
            'custom_field_8': float(self.custom_field_8) if self.custom_field_8 else None,
            'custom_field_9': float(self.custom_field_9) if self.custom_field_9 else None,
            'custom_field_10': float(self.custom_field_10) if self.custom_field_10 else None,
            'recorded_date': self.recorded_date.isoformat(),
            'notes': self.notes,
        }


class Order(models.Model):
    """Order model with item-level discount and tax support"""
    
    # Basic Info
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='orders',
        verbose_name="Tenant"
    )
    
    customer = models.ForeignKey(
        Customer,
        on_delete=models.PROTECT,
        related_name='orders',
        verbose_name="Customer"
    )
    
    order_number = models.CharField(
        max_length=50,
        unique=True,
        verbose_name="Order Number",
        help_text="Auto-generated unique order number"
    )
    """
    barcode = models.CharField(
        max_length=50,
        unique=True,
        blank=True,
        verbose_name="Barcode",
        help_text="Auto-generated barcode for tracking"
    )
    """

    qr_code = models.ImageField(
        upload_to='orders/qr_codes/',
        blank=True,
        null=True,
        verbose_name='QR Code',
        help_text='Auto-generated QR code for order tracking'
    )
    
    # Dates
    order_date = models.DateTimeField(
        default=timezone.now,
        verbose_name="Order Date & Time"
    )
    
    planned_delivery_date = models.DateField(
        verbose_name="Planned Delivery Date"
    )
    
    actual_delivery_date = models.DateField(
        null=True,
        blank=True,
        verbose_name="Actual Delivery Date"
    )
    
    trial_date = models.DateField(
        null=True,
        blank=True,
        verbose_name="Trial/Fitting Date"
    )
    
    # ==================== PRICING - NEW STRUCTURE ====================
    
    # Subtotal (renamed from total_amount)
    subtotal = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Subtotal",
        help_text="Sum of all item subtotals (before discount/tax)",
        editable=False
    )
    
    # Order-level discount (optional)
    order_discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Order Discount %",
        help_text="Additional discount on entire order (optional)"
    )
    
    order_discount_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Order Discount Amount",
        editable=False
    )
    
    # Total discounts
    total_discount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Total Discount",
        help_text="Sum of all item discounts + order discount",
        editable=False
    )
    
    # Total tax
    total_tax = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Total Tax/GST",
        help_text="Sum of all item taxes",
        editable=False
    )
    
    # Grand total (renamed from final_amount)
    grand_total = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Grand Total",
        help_text="Final payable amount",
        editable=False
    )
    
    # Payment tracking
    advance_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Advance Paid",
        editable=False
    )
    
    balance = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name="Balance Due",
        editable=False
    )
    
    # ==================== NOTES - RENAMED FIELDS ====================
    
    # Renamed from 'notes'
    order_summary = models.TextField(
        blank=True,
        verbose_name="Order Summary",
        help_text="Quick overview/notes (internal use)"
    )
    
    # Renamed from 'special_requirements'
    customer_instructions = models.TextField(
        blank=True,
        verbose_name="Customer Instructions",
        help_text="Specific requirements from customer"
    )
    
    # Status & Workflow
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('IN_PROGRESS', 'In Progress'),
        ('READY', 'Ready for Delivery'),
        ('DELIVERED', 'Delivered'),
        ('CANCELLED', 'Cancelled'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        verbose_name="Order Status"
    )
    
    PRIORITY_CHOICES = [
        ('LOW', 'Low'),
        ('NORMAL', 'Normal'),
        ('HIGH', 'High'),
        ('URGENT', 'Urgent'),
    ]
    priority = models.CharField(
        max_length=20,
        choices=PRIORITY_CHOICES,
        default='NORMAL',
        verbose_name="Priority"
    )
    
    assigned_to = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_orders',
        verbose_name="Assigned To"
    )
    
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='orders_created',
        verbose_name="Created By"
    )
    
    workflow_enabled = models.BooleanField(
        default=False,
        verbose_name="Workflow Enabled"
    )
 #this is related to work flow we will implement in latter stage   
 #   current_stage = models.ForeignKey(
 #       'masters.WorkflowStage',
 #       on_delete=models.SET_NULL,
 #       null=True,
 #       blank=True,
 #       related_name='current_orders',
 #       verbose_name="Current Workflow Stage"
 #   )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    objects = TenantManager()  
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Order"
        verbose_name_plural = "Orders"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tenant', 'status']),
            models.Index(fields=['customer', 'status']),
            models.Index(fields=['order_number']),
          #  models.Index(fields=['barcode']),
        ]
    
    def generate_qr_code(self):
        """Generate QR code for order tracking"""
        if not self.order_number:
            return
        
        import qrcode
        from io import BytesIO
        from django.core.files import File
        
        # QR Code data
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
        file_name = f'qr_{self.order_number}.png'
        
        # Save to model field
        self.qr_code.save(file_name, File(buffer), save=False)
        buffer.close()
    
    # ==================== END OF NEW METHOD ====================
    
    def __str__(self):
        return f"{self.order_number} - {self.customer.display_name}"
    
    def save(self, *args, **kwargs):
       # Generate order number if not exists
        if not self.order_number or self.order_number.strip() == '':
            date_str = timezone.now().strftime('%Y%m')
            last_order = Order.objects.filter(
                tenant=self.tenant,
                order_number__startswith=f'ORD-{date_str}'
            ).order_by('-order_number').first()
            
            if last_order:
                last_num = int(last_order.order_number.split('-')[-1])
                new_num = last_num + 1
            else:
                new_num = 1
            
            self.order_number = f'ORD-{date_str}-{new_num:05d}'
        
        # Check if this is a new order (no primary key yet)
        is_new = self.pk is None
        
        # First save to get ID
        super().save(*args, **kwargs)
        
        # Generate QR code only for new orders
        if is_new and not self.qr_code:
            self.generate_qr_code()
            # Update only QR code field
            Order.objects.filter(pk=self.pk).update(qr_code=self.qr_code)
        
    def update_totals(self):
        """Calculate and update order totals from items"""
        items = self.items.all()
        
        # Calculate subtotal
        self.subtotal = sum(item.subtotal for item in items) or Decimal('0.00')
        
        # Calculate order-level discount
        if self.order_discount_percentage > 0:
            self.order_discount_amount = self.subtotal * (
                self.order_discount_percentage / 100
            )
        else:
            self.order_discount_amount = Decimal('0.00')
        
        # Calculate total discount
        item_discounts = sum(item.item_discount_amount for item in items) or Decimal('0.00')
        self.total_discount = item_discounts + self.order_discount_amount
        
        # Calculate total tax
        self.total_tax = sum(item.tax_amount for item in items) or Decimal('0.00')
        
        # Calculate grand total
        item_totals = sum(item.total_price for item in items) or Decimal('0.00')
        self.grand_total = item_totals - self.order_discount_amount
        
        # Calculate balance
        self.balance = self.grand_total - self.advance_paid
        
        self.save(update_fields=[
            'subtotal', 'order_discount_amount', 'total_discount',
            'total_tax', 'grand_total', 'balance', 'updated_at'
        ])
    
    @property
    def is_paid(self):
        """Check if order is fully paid"""
        return self.balance <= 0
    
    @property
    def is_overdue(self):
        """Check if order is overdue"""
        if self.status in ['DELIVERED', 'CANCELLED']:
            return False
        if not self.planned_delivery_date:
            return False
        return timezone.now().date() > self.planned_delivery_date
    
    @property
    def is_delayed(self):
        """Check if order is delayed"""
        return self.is_overdue and self.status not in ['DELIVERED', 'CANCELLED']
    
    @property
    def delay_days(self):
        """Calculate number of days delayed"""
        if not self.is_delayed:
            return 0
        return (timezone.now().date() - self.planned_delivery_date).days
    
    @property
    def days_until_delivery(self):
        """Calculate days until planned delivery"""
        if not self.planned_delivery_date:
            return None
        delta = self.planned_delivery_date - timezone.now().date()
        return delta.days


# ==================== ORDER ITEM MODEL ====================


# ==================== ORDER ITEM MODEL - ENHANCED ====================

class OrderItem(models.Model):
    """Order item with item-level discount and tax - Enhanced with Family Member support"""
    
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name="Order"
    )
    
    # ==================== NEW FIELD - FAMILY MEMBER ====================
    family_member = models.ForeignKey(
        'FamilyMember',
        on_delete=models.PROTECT,
        related_name='order_items',
        null=True,  # Nullable for backward compatibility
        blank=True,
        verbose_name='For Person',
        help_text='Which family member is this item for?'
    )
    # ==================== END NEW FIELD ====================
    
    category = models.ForeignKey(
        'masters.ItemCategory',
        on_delete=models.PROTECT,
        related_name='order_items',
        verbose_name="Category",
        null=True,
        blank=True,
        help_text="Optional - not used in current workflow"
    )
    
    inventory_item = models.ForeignKey(
        'inventory.InventoryItem',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='order_items',
        verbose_name='Inventory Item',
        help_text='Link to inventory (for PRODUCT/SERVICE types only)'
    )

    unit = models.CharField(
        max_length=10,
        choices=[
            ('METER', 'Meter'),
            ('PIECE', 'Piece'),
            ('KG', 'Kilogram'),
            ('GRAM', 'Gram'),
            ('YARD', 'Yard'),
            ('SET', 'Set'),
        ],
        null=True,
        blank=True,
        verbose_name='Unit',
        help_text='Unit of measurement (auto-filled from inventory)'
    )
    
    hsn_code = models.CharField(
        max_length=10,
        blank=True,
        default='',
        verbose_name="HSN/SAC Code",
        help_text="HSN code for GST compliance (e.g., 6217 for garments)"
    )
    
    # ==================== UPDATED CHOICES - SIMPLIFIED ====================
    ITEM_TYPE_CHOICES = [
        ('PRODUCT', 'Product'),  # Any physical item (fabric, ready garment, accessory)
        ('SERVICE', 'Service'),  # Any service (stitching, alteration, embroidery)
    ]
    # ==================== END UPDATED CHOICES ====================
    
    item_type = models.CharField(
        max_length=20,
        choices=ITEM_TYPE_CHOICES,
        default='SERVICE',
        verbose_name="Item Type"
    )
    
    # Renamed from 'item_name'
    item_description = models.CharField(
        max_length=200,
        null=True,
        verbose_name="Item Description",
        help_text="Detailed description (e.g., 'Bridal Lehenga - Red Silk')"
    )
    
    description = models.TextField(
        blank=True,
        verbose_name="Additional Details"
    )
    
    # ==================== NEW FIELD - MEASUREMENT SNAPSHOT ====================
    measurements_snapshot = models.JSONField(
        null=True,
        blank=True,
        verbose_name='Measurement Snapshot',
        help_text='Frozen copy of measurements at order time'
    )
    # ==================== END NEW FIELD ====================
    
    # ==================== PRICING - BASE ====================
    
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Unit Price",
        help_text="Base price per unit (before discount/tax)"
    )
    
    quantity = models.IntegerField(
        default=1,
        validators=[MinValueValidator(1)],
        verbose_name="Quantity"
    )
    
    subtotal = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Subtotal",
        help_text="Unit price × Quantity",
        editable=False
    )
    
    # ==================== ITEM-LEVEL DISCOUNT ====================
    
    item_discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Item Discount %"
    )
    
    item_discount_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Discount Amount",
        editable=False
    )
    
    total_after_discount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="After Discount",
        editable=False
    )
    
    # ==================== ITEM-LEVEL TAX ====================
    
    tax_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Tax/GST %",
        help_text="Tax percentage (5, 12, 18, or 28)"
    )
    
    tax_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Tax Amount",
        editable=False
    )
    
    # ==================== FINAL ITEM TOTAL ====================
    
    total_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Item Total",
        editable=False
    )
    
    # Fabric Info
    fabric_provided_by_customer = models.BooleanField(
        default=False,
        verbose_name="Customer's Fabric"
    )
    
    fabric_details = models.TextField(
        blank=True,
        verbose_name="Fabric Details"
    )
    
    # Item Notes
    notes = models.TextField(
        blank=True,
        verbose_name="Item-Specific Notes"
    )
    
    # Status
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
        ('ON_HOLD', 'On Hold'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        verbose_name="Item Status"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    
    class Meta:
        verbose_name = "Order Item"
        verbose_name_plural = "Order Items"
        ordering = ['id']
    
    def __str__(self):
        return f"{self.item_description} - {self.order.order_number}"
    
    def populate_from_inventory(self):
        """
        Auto-populate item details from linked inventory
        Call this when inventory_item is selected
        """
        if self.inventory_item:
            # Auto-fill basic details
            self.item_description = self.inventory_item.name
            self.unit_price = self.inventory_item.selling_price
            self.unit = self.inventory_item.unit
            
            # Auto-fill category if not set
            if not self.category and self.inventory_item.category:
                self.category = self.inventory_item.category
            
            # Auto-fill HSN code from inventory's category
            if self.inventory_item.category and hasattr(self.inventory_item.category, 'default_hsn_code'):
                if self.inventory_item.category.default_hsn_code:
                    self.hsn_code = self.inventory_item.category.default_hsn_code
            
            # Auto-fill tax percentage from category
            if self.category and hasattr(self.category, 'gst_percentage'):
                self.tax_percentage = self.category.gst_percentage or Decimal('0.00')
    """qrcode generation  start"""
    def generate_qr_code(self):
        """
        Generate QR code for order tracking
        QR contains: Order number + Deep link
        """
        if not self.order_number:
            return
        
        # QR Code data - this is what gets encoded
        qr_data = f"ORDER:{self.order_number}:{self.id}"
        # Alternative for deep linking: qr_data = f"tailorapp://order/{self.order_number}"
        
        # Create QR code instance
        qr = qrcode.QRCode(
            version=1,  # Size (1 is smallest, 40 is largest)
            error_correction=qrcode.constants.ERROR_CORRECT_H,  # High error correction (30%)
            box_size=10,  # Size of each box in pixels
            border=4,  # Border size (minimum is 4)
        )
        
        # Add data to QR code
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        # Create image
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save to BytesIO
        buffer = BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        
        # Generate filename
        file_name = f'qr_{self.order_number}.png'
        
        # Save to model field
        self.qr_code.save(file_name, File(buffer), save=False)
        buffer.close()
    """qr code end"""            
    def save(self, *args, **kwargs):
            # Auto-populate HSN code from category if not set (category is optional now)
        if not self.hsn_code and self.category_id:
            try:
                if hasattr(self.category, 'default_hsn_code') and self.category.default_hsn_code:
                    self.hsn_code = self.category.default_hsn_code
            except:
                pass  # Category is optional, skip if error
        
        # Ensure fields have valid values before calculation
        try:
            # Convert to Decimal safely
            unit_price = Decimal(str(self.unit_price)) if self.unit_price else Decimal('0.00')
            quantity = int(self.quantity) if self.quantity else 1
            item_discount_pct = Decimal(str(self.item_discount_percentage)) if self.item_discount_percentage else Decimal('0.00')
            tax_pct = Decimal(str(self.tax_percentage)) if self.tax_percentage else Decimal('0.00')
            
            # Step 1: Calculate subtotal
            self.subtotal = unit_price * quantity
            
            # Step 2: Calculate item discount
            if item_discount_pct > 0:
                self.item_discount_amount = self.subtotal * (item_discount_pct / Decimal('100'))
            else:
                self.item_discount_amount = Decimal('0.00')
            
            # Step 3: Amount after discount
            self.total_after_discount = self.subtotal - self.item_discount_amount
            
            # Step 4: Calculate tax
            if tax_pct > 0:
                self.tax_amount = self.total_after_discount * (tax_pct / Decimal('100'))
            else:
                self.tax_amount = Decimal('0.00')
            
            # Step 5: Final item total
            self.total_price = self.total_after_discount + self.tax_amount
            
        except (ValueError, TypeError, InvalidOperation) as e:
            # If any calculation fails, set safe defaults
            self.subtotal = Decimal('0.00')
            self.item_discount_amount = Decimal('0.00')
            self.total_after_discount = Decimal('0.00')
            self.tax_amount = Decimal('0.00')
            self.total_price = Decimal('0.00')
        
        # Step 6: Save the item
        super().save(*args, **kwargs)
        
        # Step 7: Update order totals
        try:
            self.order.update_totals()
        except:
            pass  # Don't fail save if order update fails
            
    
    def delete(self, *args, **kwargs):
        """Update order totals when item is deleted"""
        order = self.order
        super().delete(*args, **kwargs)
        order.update_totals()


# ==================== ORDER ITEM MEASUREMENT MODEL ====================

class OrderItemMeasurement(models.Model):
    """Measurements for order items"""
    
    order_item = models.ForeignKey(
        OrderItem,
        on_delete=models.CASCADE,
        related_name='measurements',
        verbose_name="Order Item"
    )
    
    measurement_field = models.ForeignKey(
        'masters.MeasurementField',
        on_delete=models.PROTECT,
        related_name='order_measurements',
        verbose_name="Measurement Field"
    )
    
    value = models.CharField(
        max_length=50,
        verbose_name="Measurement Value"
    )
    
    UNIT_CHOICES = [
        ('inches', 'Inches'),
        ('cm', 'Centimeters'),
        ('meters', 'Meters'),
    ]
    unit = models.CharField(
        max_length=20,
        choices=UNIT_CHOICES,
        default='inches',
        verbose_name="Unit"
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name="Measurement Notes"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    
    class Meta:
        verbose_name = "Order Item Measurement"
        verbose_name_plural = "Order Item Measurements"
    
    def __str__(self):
        # FIXED: Use field_label instead of name
        return f"{self.measurement_field.field_label}: {self.value} {self.unit}"

# ==================== ORDER PAYMENT MODEL START====================
# Enhanced OrderPayment Model

"""
SIMPLIFIED Order Payment Model
Clean, minimal, easy to understand
"""

from django.db import models
from django.utils import timezone
from decimal import Decimal
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError


class OrderPayment(models.Model):
    """
    Simplified Payment Model
    - Positive amount = Payment received
    - Negative amount = Refund/Void
    - Only CASH payments track bank deposits
    """
    
    # Link to order
    order = models.ForeignKey(
        'Order',
        on_delete=models.CASCADE,
        related_name='payments',
        verbose_name="Order"
    )
    
    # Auto-generated payment number
    payment_number = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        verbose_name="Payment Number",
        help_text="Auto-generated: PAY-YYYYMM-NNNNN"
    )
    
    # Amount (positive = payment, negative = refund)
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name="Amount",
        help_text="Positive for payments, negative for refunds/voids"
    )
    
    # Payment Method
    PAYMENT_METHOD_CHOICES = [
        ('CASH', 'Cash'),
        ('UPI', 'UPI'),
        ('CARD', 'Card'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('CHEQUE', 'Cheque'),
    ]
    payment_method = models.CharField(
        max_length=20,
        choices=PAYMENT_METHOD_CHOICES,
        default='CASH',
        verbose_name="Payment Method"
    )
    
    # Payment Date
    payment_date = models.DateTimeField(
        default=timezone.now,
        verbose_name="Payment Date"
    )
    
    # Reference Number (optional - for UPI/Bank/Cheque)
    reference_number = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Reference Number",
        help_text="Transaction ID, Cheque Number, etc."
    )
    
    # Notes (optional)
    notes = models.TextField(
        blank=True,
        verbose_name="Notes",
        help_text="Any additional information, refund reason, etc."
    )
    
    # Bank/Account where payment received (for all methods)
    bank_name = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Bank/Account Name",
        help_text="Bank name or cash box where payment received"
    )
    
    # === CASH DEPOSIT TRACKING (Only for CASH payments) ===
    
    deposited_to_bank = models.BooleanField(
        default=False,
        verbose_name="Cash Deposited to Bank",
        help_text="Has cash been deposited? (Only for CASH payments)"
    )
    
    deposit_date = models.DateField(
        null=True,
        blank=True,
        verbose_name="Deposit Date"
    )
    
    deposit_bank_name = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Deposit Bank Name",
        help_text="Bank where cash was deposited"
    )
    
    # === AUDIT ===
    
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='payments_created',
        verbose_name="Created By"
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Created At"
    )
    
    class Meta:
        verbose_name = "Payment"
        verbose_name_plural = "Payments"
        ordering = ['-payment_date']
        indexes = [
            models.Index(fields=['payment_number']),
            models.Index(fields=['payment_date']),
            models.Index(fields=['-payment_date']),  # For recent payments
            models.Index(fields=['order', '-payment_date']),  # For order payment history
        ]
    
    def __str__(self):
        sign = "+" if self.amount >= 0 else ""
        return f"{self.payment_number} - {sign}₹{self.amount} - {self.order.order_number}"
    
    @property
    def is_refund(self):
        """Check if this is a refund (negative amount)"""
        return self.amount < 0
    
    @property
    def customer_name(self):
        """Get customer name from order"""
        return self.order.customer.name if self.order and self.order.customer else None
    
    @property
    def customer_phone(self):
        """Get customer phone from order"""
        return self.order.customer.phone if self.order and self.order.customer else None
    
    @property
    def order_number(self):
        """Get order number"""
        return self.order.order_number if self.order else None
    
    def clean(self):
        """Validation"""
        # Can't deposit non-cash to bank
        if self.deposited_to_bank and self.payment_method != 'CASH':
            raise ValidationError({
                'deposited_to_bank': 'Only CASH payments can be marked as deposited to bank'
            })
        
        # If deposited, need deposit details
        if self.deposited_to_bank:
            if not self.deposit_date:
                raise ValidationError({
                    'deposit_date': 'Deposit date required when marking as deposited'
                })
            if not self.deposit_bank_name:
                raise ValidationError({
                    'deposit_bank_name': 'Deposit bank name required when marking as deposited'
                })
        
        # Payment date can't be in future
        if self.payment_date and self.payment_date > timezone.now():
            raise ValidationError({
                'payment_date': 'Payment date cannot be in the future'
            })
    
    def save(self, *args, **kwargs):
        # Auto-generate payment number if not exists
        if not self.payment_number:
            self.payment_number = self._generate_payment_number()
        
        # Run validation
        self.clean()
        
        super().save(*args, **kwargs)
        
        # Update order advance_paid
        self._update_order_paid_amount()
    
    def _generate_payment_number(self):
        """Generate unique payment number: PAY-YYYYMM-NNNNN"""
        from django.db.models import Max
        
        year_month = timezone.now().strftime('%Y%m')
        prefix = f'PAY-{year_month}-'
        
        # Get last number for this month
        last_payment = OrderPayment.objects.filter(
            payment_number__startswith=prefix
        ).aggregate(Max('payment_number'))['payment_number__max']
        
        if last_payment:
            last_num = int(last_payment.split('-')[-1])
            new_num = last_num + 1
        else:
            new_num = 1
        
        return f'{prefix}{new_num:05d}'
    
    def _update_order_paid_amount(self):
        """Update order's advance_paid field"""
        if self.order:
            total_paid = self.order.payments.aggregate(
                total=models.Sum('amount')
            )['total'] or Decimal('0.00')
            
            self.order.advance_paid = max(total_paid, Decimal('0.00'))
            self.order.save(update_fields=['advance_paid'])


# ==================== HELPER METHOD FOR ORDER MODEL ====================
"""
Add this method to your Order model:

@property
def payment_balance(self):
    '''Calculate remaining balance'''
    return self.grand_total - (self.advance_paid or Decimal('0.00'))

@property
def is_fully_paid(self):
    '''Check if order is fully paid'''
    return self.payment_balance <= 0
"""
# ==================== ORDER PAYMENT MODEL END====================

# ==================== ORDER NOTE MODEL ====================

class OrderNote(models.Model):
    """Communication timeline for orders"""
    
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='notes',
        verbose_name="Order"
    )
    
    NOTE_TYPE_CHOICES = [
        ('GENERAL', 'General Note'),
        ('CUSTOMER', 'Customer Communication'),
        ('INTERNAL', 'Internal Note'),
        ('CHANGE', 'Change Request'),
        ('ISSUE', 'Issue/Problem'),
    ]
    note_type = models.CharField(
        max_length=20,
        choices=NOTE_TYPE_CHOICES,
        default='GENERAL',
        verbose_name="Note Type"
    )
    
    note = models.TextField(verbose_name="Note")
    
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='order_notes_created',
        verbose_name="Created By"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    
    class Meta:
        verbose_name = "Order Note"
        verbose_name_plural = "Order Notes"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.get_note_type_display()} - {self.order.order_number}"


# ==================== ORDER STATUS HISTORY MODEL ====================

class OrderStatusHistory(models.Model):
    """Track status changes for orders"""
    
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='status_history',
        verbose_name="Order"
    )
    
    from_status = models.CharField(
        max_length=20,
        verbose_name="From Status"
    )
    
    to_status = models.CharField(
        max_length=20,
        verbose_name="To Status"
    )
    
    notes = models.TextField(blank=True)
    
    changed_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='status_changes',
        verbose_name="Changed By"
    )
    
    changed_at = models.DateTimeField(auto_now_add=True)
    
    
    class Meta:
        verbose_name = "Order Status History"
        verbose_name_plural = "Order Status Histories"
        ordering = ['-changed_at']
    
    def __str__(self):
        return f"{self.order.order_number}: {self.from_status} → {self.to_status}"


# ==================== ORDER ASSIGNMENT MODEL ====================

class OrderAssignment(models.Model):
    """Assign orders to staff members"""
    
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='assignments',
        verbose_name="Order"
    )
    
    assigned_to = models.ForeignKey(
        'core.User',
        on_delete=models.CASCADE,
        related_name='order_assignments',
        verbose_name="Assigned To"
    )
    
    assigned_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='assignments_created',
        verbose_name="Assigned By"
    )
    
    ROLE_CHOICES = [
        ('CUTTER', 'Cutter'),
        ('TAILOR', 'Tailor'),
        ('DESIGNER', 'Designer'),
        ('FINISHER', 'Finisher'),
        ('QC', 'Quality Check'),
    ]
    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        verbose_name="Role"
    )
    
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
        ('REJECTED', 'Rejected'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        verbose_name="Status"
    )
    
    sequence = models.IntegerField(
        default=1,
        verbose_name="Sequence",
        help_text="Order of execution (1, 2, 3...)"
    )
    
    instructions = models.TextField(
        blank=True,
        verbose_name="Instructions"
    )
    
    completion_notes = models.TextField(
        blank=True,
        verbose_name="Completion Notes"
    )
    
    rejection_reason = models.TextField(
        blank=True,
        verbose_name="Rejection Reason"
    )
    
    assigned_at = models.DateTimeField(auto_now_add=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    
    class Meta:
        verbose_name = "Order Assignment"
        verbose_name_plural = "Order Assignments"
        ordering = ['order', 'sequence']
    
    def __str__(self):
        return f"{self.order.order_number} - {self.get_role_display()}"
    
    @property
    def time_spent(self):
        """Calculate time spent on this assignment"""
        if self.started_at and self.completed_at:
            return self.completed_at - self.started_at
        return None

"""
Invoicing Models - Phase 4
GST-Compliant for India
Add these to orders/models.py at the end
"""

# ==================== INVOICE MODEL ====================
# ==================== INVOICE MODEL ====================

class Invoice(models.Model):
    """
    Sales Invoice - GST Compliant for India
    Generated from completed orders
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='invoices'
    )
    
    order = models.ForeignKey(
        'Order',
        on_delete=models.PROTECT,
        related_name='invoices',
        verbose_name="Order"
    )
    
    customer = models.ForeignKey(
        'Customer',
        on_delete=models.PROTECT,
        related_name='invoices',
        verbose_name="Customer"
    )
    
    # Invoice Details
    invoice_number = models.CharField(
        max_length=50,
        unique=True,
        blank=True,          
        default='',           
        verbose_name="Invoice Number",
        help_text="Auto-generated. Leave blank."
    )
    
    INVOICE_TYPE_CHOICES = [
        ('TAX_INVOICE', 'Tax Invoice'),
        ('BILL_OF_SUPPLY', 'Bill of Supply'),
        ('EXPORT_INVOICE', 'Export Invoice'),
    ]
    invoice_type = models.CharField(
        max_length=20,
        choices=INVOICE_TYPE_CHOICES,
        default='TAX_INVOICE',
        verbose_name="Invoice Type"
    )
    
    invoice_date = models.DateField(
        default=timezone.now,
        verbose_name="Invoice Date"
    )
    
    due_date = models.DateField(
        null=True,
        blank=True,
        verbose_name="Payment Due Date"
    )
    
    # Amounts
    subtotal = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Subtotal"
    )
    
    total_discount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Total Discount"
    )
    
    taxable_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Taxable Amount"
    )
    
    # GST Breakup
    cgst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="CGST Amount"
    )
    
    sgst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="SGST Amount"
    )
    
    igst_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="IGST Amount",
        help_text="For inter-state transactions"
    )
    
    total_tax = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Total Tax/GST"
    )
    
    grand_total = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Grand Total"
    )
    
    round_off = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name="Round Off"
    )
    
    # Additional Info
    place_of_supply = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Place of Supply",
        help_text="State name for GST compliance"
    )
    
    reverse_charge = models.BooleanField(
        default=False,
        verbose_name="Reverse Charge Applicable"
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name="Notes/Terms & Conditions"
    )
    
    # Status
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('SENT', 'Sent to Customer'),
        ('PAID', 'Paid'),
        ('PARTIALLY_PAID', 'Partially Paid'),
        ('OVERDUE', 'Overdue'),
        ('CANCELLED', 'Cancelled'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='DRAFT',
        verbose_name="Invoice Status"
    )
    
    # Payment tracking
    amount_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Amount Paid"
    )
    
    balance_due = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name="Balance Due"
    )
    
    # PDF Generation
    pdf_generated = models.BooleanField(default=False)
    pdf_file = models.FileField(
        upload_to='invoices/pdf/',
        null=True,
        blank=True
    )
    
    # E-Invoice
    irn = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="IRN",
        help_text="Invoice Reference Number (e-invoice)"
    )
    
    ack_number = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Acknowledgement Number"
    )
    
    ack_date = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="Acknowledgement Date"
    )
    
    # Email tracking
    email_sent = models.BooleanField(default=False)
    email_sent_at = models.DateTimeField(null=True, blank=True)
    
    # Timestamps
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='invoices_created'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    objects = TenantManager()  # Auto-filters by tenant
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = "Invoice"
        verbose_name_plural = "Invoices"
        ordering = ['-invoice_date', '-created_at']
        indexes = [
            models.Index(fields=['tenant', 'invoice_date']),
            models.Index(fields=['customer']),
            models.Index(fields=['invoice_number']),
        ]
    
    def __str__(self):
        return f"{self.invoice_number} - {self.customer.name}"
    
    def save(self, *args, **kwargs):
        """Auto-generate invoice number and calculate GST"""
        from django.db import transaction
        
        # Generate invoice number if empty
        if not self.invoice_number or self.invoice_number.strip() == '':
            financial_year = self.get_financial_year()
            
            with transaction.atomic():
                last_invoice = Invoice.objects.filter(
                    tenant=self.tenant,
                    invoice_number__startswith=f'INV-{financial_year}',
                    invoice_number__isnull=False
                ).exclude(
                    invoice_number=''
                ).select_for_update().order_by('-invoice_number').first()
                
                if last_invoice:
                    try:
                        last_num = int(last_invoice.invoice_number.split('-')[-1])
                        new_num = last_num + 1
                    except (ValueError, IndexError):
                        new_num = 1
                else:
                    new_num = 1
                
                self.invoice_number = f'INV-{financial_year}-{new_num:05d}'
        
        # Auto-populate from order on creation
        if self.order and not self.pk:
            self.subtotal = self.order.subtotal
            self.total_discount = self.order.total_discount
            self.total_tax = self.order.total_tax
            self.grand_total = self.order.grand_total
            self.taxable_amount = self.order.subtotal - self.order.total_discount
            
            if not self.customer:
                self.customer = self.order.customer
        
        # Ensure taxable amount
        if self.subtotal and not self.taxable_amount:
            self.taxable_amount = self.subtotal - (self.total_discount or Decimal('0.00'))
        
        # Calculate GST breakdown
        if self.total_tax and self.total_tax > 0:
            if self.customer and self.tenant:
                customer_state = (self.customer.state or '').strip().upper()
                tenant_state = ''
                
                if hasattr(self.tenant, 'state') and self.tenant.state:
                    tenant_state = self.tenant.state.strip().upper()
                
                if customer_state and tenant_state:
                    self.calculate_gst(customer_state, tenant_state)
                else:
                    # Default: Same state
                    self.cgst_amount = self.total_tax / 2
                    self.sgst_amount = self.total_tax / 2
                    self.igst_amount = Decimal('0.00')
            else:
                self.cgst_amount = self.total_tax / 2
                self.sgst_amount = self.total_tax / 2
                self.igst_amount = Decimal('0.00')
        
        # Calculate balance
        self.balance_due = (self.grand_total or Decimal('0.00')) - (self.amount_paid or Decimal('0.00'))
        
        # Update status
        if self.balance_due <= 0 and self.status != 'CANCELLED':
            self.status = 'PAID'
        elif self.amount_paid > 0 and self.status != 'CANCELLED':
            self.status = 'PARTIALLY_PAID'
        elif self.due_date and timezone.now().date() > self.due_date and self.status not in ['PAID', 'CANCELLED']:
            self.status = 'OVERDUE'
        
        super().save(*args, **kwargs)
    
    def get_financial_year(self):
        """Get financial year in format FY2526"""
        today = timezone.now().date()
        if today.month >= 4:
            return f'FY{today.year % 100}{(today.year + 1) % 100}'
        else:
            return f'FY{(today.year - 1) % 100}{today.year % 100}'
    
    def calculate_gst(self, customer_state, tenant_state):
        """Calculate CGST/SGST or IGST based on state"""
        customer_state = customer_state.strip().upper()
        tenant_state = tenant_state.strip().upper()
        
        if customer_state == tenant_state:
            # Same state - Intra-state (CGST + SGST)
            self.cgst_amount = self.total_tax / 2
            self.sgst_amount = self.total_tax / 2
            self.igst_amount = Decimal('0.00')
        else:
            # Different state - Inter-state (IGST)
            self.cgst_amount = Decimal('0.00')
            self.sgst_amount = Decimal('0.00')
            self.igst_amount = self.total_tax
# ==================== INVOICE ITEM MODEL ===================

class InvoiceItem(models.Model):
    """
    Invoice line items
    """
    
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name="Invoice"
    )
    
    order_item = models.ForeignKey(
        'OrderItem',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='invoice_items'
    )
    
    # Item Details
    description = models.CharField(
        max_length=500,
        verbose_name="Item Description"
    )
    
    hsn_code = models.CharField(
        max_length=10,
        blank=True,
        verbose_name="HSN/SAC Code",
        help_text="For GST compliance"
    )
    
    quantity = models.IntegerField(
        default=1,
        validators=[MinValueValidator(1)]
    )
    
    unit = models.CharField(
        max_length=20,
        default='PCS',
        verbose_name="Unit"
    )
    
    # Pricing
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    
    subtotal = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    
    discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    discount_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    taxable_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    # Tax
    tax_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name="GST %"
    )
    
    tax_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    total_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    
    class Meta:
        verbose_name = "Invoice Item"
        verbose_name_plural = "Invoice Items"
        ordering = ['id']
    
    def __str__(self):
        return f"{self.description} - {self.invoice.invoice_number}"
    
    def save(self, *args, **kwargs):
        """Auto-calculate amounts"""
        self.subtotal = Decimal(str(self.unit_price)) * self.quantity
        
        if self.discount_percentage > 0:
            self.discount_amount = self.subtotal * (self.discount_percentage / 100)
        
        self.taxable_amount = self.subtotal - self.discount_amount
        
        if self.tax_percentage > 0:
            self.tax_amount = self.taxable_amount * (self.tax_percentage / 100)
        
        self.total_amount = self.taxable_amount + self.tax_amount
        
        super().save(*args, **kwargs)


# ==================== CREDIT NOTE MODEL ====================

class CreditNote(models.Model):
    """
    Credit Note for returns/cancellations
    """
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='credit_notes'
    )
    
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.PROTECT,
        related_name='credit_notes'
    )
    
    credit_note_number = models.CharField(
        max_length=50,
        unique=True
    )
    
    credit_note_date = models.DateField(default=timezone.now)
    
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    
    reason = models.TextField(verbose_name="Reason for Credit Note")
    
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('ISSUED', 'Issued'),
        ('APPLIED', 'Applied to Invoice'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='DRAFT'
    )
    
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    
    class Meta:
        verbose_name = "Credit Note"
        verbose_name_plural = "Credit Notes"
        ordering = ['-credit_note_date']
    
    def __str__(self):
        return f"{self.credit_note_number} - ₹{self.amount}"
    
"""
Purchase Management & Vendor Models - Phase 4
Add these to orders/models.py after Invoice models
"""

from django.db import models
from django.utils import timezone
from decimal import Decimal
from django.core.validators import MinValueValidator


# ==================== VENDOR MODEL ====================

"""
================================================================================
DEPRECATED CODE - MOVED TO purchase_management APP
================================================================================
Deprecated: 30-Dec-2025
Model: Vendor
Reason: Moved to purchase_management app for better separation of concerns
New Location: purchase_management.models.Vendor
Migration Status: Pending
Notes: Keep for reference until data migration is complete
================================================================================
"""
# class Vendor(models.Model):
#     """
#     Vendor/Supplier Master
#     """
    
#     tenant = models.ForeignKey(
#         'core.Tenant',
#         on_delete=models.CASCADE,
#         related_name='vendors'
#     )
    
#     VENDOR_TYPE_CHOICES = [
#         ('FABRIC', 'Fabric Supplier'),
#         ('ACCESSORIES', 'Accessories Supplier'),
#         ('EXTERNAL_WORK', 'External Work Vendor'),  # For Phase 7
#         ('OTHER', 'Other'),
#     ]
#     vendor_type = models.CharField(
#         max_length=20,
#         choices=VENDOR_TYPE_CHOICES,
#         verbose_name="Vendor Type"
#     )
    
#     # Basic Info
#     vendor_code = models.CharField(
#         max_length=20,
#         unique=True,
#         blank=True,
#         verbose_name="Vendor Code"
#     )
    
#     name = models.CharField(
#         max_length=200,
#         verbose_name="Vendor Name"
#     )
    
#     business_name = models.CharField(
#         max_length=200,
#         blank=True,
#         verbose_name="Business/Shop Name"
#     )
    
#     contact_person = models.CharField(
#         max_length=100,
#         blank=True,
#         verbose_name="Contact Person"
#     )
    
#     phone = models.CharField(max_length=15, verbose_name="Phone")
#     alternate_phone = models.CharField(max_length=15, blank=True)
#     email = models.EmailField(blank=True, null=True,)
    
#     # Address
#     address = models.TextField(blank=True)
#     city = models.CharField(max_length=100, blank=True)
#     state = models.CharField(max_length=100, blank=True)
#     pincode = models.CharField(max_length=6, blank=True)
    
#     # GST Details
#     gstin = models.CharField(
#         max_length=15,
#         blank=True,
#         verbose_name="GSTIN"
#     )
    
#     pan = models.CharField(
#         max_length=10,
#         blank=True,
#         verbose_name="PAN"
#     )
    
#     # Payment Terms
#     PAYMENT_TERMS_CHOICES = [
#         ('CASH', 'Cash'),
#         ('CREDIT_7', '7 Days Credit'),
#         ('CREDIT_15', '15 Days Credit'),
#         ('CREDIT_30', '30 Days Credit'),
#         ('CREDIT_45', '45 Days Credit'),
#         ('ADVANCE', 'Advance Payment'),
#     ]
#     payment_terms = models.CharField(
#         max_length=20,
#         choices=PAYMENT_TERMS_CHOICES,
#         default='CASH'
#     )
    
#     credit_limit = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00'),
#         verbose_name="Credit Limit"
#     )
    
#     # Bank Details
#     bank_name = models.CharField(max_length=100, blank=True)
#     account_number = models.CharField(max_length=50, blank=True)
#     ifsc_code = models.CharField(max_length=15, blank=True)
    
#     # Vendor Performance
#     rating = models.DecimalField(
#         max_digits=3,
#         decimal_places=2,
#         default=Decimal('0.00'),
#         validators=[MinValueValidator(Decimal('0.00'))],
#         help_text="Vendor rating (0-5)"
#     )
    
#     total_purchases = models.IntegerField(default=0)
#     total_purchase_amount = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     outstanding_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     # Status
#     is_active = models.BooleanField(default=True)
#     notes = models.TextField(blank=True)
    
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
#     objects = TenantManager()  
#     all_objects = models.Manager()  
    
    
#     class Meta:
#         verbose_name = "Vendor"
#         verbose_name_plural = "Vendors"
#         ordering = ['name']
#         indexes = [
#             models.Index(fields=['tenant', 'vendor_type']),
#             models.Index(fields=['name']),
#         ]
    
#     def __str__(self):
#         return f"{self.vendor_code} - {self.name}"
    
#     def save(self, *args, **kwargs):
#         """Auto-generate vendor code"""
#         if not self.vendor_code:
#             type_code = self.vendor_type[:3].upper()
#             last_vendor = Vendor.objects.filter(
#                 tenant=self.tenant,
#                 vendor_code__startswith=f'VEN-{type_code}'
#             ).order_by('-vendor_code').first()
            
#             if last_vendor:
"""
================================================================================
DEPRECATED CODE - MOVED TO purchase_management APP
================================================================================
Deprecated: 30-Dec-2025
Model: PurchaseOrder
Reason: Moved to purchase_management app for better separation of concerns
New Location: purchase_management.models.PurchaseBill
Migration Status: Pending
Notes: Keep for reference until data migration is complete
================================================================================
"""
# #                 last_num = int(last_vendor.vendor_code.split('-')[-1])
# #                 new_num = last_num + 1
# #             else:
# #                 new_num = 1
            
# #             self.vendor_code = f'VEN-{type_code}-{new_num:04d}'
        
# #         super().save(*args, **kwargs)

# """
# ================================================================================
# END DEPRECATED CODE
# ================================================================================
# """

# # ==================== PURCHASE ORDER MODEL ====================

# class PurchaseOrder(models.Model):
#     """
#     Purchase Order to Vendor
#     """
    
#     tenant = models.ForeignKey(
#         'core.Tenant',
#         on_delete=models.CASCADE,
#         related_name='purchase_orders'
#     )
    
#     vendor = models.ForeignKey(
#         Vendor,
#         on_delete=models.PROTECT,
#         related_name='purchase_orders'
#     )
    
#     po_number = models.CharField(
#         max_length=50,
#         unique=True,
#         verbose_name="PO Number"
#     )
    
#     po_date = models.DateField(
#         default=timezone.now,
#         verbose_name="PO Date"
#     )
    
#     expected_delivery_date = models.DateField(
#         null=True,
#         blank=True
#     )
    
#     # Amounts
#     subtotal = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     discount_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     tax_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     total_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     # Status
#     STATUS_CHOICES = [
#         ('DRAFT', 'Draft'),
#         ('SENT', 'Sent to Vendor'),
#         ('CONFIRMED', 'Confirmed by Vendor'),
#         ('PARTIALLY_RECEIVED', 'Partially Received'),
#         ('RECEIVED', 'Fully Received'),
#         ('CANCELLED', 'Cancelled'),
#     ]
#     status = models.CharField(
#         max_length=20,
#         choices=STATUS_CHOICES,
#         default='DRAFT'
#     )
    
#     notes = models.TextField(blank=True)
#     terms_and_conditions = models.TextField(blank=True)
    
#     created_by = models.ForeignKey(
#         'core.User',
#         on_delete=models.SET_NULL,
#         null=True,
#         related_name='pos_created'
#     )
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
#     objects = TenantManager()  
#     all_objects = models.Manager()  
    
    
#     class Meta:
"""
================================================================================
DEPRECATED CODE - MOVED TO purchase_management APP
================================================================================
Deprecated: 30-Dec-2025
Model: PurchaseInvoice
Reason: Moved to purchase_management app for better separation of concerns
New Location: purchase_management.models.PurchaseBill
Migration Status: Pending
Notes: Keep for reference until data migration is complete
================================================================================
"""
# #         verbose_name = "Purchase Order"
# #         verbose_name_plural = "Purchase Orders"
# #         ordering = ['-po_date']
    
# #     def __str__(self):
# #         return f"{self.po_number} - {self.vendor.name}"
    
# #     def save(self, *args, **kwargs):
# #         """Auto-generate PO number"""
# #         if not self.po_number:
# #             date_str = timezone.now().strftime('%y%m')
# #             last_po = PurchaseOrder.objects.filter(
# """
# ================================================================================
# END DEPRECATED CODE
# ================================================================================
# """
#                 tenant=self.tenant,
#                 po_number__startswith=f'PO-{date_str}'
#             ).order_by('-po_number').first()
            
#             if last_po:
#                 last_num = int(last_po.po_number.split('-')[-1])
#                 new_num = last_num + 1
#             else:
#                 new_num = 1
            
#             self.po_number = f'PO-{date_str}-{new_num:05d}'
        
#         super().save(*args, **kwargs)


# # ==================== PURCHASE INVOICE MODEL ====================

# class PurchaseInvoice(models.Model):
#     """
#     Purchase Invoice from Vendor
#     """
    
#     tenant = models.ForeignKey(
#         'core.Tenant',
#         on_delete=models.CASCADE,
#         related_name='purchase_invoices'
#     )
    
#     vendor = models.ForeignKey(
#         Vendor,
#         on_delete=models.PROTECT,
#         related_name='purchase_invoices'
#     )
    
#     purchase_order = models.ForeignKey(
#         PurchaseOrder,
#         on_delete=models.SET_NULL,
#         null=True,
#         blank=True,
#         related_name='invoices'
#     )
    
#     # Invoice Details
#     vendor_invoice_number = models.CharField(
#         max_length=100,
#         verbose_name="Vendor Invoice Number"
#     )
    
#     internal_reference = models.CharField(
#         max_length=50,
#         unique=True,
#         blank=True,
#         verbose_name="Our Reference Number"
#     )
    
#     invoice_date = models.DateField(default=timezone.now)
#     due_date = models.DateField(null=True, blank=True)
    
#     # Amounts
#     subtotal = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     discount_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     taxable_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     cgst_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     sgst_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     igst_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     total_tax = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     total_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     # TDS
#     tds_applicable = models.BooleanField(default=False)
#     tds_percentage = models.DecimalField(
#         max_digits=5,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
#     tds_amount = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     net_payable = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00'),
#         verbose_name="Net Payable Amount"
#     )
    
#     # Payment tracking
#     amount_paid = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     balance_due = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00')
#     )
    
#     # Status
#     STATUS_CHOICES = [
#         ('RECEIVED', 'Invoice Received'),
#         ('VERIFIED', 'Verified'),
#         ('PAID', 'Paid'),
#         ('PARTIALLY_PAID', 'Partially Paid'),
#         ('OVERDUE', 'Overdue'),
#     ]
#     status = models.CharField(
#         max_length=20,
#         choices=STATUS_CHOICES,
#         default='RECEIVED'
#     )
    
#     invoice_copy = models.FileField(
#         upload_to='purchases/invoices/',
#         null=True,
#         blank=True,
#         help_text="Upload vendor invoice copy"
#     )
    
"""
================================================================================
DEPRECATED CODE - MOVED TO purchase_management APP
================================================================================
Deprecated: 30-Dec-2025
Model: Expense
Reason: Moved to purchase_management app for better separation of concerns
New Location: purchase_management.models.Expense
Migration Status: Pending
Notes: Keep for reference until data migration is complete
================================================================================
"""
# #     notes = models.TextField(blank=True)
    
# #     created_by = models.ForeignKey(
# #         'core.User',
# #         on_delete=models.SET_NULL,
# #         null=True
# #     )
# #     created_at = models.DateTimeField(auto_now_add=True)
# #     updated_at = models.DateTimeField(auto_now=True)
# #     objects = TenantManager()  
# #     all_objects = models.Manager()
    
# """
# ================================================================================
# END DEPRECATED CODE
# ================================================================================
# """
#     class Meta:
#         verbose_name = "Purchase Invoice"
#         verbose_name_plural = "Purchase Invoices"
#         ordering = ['-invoice_date']
    
#     def __str__(self):
#         return f"{self.vendor_invoice_number} - {self.vendor.name}"
    
#     def save(self, *args, **kwargs):
#         """Auto-generate internal reference"""
#         if not self.internal_reference:
#             date_str = timezone.now().strftime('%y%m')
#             last_pi = PurchaseInvoice.objects.filter(
#                 tenant=self.tenant,
#                 internal_reference__startswith=f'PI-{date_str}'
#             ).order_by('-internal_reference').first()
            
#             if last_pi:
#                 last_num = int(last_pi.internal_reference.split('-')[-1])
#                 new_num = last_num + 1
#             else:
#                 new_num = 1
            
#             self.internal_reference = f'PI-{date_str}-{new_num:05d}'
        
#         # Calculate net payable
#         self.net_payable = self.total_amount - self.tds_amount
#         self.balance_due = self.net_payable - self.amount_paid
        
#         super().save(*args, **kwargs)


# # ==================== EXPENSE MODEL ====================

# class Expense(models.Model):
#     """
#     Business Expenses
#     """
    
#     tenant = models.ForeignKey(
#         'core.Tenant',
#         on_delete=models.CASCADE,
#         related_name='expenses'
#     )
    
#     EXPENSE_CATEGORY_CHOICES = [
#         ('RENT', 'Rent'),
#         ('ELECTRICITY', 'Electricity'),
#         ('WATER', 'Water'),
#         ('INTERNET', 'Internet'),
#         ('PHONE', 'Phone'),
#         ('SALARY', 'Salary'),
#         ('TRANSPORT', 'Transport'),
#         ('MAINTENANCE', 'Maintenance'),
#         ('MARKETING', 'Marketing'),
#         ('STATIONERY', 'Stationery'),
#         ('MISCELLANEOUS', 'Miscellaneous'),
#     ]
#     category = models.CharField(
#         max_length=20,
#         choices=EXPENSE_CATEGORY_CHOICES,
# #         verbose_name="Expense Category"
# #     )
    
# #     expense_date = models.DateField(default=timezone.now)
    
# #     description = models.CharField(max_length=200)
    
# #     amount = models.DecimalField(
# """
# ================================================================================
# END DEPRECATED CODE
# ================================================================================
# """
#         max_digits=10,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.00'))]
#     )
    
#     PAYMENT_MODE_CHOICES = [
#         ('CASH', 'Cash'),
#         ('BANK', 'Bank Transfer'),
#         ('UPI', 'UPI'),
#         ('CARD', 'Card'),
#         ('CHEQUE', 'Cheque'),
#     ]
#     payment_mode = models.CharField(
#         max_length=20,
#         choices=PAYMENT_MODE_CHOICES,
#         default='CASH'
#     )
    
#     reference_number = models.CharField(
#         max_length=100,
#         blank=True,
#         help_text="Transaction/Cheque reference"
#     )
    
#     receipt_copy = models.FileField(
#         upload_to='expenses/receipts/',
#         null=True,
#         blank=True,
#         help_text="Upload receipt/bill"
#     )
    
#     notes = models.TextField(blank=True)
    
#     created_by = models.ForeignKey(
#         'core.User',
#         on_delete=models.SET_NULL,
#         null=True
#     )
#     created_at = models.DateTimeField(auto_now_add=True)
#     objects = TenantManager()  # ← ADD
#     all_objects = models.Manager()
    
    
#     class Meta:
#         verbose_name = "Expense"
#         verbose_name_plural = "Expenses"
#         ordering = ['-expense_date']
    
#     def __str__(self):
#         return f"{self.get_category_display()} - ₹{self.amount} on {self.expense_date}"

    
    # ==================== PHOTO MODELS ====================

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




class CustomerProfilePhoto(models.Model):
    """Customer profile photo for identification"""
    
    customer = models.OneToOneField(
        'Customer',
        on_delete=models.CASCADE,
        related_name='profile_photo',
        verbose_name='Customer'
    )
    
    photo = models.ImageField(
        upload_to='customers/profiles/',
        verbose_name='Profile Photo'
    )
    
    uploaded_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name='Uploaded By'
    )
    
    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Customer Profile Photo'
        verbose_name_plural = 'Customer Profile Photos'
    
    def __str__(self):
        return f"Profile Photo - {self.customer.name}"


class CustomerProvidedMaterial(models.Model):
    """Track customer's own fabric/saree/materials brought for stitching"""
    
    MATERIAL_TYPE_CHOICES = [
        ('FABRIC', 'Fabric'),
        ('SAREE', 'Saree'),
        ('SUIT_PIECE', 'Suit Piece'),
        ('BLOUSE_PIECE', 'Blouse Piece'),
        ('ACCESSORY', 'Accessory'),
        ('OTHER', 'Other'),
    ]
    
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='customer_materials',
        verbose_name='Order'
    )
    
    material_type = models.CharField(
        max_length=20,
        choices=MATERIAL_TYPE_CHOICES,
        default='FABRIC',
        verbose_name='Material Type'
    )
    
    description = models.CharField(
        max_length=200,
        verbose_name='Description',
        help_text='e.g., Red silk fabric, 3 meters'
    )
    
    quantity = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='Quantity',
        help_text='e.g., 3 meters, 1 piece'
    )
    
    photo = models.ImageField(
        upload_to='orders/customer_materials/',
        verbose_name='Material Photo'
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name='Notes',
        help_text='Any special notes about the material'
    )
    
    received_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='materials_received',
        verbose_name='Received By'
    )
    
    received_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Customer Provided Material'
        verbose_name_plural = 'Customer Provided Materials'
        ordering = ['-received_at']
    
    def __str__(self):
        return f"{self.order.order_number} - {self.material_type}"



# ==================== MEASUREMENT MODELS ====================

class CustomerMeasurementProfile(models.Model):
    """
    Saved measurement profiles for repeat customers
    Allows reusing measurements for future orders
    """
    
    customer = models.ForeignKey(
        Customer,
        on_delete=models.CASCADE,
        related_name='measurement_profiles',
        verbose_name='Customer'
    )
    
    profile_name = models.CharField(
        max_length=100,
        verbose_name='Profile Name',
        help_text='e.g., Standard Blouse, Party Wear Lehenga'
    )
    
    garment_type = models.ForeignKey(
        'masters.ItemCategory',
        on_delete=models.PROTECT,
        verbose_name='Garment Type'
    )
    
    # Standard Measurements (common fields)
    chest = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Chest'
    )
    
    waist = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Waist'
    )
    
    hip = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Hip'
    )
    
    shoulder = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Shoulder'
    )
    
    sleeve_length = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Sleeve Length'
    )
    
    garment_length = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Garment Length'
    )
    
    neck = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Neck'
    )
    
    arm_hole = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Arm Hole'
    )
    
    # Additional measurements (JSON for flexibility)
    additional_measurements = models.JSONField(
        default=dict,
        blank=True,
        verbose_name='Additional Measurements',
        help_text='Store any extra measurements as key-value pairs'
    )
    
    # Notes
    fit_notes = models.TextField(
        blank=True,
        verbose_name='Fit Notes',
        help_text='e.g., Customer prefers loose fit, broad shoulders'
    )
    
    # Meta
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active'
    )
    
    created_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='measurement_profiles_created',
        verbose_name='Created By'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Customer Measurement Profile'
        verbose_name_plural = 'Customer Measurement Profiles'
        ordering = ['-created_at']
        unique_together = ['customer', 'profile_name']
    
    def __str__(self):
        return f"{self.customer.name} - {self.profile_name}"


class OrderMeasurement(models.Model):
    """
    Measurements specific to an order
    Can be copied from profile or taken fresh
    """
    
    order = models.OneToOneField(
        Order,
        on_delete=models.CASCADE,
        related_name='measurements',
        verbose_name='Order'
    )
    
    # Link to profile if reused
    copied_from_profile = models.ForeignKey(
        CustomerMeasurementProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name='Copied From Profile',
        help_text='If measurements were copied from saved profile'
    )
    
    # Standard Measurements
    chest = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Chest'
    )
    
    waist = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Waist'
    )
    
    hip = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Hip'
    )
    
    shoulder = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Shoulder'
    )
    
    sleeve_length = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Sleeve Length'
    )
    
    garment_length = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Garment Length'
    )
    
    neck = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Neck'
    )
    
    arm_hole = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Arm Hole'
    )
    
    # Additional measurements (JSON for flexibility)
    additional_measurements = models.JSONField(
        default=dict,
        blank=True,
        verbose_name='Additional Measurements'
    )
    
    # Notes
    measurement_notes = models.TextField(
        blank=True,
        verbose_name='Measurement Notes'
    )
    
    # Meta
    measured_by = models.ForeignKey(
        'core.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='measurements_taken',
        verbose_name='Measured By'
    )
    
    measured_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Order Measurement'
        verbose_name_plural = 'Order Measurements'
    
    def __str__(self):
        return f"Measurements for {self.order.order_number}"
    
    def copy_from_profile(self, profile):
        """Copy measurements from a saved profile"""
        self.copied_from_profile = profile
        self.chest = profile.chest
        self.waist = profile.waist
        self.hip = profile.hip
        self.shoulder = profile.shoulder
        self.sleeve_length = profile.sleeve_length
        self.garment_length = profile.garment_length
        self.neck = profile.neck
        self.arm_hole = profile.arm_hole
        self.additional_measurements = profile.additional_measurements
        self.measurement_notes = profile.fit_notes
        self.save()
#this is for creating non inventroy items 
class Item(models.Model):
    ITEM_TYPES = [
        ('PRODUCT', 'Product'),
        ('SERVICE', 'Service'),
    ]

    tenant = models.ForeignKey('core.Tenant', on_delete=models.CASCADE)
    item_type = models.CharField(max_length=10, choices=ITEM_TYPES)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    #unit = models.CharField(max_length=50) # e.g., 'Meters' or 'Per Item'
    unit = models.ForeignKey(
        ItemUnit,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='items'
    )
    hsn_sac_code = models.CharField(max_length=20, blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    tax_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    objects = TenantManager() # Enables automatic tenant filtering

    class Meta:
        unique_together = ('tenant', 'name', 'item_type')
        verbose_name = 'Master Item'
        ordering = ['name']  

    def __str__(self):
        return f"{self.name} ({self.item_type})"