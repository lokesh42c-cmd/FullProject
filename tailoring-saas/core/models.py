"""
Core models for multi-tenant SaaS application.
UPDATED: New role structure with WORKSHOP_MANAGER, SPECIALIST, ACCOUNTANT, KIOSK
"""
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.utils import timezone
from django.core.validators import RegexValidator
from datetime import timedelta
from slugify import slugify
from decimal import Decimal 
from django.core.validators import MinValueValidator


class TenantManager(models.Manager):
    """Manager for Tenant model"""
    
    def get_active(self):
        """Get all active tenants"""
        return self.filter(is_active=True)


class Tenant(models.Model):
    """
    Tenant (Shop) Model - Each tailoring shop is a tenant
    Complete data isolation per tenant
    """
    # Basic Information
    name = models.CharField(max_length=200, help_text="Shop name")
    slug = models.SlugField(max_length=200, unique=True, help_text="URL-friendly shop name")
    email = models.EmailField(help_text="Shop contact email")
    
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed."
    )
    phone_number = models.CharField(validators=[phone_regex], max_length=17, help_text="Shop contact phone")
    
    # Address
    address = models.TextField(blank=True, null=True)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    pincode = models.CharField(max_length=10, blank=True, null=True)
    
    # Business Details (for invoices)
    gstin = models.CharField(max_length=15, blank=True, null=True, help_text="GST Identification Number")
    pan_number = models.CharField(max_length=10, blank=True, null=True, help_text="PAN Number")
    logo = models.ImageField(upload_to='tenant_logos/', blank=True, null=True)
    # ==================== NEW FIELD ====================
    custom_measurement_labels = models.JSONField(
        default=dict,
        blank=True,
        verbose_name='Custom Measurement Labels',
        help_text='Labels for custom measurement fields (custom_1 to custom_10)'
    )
# ==================== END NEW FIELD ====================
    # Bank Details
    bank_name = models.CharField(max_length=100, blank=True, null=True)
    bank_account_number = models.CharField(max_length=50, blank=True, null=True)
    bank_ifsc_code = models.CharField(max_length=11, blank=True, null=True)
    bank_branch = models.CharField(max_length=100, blank=True, null=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = TenantManager()
    
    class Meta:
        db_table = 'tenants'
        ordering = ['-created_at']
        verbose_name = 'Tenant (Shop)'
        verbose_name_plural = 'Tenants (Shops)'
    
    @property
    def active_subscription(self):
        """Get the active subscription for this tenant"""
        try:
            return self.subscriptions.filter(
                status__in=['ACTIVE', 'TRIAL']
            ).select_related('plan').first()
        except Exception:
            return None
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        """Auto-generate slug from name if not provided"""
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)


class UserManager(BaseUserManager):
    """Manager for custom User model"""
    
    def create_user(self, email, name, password=None, **extra_fields):
        """Create and return a regular user"""
        if not email:
            raise ValueError('Users must have an email address')
        if not name:
            raise ValueError('Users must have a name')
        
        email = self.normalize_email(email)
        user = self.model(email=email, name=name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, name, password=None, **extra_fields):
        """Create and return a superuser"""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        
        # REMOVED: role setting - superuser doesn't need role
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True')
        
        return self.create_user(email, name, password, **extra_fields)

class User(AbstractBaseUser, PermissionsMixin):
    """
    Custom User Model with multi-tenant support
    Each user belongs to one tenant (shop)
    
    NOTE: Role is now defined in Employee model only
    This model handles authentication (login) only
    """
    
    # Identity
    email = models.EmailField(unique=True, help_text="User email (used for login)")
    name = models.CharField(max_length=200, help_text="Full name")
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed."
    )
    phone_number = models.CharField(validators=[phone_regex], max_length=17, blank=True, null=True)
    
    # Tenant Relationship (nullable for superuser)
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name='users',
        null=True,
        blank=True,
        help_text="Shop this user belongs to"
    )
    
    # REMOVED: role field - now in Employee model only
    
    # Status
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False, help_text="Can access Django admin")
    is_superuser = models.BooleanField(default=False, help_text="Has all permissions")
    
    # Timestamps
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)
    
    objects = UserManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']
    
    class Meta:
        db_table = 'users'
        ordering = ['-date_joined']
        verbose_name = 'User'
        verbose_name_plural = 'Users'
    
    def __str__(self):
        return f"{self.name} ({self.email})"
    
    def get_full_name(self):
        return self.name
    
    def get_short_name(self):
        return self.name.split()[0] if self.name else self.email
    
    # ==================== ROLE HELPER PROPERTIES ====================
    
    @property
    def employee(self):
        """Get linked employee profile"""
        try:
            return self.employee_profile
        except:
            return None
    
    @property
    def role(self):
        """Get role from employee profile"""
        if self.employee:
            return self.employee.role
        return None
    
    @property
    def is_owner(self):
        """Check if user is owner"""
        return self.employee and self.employee.role == 'OWNER'
    
    @property
    def is_management(self):
        """Check if user is in management"""
        if not self.employee:
            return False
        return self.employee.role in ['OWNER', 'WORKSHOP_MANAGER', 'HR_MANAGER']
    
    @property
    def can_manage_orders(self):
        """Check if user can manage orders"""
        if not self.employee:
            return False
        return self.employee.can_manage_orders
    
    @property
    def can_manage_inventory(self):
        """Check if user can manage inventory"""
        if not self.employee:
            return False
        return self.employee.can_manage_inventory
    
    @property
    def can_manage_employees(self):
        """Check if user can manage employees"""
        if not self.employee:
            return False
        return self.employee.can_manage_employees
    
    @property
    def can_assign_tasks(self):
        """Check if user can assign tasks"""
        if not self.employee:
            return False
        return self.employee.can_assign_tasks
'''
class SubscriptionPlan(models.Model):
    """
    Subscription plans for the SaaS platform
    Defines pricing, limits, and features for each tier
    """
    PLAN_TYPE_CHOICES = [
        ('FREE', 'Free Trial'),
        ('STARTER', 'Starter'),
        ('PROFESSIONAL', 'Professional'),
        ('ENTERPRISE', 'Enterprise'),
    ]
    
    # Identity
    name = models.CharField(max_length=100, help_text="Plan display name")
    plan_type = models.CharField(
        max_length=20,
        choices=PLAN_TYPE_CHOICES,
        unique=True,
        help_text="Unique plan identifier"
    )
    description = models.TextField(blank=True, null=True)
    
    # Pricing
    price_monthly = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Monthly price in INR"
    )
    price_yearly = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Yearly price in INR (usually discounted)"
    )
    
    # Resource Limits (null means unlimited)
    max_orders_per_month = models.IntegerField(
        null=True,
        blank=True,
        help_text="Maximum orders per month (null = unlimited)"
    )
    max_customers = models.IntegerField(
        null=True,
        blank=True,
        help_text="Maximum total customers (null = unlimited)"
    )
    max_staff_users = models.IntegerField(
        null=True,
        blank=True,
        help_text="Maximum staff users (null = unlimited)"
    )
    max_inventory_items = models.IntegerField(
        null=True,
        blank=True,
        help_text="Maximum inventory items (null = unlimited)"
    )
    
    # Feature Flags
    has_inventory = models.BooleanField(default=False, help_text="Inventory management feature")
    has_advanced_reports = models.BooleanField(default=False, help_text="Advanced reporting feature")
    has_api_access = models.BooleanField(default=False, help_text="API access for integrations")
    has_custom_fields = models.BooleanField(default=False, help_text="Custom field builder")
    has_whatsapp_integration = models.BooleanField(default=False, help_text="WhatsApp notifications")
    has_data_export = models.BooleanField(default=False, help_text="Export data to Excel/CSV")
    has_multi_location = models.BooleanField(default=False, help_text="Multi-location support")
    
    # Visibility
    is_active = models.BooleanField(default=True)
    is_visible = models.BooleanField(default=True, help_text="Show in pricing page")
    display_order = models.IntegerField(default=0, help_text="Order in pricing page")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'subscription_plans'
        ordering = ['display_order', 'price_monthly']
        verbose_name = 'Subscription Plan'
        verbose_name_plural = 'Subscription Plans'
    
    def __str__(self):
        return f"{self.name} (₹{self.price_monthly}/month)"


class TenantSubscription(models.Model):
    """
    Tenant's active subscription
    Tracks usage, limits, and subscription status
    """
    STATUS_CHOICES = [
        ('TRIAL', 'Trial Period'),
        ('ACTIVE', 'Active'),
        ('PAST_DUE', 'Past Due'),
        ('CANCELLED', 'Cancelled'),
        ('EXPIRED', 'Expired'),
    ]
    
    BILLING_CYCLE_CHOICES = [
        ('MONTHLY', 'Monthly'),
        ('YEARLY', 'Yearly'),
    ]
    
    # Relationships
    tenant = models.OneToOneField(
        Tenant,
        on_delete=models.CASCADE,
        related_name='subscription',
        help_text="Shop this subscription belongs to"
    )
    plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.PROTECT,
        related_name='subscriptions',
        help_text="Current subscription plan"
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='TRIAL',
        help_text="Current subscription status"
    )
    billing_cycle = models.CharField(
        max_length=20,
        choices=BILLING_CYCLE_CHOICES,
        default='MONTHLY'
    )
    
    # Usage Tracking (resets monthly)
    current_month_orders = models.IntegerField(default=0, help_text="Orders created this month")
    total_customers = models.IntegerField(default=0, help_text="Total customers")
    total_staff_users = models.IntegerField(default=1, help_text="Total staff users")
    total_inventory_items = models.IntegerField(default=0, help_text="Total inventory items")
    
    # Dates
    trial_ends_at = models.DateTimeField(null=True, blank=True, help_text="Trial expiration date")
    current_period_start = models.DateTimeField(help_text="Current billing period start")
    current_period_end = models.DateTimeField(help_text="Current billing period end")
    cancelled_at = models.DateTimeField(null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'tenant_subscriptions'
        ordering = ['-created_at']
        verbose_name = 'Tenant Subscription'
        verbose_name_plural = 'Tenant Subscriptions'
    
    def __str__(self):
        return f"{self.tenant.name} - {self.plan.name} ({self.status})"
    
    def is_active(self):
        """Check if subscription is currently active"""
        now = timezone.now()
        return (
            self.status in ['TRIAL', 'ACTIVE'] and
            self.current_period_end > now
        )
    
    def is_trial(self):
        """Check if in trial period"""
        now = timezone.now()
        return (
            self.status == 'TRIAL' and
            self.trial_ends_at and
            self.trial_ends_at > now
        )
    
    def can_create_order(self):
        """Check if tenant can create more orders this month"""
        if not self.plan.max_orders_per_month:
            return True  # Unlimited
        return self.current_month_orders < self.plan.max_orders_per_month
    
    def can_add_customer(self):
        """Check if tenant can add more customers"""
        if not self.plan.max_customers:
            return True  # Unlimited
        return self.total_customers < self.plan.max_customers
    
    def can_add_staff(self):
        """Check if tenant can add more staff users"""
        if not self.plan.max_staff_users:
            return True  # Unlimited
        return self.total_staff_users < self.plan.max_staff_users
    
    def can_add_inventory_item(self):
        """Check if tenant can add more inventory items"""
        if not self.plan.max_inventory_items:
            return True  # Unlimited
        return self.total_inventory_items < self.plan.max_inventory_items
    
    def get_usage_percentage(self, resource_type):
        """Get usage percentage for a resource"""
        if resource_type == 'orders':
            if not self.plan.max_orders_per_month:
                return 0
            return (self.current_month_orders / self.plan.max_orders_per_month) * 100
        elif resource_type == 'customers':
            if not self.plan.max_customers:
                return 0
            return (self.total_customers / self.plan.max_customers) * 100
        elif resource_type == 'staff':
            if not self.plan.max_staff_users:
                return 0
            return (self.total_staff_users / self.plan.max_staff_users) * 100
        elif resource_type == 'inventory':
            if not self.plan.max_inventory_items:
                return 0
            return (self.total_inventory_items / self.plan.max_inventory_items) * 100
        return 0

'''
# core/models.py

class SubscriptionPlan(models.Model):
    """Subscription Plans with Feature Limits"""
    
    TIER_CHOICES = [
        ('FREE_TRIAL', 'Free Trial'),
        ('STARTER', 'Starter'),
        ('PRO', 'Professional'),
        ('BUSINESS', 'Business'),
        ('ENTERPRISE', 'Enterprise'),
    ]
    
    tier = models.CharField(
        max_length=20,
        choices=TIER_CHOICES,
        unique=True,
        verbose_name="Plan Tier"
    )
    
    name = models.CharField(max_length=100, verbose_name="Plan Name")
    description = models.TextField(blank=True)
    
    # Pricing
    price_monthly = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Monthly Price (INR)"
    )
    
    price_yearly = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="Yearly Price (INR)",
        help_text="Annual pricing with discount"
    )
    
    # ==================== LIMITS ====================
    
    # Orders
    max_orders_per_month = models.IntegerField(
        default=0,
        verbose_name="Max Orders/Month",
        help_text="0 = Unlimited"
    )
    
    # Customers
    max_customers = models.IntegerField(
        default=0,
        verbose_name="Max Customers",
        help_text="0 = Unlimited"
    )
    
    # Employees
    max_employees = models.IntegerField(
        default=0,
        verbose_name="Max Employees",
        help_text="0 = Unlimited"
    )
    
    # Users (login accounts)
    max_users = models.IntegerField(
        default=1,
        verbose_name="Max User Accounts"
    )
    
    # Inventory
    max_inventory_items = models.IntegerField(
        default=0,
        verbose_name="Max Inventory Items",
        help_text="0 = Unlimited"
    )
    
    # Vendors
    max_vendors = models.IntegerField(
        default=0,
        verbose_name="Max Vendors",
        help_text="0 = Unlimited"
    )
    
    # Customer photos per order
    max_photos_per_order = models.IntegerField(
        default=3,
        verbose_name="Max Photos Per Order"
    )
    
    # ==================== FEATURE FLAGS ====================
    
    # Customer Features
    allow_b2b_customers = models.BooleanField(
        default=False,
        verbose_name="Allow B2B Customers"
    )
    
    allow_measurement_profiles = models.BooleanField(
        default=False,
        verbose_name="Allow Measurement Profiles"
    )
    
    # Invoicing Features
    allow_gst_invoicing = models.BooleanField(
        default=False,
        verbose_name="Allow GST Invoicing"
    )
    
    allow_item_discount = models.BooleanField(
        default=False,
        verbose_name="Allow Item-Level Discount"
    )
    
    allow_invoice_customization = models.CharField(
        max_length=20,
        choices=[
            ('NONE', 'No Customization'),
            ('BASIC', 'Basic (Logo + Colors)'),
            ('ADVANCED', 'Advanced (Full Template)'),
        ],
        default='NONE',
        verbose_name="Invoice Customization"
    )
    
    # Inventory Features
    allow_inventory = models.BooleanField(
        default=False,
        verbose_name="Allow Inventory Management"
    )
    
    allow_barcode_sku = models.BooleanField(
        default=False,
        verbose_name="Allow Barcode/SKU"
    )
    
    allow_purchase_orders = models.BooleanField(
        default=False,
        verbose_name="Allow Purchase Orders"
    )
    
    # Employee Features
    allow_employee_management = models.BooleanField(
        default=False,
        verbose_name="Allow Employee Management"
    )
    
    allow_attendance = models.CharField(
        max_length=20,
        choices=[
            ('NONE', 'No Attendance'),
            ('MANUAL', 'Manual Entry'),
            ('QR_SCAN', 'QR Code Scanning'),
        ],
        default='NONE',
        verbose_name="Attendance System"
    )
    
    allow_leave_management = models.BooleanField(
        default=False,
        verbose_name="Allow Leave Management"
    )
    
    allow_payroll = models.BooleanField(
        default=False,
        verbose_name="Allow Payroll"
    )
    
    # Workflow Features
    allow_workflow = models.BooleanField(
        default=False,
        verbose_name="Allow Workflow Tracking"
    )
    
    max_workflow_stages = models.IntegerField(
        default=0,
        verbose_name="Max Workflow Stages",
        help_text="0 = Feature disabled"
    )
    
    allow_task_assignment = models.BooleanField(
        default=False,
        verbose_name="Allow Task Assignment"
    )
    
    allow_qa_system = models.BooleanField(
        default=False,
        verbose_name="Allow QA System"
    )
    
    allow_trial_feedback = models.BooleanField(
        default=False,
        verbose_name="Allow Trial Feedback"
    )
    
    # QR Features
    allow_order_qr = models.BooleanField(
        default=True,
        verbose_name="Allow Order QR Codes"
    )
    
    allow_employee_qr = models.BooleanField(
        default=False,
        verbose_name="Allow Employee QR Codes"
    )
    
    # Reports
    report_types = models.JSONField(
        default=list,
        verbose_name="Allowed Report Types",
        help_text="List of report slugs: ['sales', 'inventory', 'employee']"
    )
    
    allow_data_export = models.BooleanField(
        default=False,
        verbose_name="Allow Data Export (Excel/PDF)"
    )
    
    # API & Integrations
    allow_api_access = models.BooleanField(
        default=False,
        verbose_name="Allow API Access"
    )
    
    # Support
    support_level = models.CharField(
        max_length=20,
        choices=[
            ('EMAIL', 'Email Only'),
            ('PRIORITY_EMAIL', 'Priority Email'),
            ('PHONE', 'Phone + Email'),
            ('DEDICATED', 'Dedicated Support'),
        ],
        default='EMAIL',
        verbose_name="Support Level"
    )
    
    # Trial
    trial_days = models.IntegerField(
        default=0,
        verbose_name="Trial Period (Days)"
    )
    
    # Status
    is_active = models.BooleanField(default=True)
    is_popular = models.BooleanField(
        default=False,
        verbose_name="Mark as Popular"
    )
    
    display_order = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Subscription Plan"
        verbose_name_plural = "Subscription Plans"
        ordering = ['display_order', 'price_monthly']
    
    def __str__(self):
        return f"{self.name} - ₹{self.price_monthly}/month"
    
    def get_feature_list(self):
        """Return list of enabled features"""
        features = []
        
        # Orders
        if self.max_orders_per_month > 0:
            features.append(f"{self.max_orders_per_month} orders/month")
        else:
            features.append("Unlimited orders")
        
        # Employees
        if self.allow_employee_management:
            if self.max_employees > 0:
                features.append(f"Up to {self.max_employees} employees")
            else:
                features.append("Unlimited employees")
        
        # Workflow
        if self.allow_workflow:
            features.append("Workshop workflow tracking")
        
        # GST
        if self.allow_gst_invoicing:
            features.append("GST-compliant invoicing")
        
        # Inventory
        if self.allow_inventory:
            features.append("Inventory management")
        
        return features

class TenantSubscription(models.Model):
    """Tenant's active subscription"""
    
    tenant = models.OneToOneField(
        Tenant,
        on_delete=models.CASCADE,
        related_name='subscription'
    )
    
    plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.PROTECT,
        related_name='subscriptions'
    )
    
    # Billing
    BILLING_CYCLE_CHOICES = [
        ('MONTHLY', 'Monthly'),
        ('YEARLY', 'Yearly'),
    ]
    billing_cycle = models.CharField(
        max_length=10,
        choices=BILLING_CYCLE_CHOICES,
        default='MONTHLY'
    )
    
    # Dates
    start_date = models.DateField(default=timezone.now)
    end_date = models.DateField(null=True, blank=True)
    trial_end_date = models.DateField(null=True, blank=True)
    
    # Status
    STATUS_CHOICES = [
        ('TRIAL', 'Trial Period'),
        ('ACTIVE', 'Active'),
        ('EXPIRED', 'Expired'),
        ('CANCELLED', 'Cancelled'),
        ('SUSPENDED', 'Suspended'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='TRIAL'
    )
    orders_created = models.IntegerField(
        default=0,
        verbose_name="Orders Created This Period",
        help_text="Number of orders created in current billing period"
    )
    
    # Auto-renewal
    auto_renew = models.BooleanField(default=True)
    
    # Usage tracking
    orders_this_month = models.IntegerField(default=0)
    last_reset_date = models.DateField(default=timezone.now)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Tenant Subscription"
        verbose_name_plural = "Tenant Subscriptions"
    
    def __str__(self):
        return f"{self.tenant.name} - {self.plan.name}"
    
    def is_trial(self):
        """Check if in trial period"""
        if self.status == 'TRIAL' and self.trial_end_date:
            return timezone.now().date() <= self.trial_end_date
        return False
    
    def is_active(self):
        """Check if subscription is active"""
        if self.status == 'TRIAL':
            return self.is_trial()
        
        if self.status == 'ACTIVE':
            if self.end_date:
                return timezone.now().date() <= self.end_date
            return True
        
        return False
    
    def days_remaining(self):
        """Days remaining in current subscription"""
        if self.status == 'TRIAL' and self.trial_end_date:
            delta = self.trial_end_date - timezone.now().date()
            return max(0, delta.days)
        
        if self.end_date:
            delta = self.end_date - timezone.now().date()
            return max(0, delta.days)
        
        return 0
    
    def reset_monthly_limits(self):
        """Reset monthly usage counters"""
        today = timezone.now().date()
        
        # Check if month has changed
        if self.last_reset_date.month != today.month:
            self.orders_this_month = 0
            self.last_reset_date = today
            self.save()
    
    def can_create_order(self):
        """Check if tenant can create more orders this month"""
        self.reset_monthly_limits()
        
        max_orders = self.plan.max_orders_per_month
        
        # 0 = unlimited
        if max_orders == 0:
            return True, None
        
        if self.orders_this_month >= max_orders:
            return False, f"Monthly limit of {max_orders} orders reached"
        
        return True, None
    
    def increment_order_count(self):
        """Increment order count for this month"""
        self.orders_this_month += 1
        self.save()

