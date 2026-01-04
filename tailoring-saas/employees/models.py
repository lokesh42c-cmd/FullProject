from django.db import models
from django.core.validators import MinValueValidator
from django.utils import timezone
from decimal import Decimal
from datetime import datetime, time, timedelta
from core.managers import TenantManager


class Department(models.Model):
    """Departments in the shop (Cutting, Embroidery, Tailoring, etc.)"""
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='departments',
        verbose_name='Tenant'
    )
    
    name = models.CharField(
        max_length=100,
        verbose_name='Department Name',
        help_text='e.g., Cutting, Embroidery, Tailoring, Store'
    )
    
    description = models.TextField(
        blank=True,
        verbose_name='Description'
    )
    
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Department'
        verbose_name_plural = 'Departments'
        ordering = ['name']
        unique_together = ['tenant', 'name']
    
    def __str__(self):
        return self.name

class Employee(models.Model):
    """Employee/Worker model with comprehensive details"""
    
    ROLE_CHOICES = [
    # Management (Full Access)
    ('OWNER', 'Owner'),
    ('WORKSHOP_MANAGER', 'Workshop Manager'),
    ('HR_MANAGER', 'HR Manager'),
    
    # Creative & Production Management
    ('DESIGNER', 'Designer'),
    ('DEPARTMENT_MASTER', 'Department Master'),
    
    # Production Workers
    ('TAILOR', 'Tailor'),
    ('EMBROIDERY_WORKER', 'Embroidery Worker'),
    ('CUTTING_WORKER', 'Cutting Worker'),
    ('FINISHING_WORKER', 'Finishing Worker'),
    ('HELPER', 'Helper/Assistant'),
    
    # Support Staff
    ('STORE_MANAGER', 'Store Manager'),
    ('ACCOUNTANT', 'Accountant'),
    ('RECEPTIONIST', 'Receptionist'),
    ('DATA_ENTRY', 'Data Entry Clerk'),
]
    
    PAYMENT_TYPE_CHOICES = [
        ('MONTHLY', 'Fixed Monthly Salary'),
        ('WEEKLY', 'Weekly Payment'),
        ('PIECE_RATE', 'Per Piece Rate'),
        ('HOURLY', 'Hourly Rate'),
        ('DAILY', 'Daily Wage'),
        ('MIXED', 'Salary + Piece Rate Bonus'),
    ]
    
    BLOOD_GROUP_CHOICES = [
        ('A+', 'A+'),
        ('A-', 'A-'),
        ('B+', 'B+'),
        ('B-', 'B-'),
        ('O+', 'O+'),
        ('O-', 'O-'),
        ('AB+', 'AB+'),
        ('AB-', 'AB-'),
    ]
    
    GENDER_CHOICES = [
        ('MALE', 'Male'),
        ('FEMALE', 'Female'),
        ('OTHER', 'Other'),
    ]
    
    # Basic Info
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='employees',
        verbose_name='Tenant'
    )
    
    user = models.OneToOneField(
        'core.User',
        on_delete=models.CASCADE,
        related_name='employee_profile',
        verbose_name='User Account'
    )
    
    employee_code = models.CharField(
        max_length=20,
        unique=True,
        verbose_name='Employee Code',
        help_text='Enter manually: EMP-001, EMP-002, etc.'
    )
    
    # Personal Details
    date_of_birth = models.DateField(
        null=True,
        blank=True,
        verbose_name='Date of Birth'
    )
    
    gender = models.CharField(
        max_length=10,
        choices=GENDER_CHOICES,
        blank=True,
        verbose_name='Gender'
    )
    
    blood_group = models.CharField(
        max_length=5,
        choices=BLOOD_GROUP_CHOICES,
        blank=True,
        verbose_name='Blood Group'
    )
    
    # Role & Department
    role = models.CharField(
        max_length=30,
        choices=ROLE_CHOICES,
        default='WORKER',
        verbose_name='Role'
    )
    
    department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='employees',
        verbose_name='Department'
    )
    
    specialization = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Specialization',
        help_text='e.g., Tailor, Embroidery Worker, Cutting Master'
    )
    
    # Hierarchy
    reports_to = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='subordinates',
        verbose_name='Reports To'
    )
    
    # Employment Details
    date_joined = models.DateField(
        default=timezone.now,
        verbose_name='Date Joined'
    )
    
    date_left = models.DateField(
        null=True,
        blank=True,
        verbose_name='Date Left'
    )
    
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active'
    )
    
    # Payment Configuration
    payment_type = models.CharField(
        max_length=20,
        choices=PAYMENT_TYPE_CHOICES,
        default='MONTHLY',
        verbose_name='Payment Type'
    )
    
    monthly_salary = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Monthly Salary (₹)',
        help_text='For monthly/mixed payment types'
    )
    
    hourly_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Hourly Rate (₹/hour)',
        help_text='Per hour rate'
    )
    
    weekly_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Weekly Rate (₹)'
    )
    
    daily_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Daily Rate (₹)'
    )
    
    # Government IDs
    aadhar_number = models.CharField(
        max_length=12,
        blank=True,
        verbose_name='Aadhar Number',
        help_text='12-digit Aadhar number'
    )
    
    pan_number = models.CharField(
        max_length=10,
        blank=True,
        verbose_name='PAN Number',
        help_text='10-character PAN'
    )
    
    # PF & ESI Details
    uan_number = models.CharField(
        max_length=12,
        blank=True,
        verbose_name='UAN Number',
        help_text='Universal Account Number for PF'
    )
    
    pf_number = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='PF Account Number'
    )
    
    esi_number = models.CharField(
        max_length=17,
        blank=True,
        verbose_name='ESI Number',
        help_text='Employee State Insurance Number'
    )
    
    # Bank Details
    bank_account_name = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Account Holder Name'
    )
    
    bank_account_number = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='Account Number'
    )
    
    bank_name = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Bank Name'
    )
    
    bank_branch = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Branch Name'
    )
    
    bank_ifsc = models.CharField(
        max_length=11,
        blank=True,
        verbose_name='IFSC Code'
    )
    
    upi_id = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='UPI ID'
    )
    
    # Nominee Details
    nominee_name = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Nominee Name'
    )
    
    nominee_relationship = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Nominee Relationship',
        help_text='e.g., Spouse, Father, Mother, Child'
    )
    
    nominee_phone = models.CharField(
        max_length=15,
        blank=True,
        verbose_name='Nominee Phone Number'
    )
    
    nominee_aadhar = models.CharField(
        max_length=12,
        blank=True,
        verbose_name='Nominee Aadhar Number'
    )
    
    # Contact Info
    phone_number = models.CharField(
        max_length=15,
        blank=True,
        verbose_name='Phone Number'
    )
    
    alternate_phone = models.CharField(
        max_length=15,
        blank=True,
        verbose_name='Alternate Phone Number'
    )
    
    emergency_contact_name = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Emergency Contact Name'
    )
    
    emergency_contact_phone = models.CharField(
        max_length=15,
        blank=True,
        verbose_name='Emergency Contact Phone'
    )
    
    emergency_contact_relationship = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Emergency Contact Relationship'
    )
    
    # Address
    current_address = models.TextField(
        blank=True,
        verbose_name='Current Address'
    )
    
    permanent_address = models.TextField(
        blank=True,
        verbose_name='Permanent Address'
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
        verbose_name='PIN Code'
    )
    
    # Workshop PIN (for tablet login)
    workshop_pin = models.CharField(
        max_length=4,
        blank=True,
        verbose_name='Workshop PIN',
        help_text='4-digit PIN for workshop tablet (Masters only)'
    )
    
    # Photos & Documents
    photo = models.ImageField(
        upload_to='employees/photos/',
        null=True,
        blank=True,
        verbose_name='Photo'
    )
    
    qr_code = models.ImageField(
        upload_to='employees/qr_codes/',
        null=True,
        blank=True,
        editable=False,
        verbose_name='Employee QR Code'
    )
    
    aadhar_card_copy = models.FileField(
        upload_to='employees/documents/aadhar/',
        null=True,
        blank=True,
        verbose_name='Aadhar Card Copy'
    )
    
    pan_card_copy = models.FileField(
        upload_to='employees/documents/pan/',
        null=True,
        blank=True,
        verbose_name='PAN Card Copy'
    )
    
    # Additional Info
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    objects = TenantManager()
    all_objects = models.Manager()

    # ==================== ADD THESE METHODS HERE ====================
    
    @property
    def is_management(self):
        """Check if employee is in management"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER', 'HR_MANAGER']
    
    @property
    def can_manage_all_departments(self):
        """Full workshop management access"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER']
    
    @property
    def can_manage_department(self):
        """Can manage one department"""
        return self.role == 'DEPARTMENT_MASTER'
    
    @property
    def can_assign_tasks(self):
        """Can assign work to others"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER', 'DEPARTMENT_MASTER']
    
    @property
    def can_manage_employees(self):
        """Can manage employee records"""
        return self.role in ['OWNER', 'HR_MANAGER']
    
    @property
    def can_manage_inventory(self):
        """Can manage stock"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER', 'STORE_MANAGER']
    
    @property
    def can_manage_orders(self):
        """Can create/edit orders"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER', 'DESIGNER', 'RECEPTIONIST']
    
    @property
    def can_manage_payments(self):
        """Can handle payments"""
        return self.role in ['OWNER', 'ACCOUNTANT', 'RECEPTIONIST']
    
    @property
    def is_production_worker(self):
        """Is a production worker"""
        return self.role in ['TAILOR', 'EMBROIDERY_WORKER', 'CUTTING_WORKER', 'FINISHING_WORKER', 'HELPER']
    
    @property
    def can_execute_tasks(self):
        """Can work on tasks"""
        return self.is_production_worker
    
    @property
    def needs_workshop_pin(self):
        """Needs PIN for workshop tablet"""
        return self.role in ['DEPARTMENT_MASTER', 'WORKSHOP_MANAGER']
    
    @property
    def can_access_admin(self):
        """Can access Django admin panel"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER', 'HR_MANAGER']
    
    # ==================== END OF NEW METHODS ====================
    
    class Meta:
        verbose_name = 'Employee'
        verbose_name_plural = 'Employees'
        ordering = ['employee_code']
        indexes = [
            models.Index(fields=['tenant', 'is_active']),
            models.Index(fields=['role']),
            models.Index(fields=['department']),
            models.Index(fields=['employee_code']),
        ]
    
    def __str__(self):
        return f"{self.employee_code} - {self.user.get_full_name()}"
    
    def save(self, *args, **kwargs):
        # Generate QR code if doesn't exist
        if not self.qr_code:
            self.generate_qr_code()
        super().save(*args, **kwargs)
    
    def generate_qr_code(self):
        """Generate QR code for employee"""
        import qrcode
        from io import BytesIO
        from django.core.files import File
        
        # QR data: employee_code + tenant_id
        qr_data = f"EMP:{self.employee_code}:TENANT:{self.tenant.id}"
        
        # Generate QR code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save to BytesIO
        buffer = BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        
        # Save to model
        file_name = f'employee_{self.employee_code}_qr.png'
        self.qr_code.save(file_name, File(buffer), save=False)
    
    @property
    def age(self):
        """Calculate age from date of birth"""
        if self.date_of_birth:
            from datetime import date
            today = date.today()
            return today.year - self.date_of_birth.year - (
                (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
            )
        return None
    
    @property
    def is_department_master(self):
        """Check if employee is a department master"""
        return self.role == 'DEPARTMENT_MASTER'
    
    @property
    def is_management(self):
        """Check if employee is in management"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER', 'HR_MANAGER']
    
    @property
    def can_assign_work(self):
        """Check if employee can assign work to others"""
        return self.role in ['OWNER', 'WORKSHOP_MANAGER', 'DESIGNER', 'DEPARTMENT_MASTER']
    
    @property
    def has_workshop_access(self):
        """Check if employee can login to workshop tablet"""
        return bool(self.workshop_pin) and self.is_department_master

class PieceRateItem(models.Model):
    """Piece rate configuration per item type for employees"""
    
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='piece_rates',
        verbose_name='Employee'
    )
    
    item_category = models.ForeignKey(
        'masters.ItemCategory',
        on_delete=models.CASCADE,
        verbose_name='Item Category'
    )
    
    rate_per_item = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Rate per Item',
        help_text='Amount paid for completing one item'
    )
    
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Piece Rate'
        verbose_name_plural = 'Piece Rates'
        unique_together = ['employee', 'item_category']
    
    def __str__(self):
        return f"{self.employee.employee_code} - {self.item_category.name}: ₹{self.rate_per_item}"


class ShopSettings(models.Model):
    """Shop timing and attendance configuration"""
    
    tenant = models.OneToOneField(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='shop_settings',
        verbose_name='Tenant'
    )
    
    # Shop Timings
    opening_time = models.TimeField(
        default=time(9, 0),
        verbose_name='Opening Time'
    )
    
    closing_time = models.TimeField(
        default=time(19, 0),  # 7 PM
        verbose_name='Closing Time'
    )
    
    # Lunch Break
    lunch_start = models.TimeField(
        default=time(13, 0),  # 1 PM
        verbose_name='Lunch Start'
    )
    
    lunch_end = models.TimeField(
        default=time(14, 0),  # 2 PM
        verbose_name='Lunch End'
    )
    
    # Tea Breaks
    tea_break_1_start = models.TimeField(
        null=True,
        blank=True,
        default=time(11, 0),  # 11 AM
        verbose_name='Tea Break 1 Start'
    )
    
    tea_break_1_end = models.TimeField(
        null=True,
        blank=True,
        default=time(11, 15),  # 11:15 AM
        verbose_name='Tea Break 1 End'
    )
    
    tea_break_2_start = models.TimeField(
        null=True,
        blank=True,
        default=time(16, 0),  # 4 PM
        verbose_name='Tea Break 2 Start'
    )
    
    tea_break_2_end = models.TimeField(
        null=True,
        blank=True,
        default=time(16, 15),  # 4:15 PM
        verbose_name='Tea Break 2 End'
    )
    
    # Attendance Settings
    grace_period_minutes = models.IntegerField(
        default=10,
        verbose_name='Grace Period (minutes)',
        help_text='Late arrival grace period'
    )
    
    overtime_after_midnight_cutoff = models.TimeField(
        default=time(2, 0),  # 2 AM
        verbose_name='OT Midnight Cutoff',
        help_text='OT after this time counts as next day (default: 2 AM)'
    )
    
    # Week Configuration
    weekly_off_days = models.CharField(
        max_length=50,
        default='Sunday',
        verbose_name='Weekly Off Days',
        help_text='Comma-separated: Sunday,Saturday'
    )
    
    # Overtime
    overtime_multiplier = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal('1.5'),
        verbose_name='OT Multiplier',
        help_text='OT rate multiplier (1.5 = 1.5x normal rate)'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Shop Settings'
        verbose_name_plural = 'Shop Settings'
    
    def __str__(self):
        return f"Shop Settings - {self.tenant.name}"
    
    def get_total_break_minutes(self):
        """Calculate total break time in minutes"""
        lunch_minutes = 60  # Assuming 1 hour lunch
        
        tea_1_minutes = 0
        if self.tea_break_1_start and self.tea_break_1_end:
            tea_1_delta = datetime.combine(datetime.today(), self.tea_break_1_end) - \
                         datetime.combine(datetime.today(), self.tea_break_1_start)
            tea_1_minutes = tea_1_delta.total_seconds() / 60
        
        tea_2_minutes = 0
        if self.tea_break_2_start and self.tea_break_2_end:
            tea_2_delta = datetime.combine(datetime.today(), self.tea_break_2_end) - \
                         datetime.combine(datetime.today(), self.tea_break_2_start)
            tea_2_minutes = tea_2_delta.total_seconds() / 60
        
        return lunch_minutes + tea_1_minutes + tea_2_minutes
    
# ==================== ATTENDANCE MODELS ====================

class Attendance(models.Model):
    """Daily attendance tracking with clock in/out"""
    
    STATUS_CHOICES = [
        ('PRESENT', 'Present'),
        ('LATE', 'Late'),
        ('HALF_DAY', 'Half Day'),
        ('ABSENT', 'Absent'),
        ('WEEKLY_OFF', 'Weekly Off'),
        ('HOLIDAY', 'Holiday'),
        ('LEAVE', 'On Leave'),
    ]
    
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='attendance_records',
        verbose_name='Employee'
    )
    
    date = models.DateField(
        verbose_name='Date'
    )
    
    # Clock times
    clock_in = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Clock In'
    )
    
    clock_out = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Clock Out'
    )
    
    # Calculated hours
    regular_hours = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Regular Hours'
    )
    
    overtime_hours = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Overtime Hours'
    )
    
    break_hours = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Break Hours'
    )
    
    total_working_hours = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Total Working Hours',
        help_text='Regular + Overtime'
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PRESENT',
        verbose_name='Status'
    )
    
    # Notes
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    # Location (optional - for future GPS tracking)
    clock_in_location = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Clock In Location'
    )
    
    clock_out_location = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Clock Out Location'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Attendance'
        verbose_name_plural = 'Attendance Records'
        ordering = ['-date', 'employee']
        unique_together = ['employee', 'date']
        indexes = [
            models.Index(fields=['employee', 'date']),
            models.Index(fields=['date']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.employee.employee_code} - {self.date} - {self.status}"
    
    def calculate_hours(self):
        """
        Calculate regular, overtime, and break hours
        Based on shop settings and clock in/out times
        """
        if not self.clock_in or not self.clock_out:
            return
        
        from datetime import datetime, time, timedelta
        
        # Get shop settings
        try:
            shop_settings = self.employee.tenant.shop_settings
        except:
            # Default settings if not configured
            shop_opening = time(9, 0)
            shop_closing = time(19, 0)
            total_break_minutes = 60
            grace_period = 10
        else:
            shop_opening = shop_settings.opening_time
            shop_closing = shop_settings.closing_time
            total_break_minutes = shop_settings.get_total_break_minutes()
            grace_period = shop_settings.grace_period_minutes
        
        # Calculate total time worked (in minutes)
        clock_in_dt = self.clock_in
        clock_out_dt = self.clock_out
        
        # Total time between clock in and clock out
        total_delta = clock_out_dt - clock_in_dt
        total_minutes = total_delta.total_seconds() / 60
        
        # Subtract break time
        working_minutes = total_minutes - total_break_minutes
        
        # Calculate expected regular hours
        shop_open_dt = datetime.combine(clock_in_dt.date(), shop_opening)
        shop_close_dt = datetime.combine(clock_in_dt.date(), shop_closing)
        expected_regular_delta = shop_close_dt - shop_open_dt
        expected_regular_minutes = (expected_regular_delta.total_seconds() / 60) - total_break_minutes
        
        # Determine regular vs overtime
        if working_minutes <= expected_regular_minutes:
            # All time is regular
            self.regular_hours = Decimal(str(round(working_minutes / 60, 2)))
            self.overtime_hours = Decimal('0.00')
        else:
            # Has overtime
            self.regular_hours = Decimal(str(round(expected_regular_minutes / 60, 2)))
            overtime_minutes = working_minutes - expected_regular_minutes
            self.overtime_hours = Decimal(str(round(overtime_minutes / 60, 2)))
        
        self.break_hours = Decimal(str(round(total_break_minutes / 60, 2)))
        self.total_working_hours = self.regular_hours + self.overtime_hours
        
        # Determine status
        if not self.clock_in:
            self.status = 'ABSENT'
        else:
            # Check if late
            clock_in_time = clock_in_dt.time()
            grace_time = (datetime.combine(datetime.today(), shop_opening) + 
                         timedelta(minutes=grace_period)).time()
            
            if clock_in_time > grace_time:
                self.status = 'LATE'
            else:
                self.status = 'PRESENT'
            
            # Check for half day (less than 4 hours)
            if self.total_working_hours < Decimal('4.00'):
                self.status = 'HALF_DAY'
    
    def save(self, *args, **kwargs):
        """Auto-calculate hours before saving"""
        if self.clock_in and self.clock_out:
            self.calculate_hours()
        super().save(*args, **kwargs)


class OvertimeLog(models.Model):
    """
    Separate overtime tracking for after-midnight scenarios
    Handles: OT that crosses midnight, early morning OT
    """
    
    OT_TYPE_CHOICES = [
        ('REGULAR_OT', 'Regular Overtime'),
        ('AFTER_MIDNIGHT', 'After Midnight OT'),
        ('EARLY_MORNING', 'Early Morning OT'),
    ]
    
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='overtime_logs',
        verbose_name='Employee'
    )
    
    attendance = models.ForeignKey(
        Attendance,
        on_delete=models.CASCADE,
        related_name='overtime_logs',
        verbose_name='Attendance Record'
    )
    
    date = models.DateField(
        verbose_name='OT Date',
        help_text='Which day this OT should be credited to'
    )
    
    ot_start = models.DateTimeField(
        verbose_name='OT Start Time'
    )
    
    ot_end = models.DateTimeField(
        verbose_name='OT End Time'
    )
    
    ot_hours = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='OT Hours'
    )
    
    ot_type = models.CharField(
        max_length=20,
        choices=OT_TYPE_CHOICES,
        default='REGULAR_OT',
        verbose_name='OT Type'
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Overtime Log'
        verbose_name_plural = 'Overtime Logs'
        ordering = ['-date', '-ot_start']
        indexes = [
            models.Index(fields=['employee', 'date']),
            models.Index(fields=['date']),
        ]
    
    def __str__(self):
        return f"{self.employee.employee_code} - {self.date} - {self.ot_hours}hrs ({self.ot_type})"
    
    def save(self, *args, **kwargs):
        """Calculate OT hours and determine which date to credit"""
        from datetime import datetime, time
        
        # Calculate OT hours
        if self.ot_start and self.ot_end:
            delta = self.ot_end - self.ot_start
            self.ot_hours = Decimal(str(round(delta.total_seconds() / 3600, 2)))
        
        # Determine OT date and type
        # Rule: If shift started before midnight, ALL OT goes to that date
        clock_in_date = self.ot_start.date()
        clock_out_date = self.ot_end.date()
        
        if clock_in_date != clock_out_date:
            # Crossed midnight
            if self.ot_start.time() < time(23, 59):
                # Started before midnight - credit to previous day
                self.date = clock_in_date
                self.ot_type = 'AFTER_MIDNIGHT'
            else:
                # Started after midnight - credit to current day
                self.date = clock_out_date
                self.ot_type = 'EARLY_MORNING'
        else:
            # Same day OT
            self.date = clock_in_date
            self.ot_type = 'REGULAR_OT'
        
        super().save(*args, **kwargs)


class BreakLog(models.Model):
    """Track individual breaks during the day"""
    
    BREAK_TYPE_CHOICES = [
        ('LUNCH', 'Lunch Break'),
        ('TEA', 'Tea Break'),
        ('PRAYER', 'Prayer Break'),
        ('SMOKING', 'Smoking Break'),
        ('TOILET', 'Toilet Break'),
        ('OTHER', 'Other Break'),
    ]
    
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='break_logs',
        verbose_name='Employee'
    )
    
    attendance = models.ForeignKey(
        Attendance,
        on_delete=models.CASCADE,
        related_name='break_logs',
        verbose_name='Attendance Record'
    )
    
    date = models.DateField(
        verbose_name='Date'
    )
    
    break_type = models.CharField(
        max_length=20,
        choices=BREAK_TYPE_CHOICES,
        default='OTHER',
        verbose_name='Break Type'
    )
    
    start_time = models.DateTimeField(
        verbose_name='Break Start'
    )
    
    end_time = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Break End'
    )
    
    duration_minutes = models.IntegerField(
        default=0,
        verbose_name='Duration (minutes)'
    )
    
    notes = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Notes'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Break Log'
        verbose_name_plural = 'Break Logs'
        ordering = ['-date', '-start_time']
        indexes = [
            models.Index(fields=['employee', 'date']),
            models.Index(fields=['attendance']),
        ]
    
    def __str__(self):
        return f"{self.employee.employee_code} - {self.break_type} - {self.duration_minutes}min"
    
    def save(self, *args, **kwargs):
        """Calculate duration if end_time is set"""
        if self.start_time and self.end_time:
            delta = self.end_time - self.start_time
            self.duration_minutes = int(delta.total_seconds() / 60)
        
        super().save(*args, **kwargs)
    
    def is_within_scheduled_break(self):
        """Check if break falls within scheduled break times"""
        try:
            shop_settings = self.employee.tenant.shop_settings
            break_time = self.start_time.time()
            
            # Check lunch
            if (shop_settings.lunch_start and shop_settings.lunch_end and
                shop_settings.lunch_start <= break_time <= shop_settings.lunch_end):
                return True, 'LUNCH'
            
            # Check tea break 1
            if (shop_settings.tea_break_1_start and shop_settings.tea_break_1_end and
                shop_settings.tea_break_1_start <= break_time <= shop_settings.tea_break_1_end):
                return True, 'TEA'
            
            # Check tea break 2
            if (shop_settings.tea_break_2_start and shop_settings.tea_break_2_end and
                shop_settings.tea_break_2_start <= break_time <= shop_settings.tea_break_2_end):
                return True, 'TEA'
            
            return False, None
        except:
            return False, None
        
