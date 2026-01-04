from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Department,
    Employee,
    PieceRateItem,
    ShopSettings,
    Attendance,
    OvertimeLog,
    BreakLog,
)


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    """Department administration"""
    
    list_display = ['name', 'tenant', 'employee_count', 'is_active']
    list_filter = ['is_active', 'tenant']
    search_fields = ['name', 'description']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('tenant', 'name', 'description')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
    )
    
    def employee_count(self, obj):
        """Show number of employees in department"""
        count = obj.employees.filter(is_active=True).count()
        return f"{count} employees"
    employee_count.short_description = 'Employees'


class PieceRateInline(admin.TabularInline):
    """Inline for piece rates"""
    model = PieceRateItem
    extra = 0
    fields = ['item_category', 'rate_per_item', 'is_active']


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    """Employee administration"""
    
    list_display = [
        'employee_code',
        'user_name',
        'role',
        'department',
        'payment_type',
        'has_qr_badge',
        'is_active_badge',
        'date_joined',
    ]
    
    list_filter = [
        'role',
        'department',
        'payment_type',
        'is_active',
        'gender',
        'blood_group',
    ]
    
    search_fields = [
        'employee_code',
        'user__email',
        'user__first_name',
        'user__last_name',
        'phone_number',
        'aadhar_number',
        'pan_number',
        'uan_number',
    ]
    
    readonly_fields = ['qr_code_display', 'age', 'created_at', 'updated_at']
    
    inlines = [PieceRateInline]
    
    fieldsets = (
        ('Account & Code', {
            'fields': ('tenant', 'user', 'employee_code')
        }),
        ('Personal Details', {
            'fields': (
                'date_of_birth', 'age', 'gender', 'blood_group', 'photo'
            )
        }),
        ('Role & Department', {
            'fields': ('role', 'department', 'specialization', 'reports_to')
        }),
        ('Employment', {
            'fields': ('date_joined', 'date_left', 'is_active')
        }),
        ('Payment Configuration', {
            'fields': (
                'payment_type',
                'monthly_salary',
                'hourly_rate',
                'weekly_rate',
                'daily_rate',
            )
        }),
        ('Government IDs', {
            'fields': (
                'aadhar_number', 'aadhar_card_copy',
                'pan_number', 'pan_card_copy',
            ),
            'classes': ('collapse',)
        }),
        ('PF & ESI Details', {
            'fields': (
                'uan_number',
                'pf_number',
                'esi_number',
            ),
            'classes': ('collapse',)
        }),
        ('Bank Details', {
            'fields': (
                'bank_account_name',
                'bank_account_number',
                'bank_name',
                'bank_branch',
                'bank_ifsc',
                'upi_id',
            ),
            'classes': ('collapse',)
        }),
        ('Nominee Details', {
            'fields': (
                'nominee_name',
                'nominee_relationship',
                'nominee_phone',
                'nominee_aadhar',
            ),
            'classes': ('collapse',)
        }),
        ('Contact Information', {
            'fields': (
                'phone_number',
                'alternate_phone',
                'emergency_contact_name',
                'emergency_contact_phone',
                'emergency_contact_relationship',
            )
        }),
        ('Address', {
            'fields': (
                'current_address',
                'permanent_address',
                'city',
                'state',
                'pincode',
            ),
            'classes': ('collapse',)
        }),
        ('Workshop Access', {
            'fields': ('workshop_pin',),
            'description': 'Set 4-digit PIN for workshop tablet login (Masters only)'
        }),
        ('QR Code', {
            'fields': ('qr_code_display',),
        }),
        ('Additional', {
            'fields': ('notes',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def user_name(self, obj):
        """Display user's full name"""
        return obj.user.get_full_name() or obj.user.email
    user_name.short_description = 'Name'
    
    def is_active_badge(self, obj):
        """Show active status badge"""
        if obj.is_active:
            return format_html(
                '<span style="color: green;">✓ Active</span>'
            )
        return format_html(
            '<span style="color: red;">✗ Inactive</span>'
        )
    is_active_badge.short_description = 'Status'
    
    def has_qr_badge(self, obj):
        """Show if employee has QR code"""
        if obj.qr_code:
            return format_html(
                '<span style="color: green; font-size: 16px;">✓</span>'
            )
        return format_html(
            '<span style="color: red; font-size: 16px;">✗</span>'
        )
    has_qr_badge.short_description = 'QR'
    
    def qr_code_display(self, obj):
        """Display QR code image in admin"""
        if obj.qr_code:
            return format_html(
                '<div style="text-align: center;">'
                '<img src="{}" style="max-width: 200px; border: 2px solid #ddd; padding: 10px; background: white;" /><br>'
                '<strong style="margin-top: 10px; display: block;">{}</strong><br>'
                '<small style="color: #666;">Scan for Attendance & Work Tracking</small>'
                '</div>',
                obj.qr_code.url,
                obj.employee_code
            )
        return format_html(
            '<span style="color: #999;">QR code will be generated on save</span>'
        )
    qr_code_display.short_description = 'Employee QR Code'
    
    def age(self, obj):
        """Display calculated age"""
        if obj.age:
            return f"{obj.age} years"
        return "-"
    age.short_description = 'Age'

@admin.register(ShopSettings)
class ShopSettingsAdmin(admin.ModelAdmin):
    """Shop settings administration"""
    
    list_display = ['tenant', 'opening_time', 'closing_time', 'weekly_off_days']
    
    fieldsets = (
        ('Shop Timings', {
            'fields': ('tenant', 'opening_time', 'closing_time')
        }),
        ('Lunch Break', {
            'fields': ('lunch_start', 'lunch_end')
        }),
        ('Tea Breaks', {
            'fields': (
                'tea_break_1_start', 'tea_break_1_end',
                'tea_break_2_start', 'tea_break_2_end',
            )
        }),
        ('Attendance Settings', {
            'fields': (
                'grace_period_minutes',
                'overtime_after_midnight_cutoff',
                'weekly_off_days',
                'overtime_multiplier',
            )
        }),
    )


class OvertimeLogInline(admin.TabularInline):
    """Inline for overtime logs"""
    model = OvertimeLog
    extra = 0
    fields = ['date', 'ot_start', 'ot_end', 'ot_hours', 'ot_type']
    readonly_fields = ['ot_hours', 'ot_type']


class BreakLogInline(admin.TabularInline):
    """Inline for break logs"""
    model = BreakLog
    extra = 0
    fields = ['break_type', 'start_time', 'end_time', 'duration_minutes']
    readonly_fields = ['duration_minutes']


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    """Attendance administration"""
    
    list_display = [
        'employee_code',
        'employee_name',
        'date',
        'clock_in_display',
        'clock_out_display',
        'total_hours',
        'status_badge',
    ]
    
    list_filter = [
        'status',
        'date',
        'employee__department',
    ]
    
    search_fields = [
        'employee__employee_code',
        'employee__user__first_name',
        'employee__user__last_name',
    ]
    
    date_hierarchy = 'date'
    
    readonly_fields = [
        'regular_hours',
        'overtime_hours',
        'break_hours',
        'total_working_hours',
        'status',
    ]
    
    inlines = [OvertimeLogInline, BreakLogInline]
    
    fieldsets = (
        ('Employee & Date', {
            'fields': ('employee', 'date')
        }),
        ('Clock Times', {
            'fields': (
                'clock_in', 'clock_out',
                'clock_in_location', 'clock_out_location',
            )
        }),
        ('Calculated Hours', {
            'fields': (
                'regular_hours',
                'overtime_hours',
                'break_hours',
                'total_working_hours',
            )
        }),
        ('Status', {
            'fields': ('status', 'notes')
        }),
    )
    
    def employee_code(self, obj):
        return obj.employee.employee_code
    employee_code.short_description = 'Emp Code'
    employee_code.admin_order_field = 'employee__employee_code'
    
    def employee_name(self, obj):
        return obj.employee.user.get_full_name()
    employee_name.short_description = 'Name'
    
    def clock_in_display(self, obj):
        if obj.clock_in:
            return obj.clock_in.strftime('%I:%M %p')
        return '-'
    clock_in_display.short_description = 'Clock In'
    
    def clock_out_display(self, obj):
        if obj.clock_out:
            return obj.clock_out.strftime('%I:%M %p')
        return '-'
    clock_out_display.short_description = 'Clock Out'
    
    def total_hours(self, obj):
        return f"{obj.total_working_hours}h"
    total_hours.short_description = 'Total'
    
    def status_badge(self, obj):
        """Show status with color"""
        colors = {
            'PRESENT': 'green',
            'LATE': 'orange',
            'ABSENT': 'red',
            'HALF_DAY': 'orange',
            'WEEKLY_OFF': 'blue',
            'HOLIDAY': 'blue',
            'LEAVE': 'gray',
        }
        color = colors.get(obj.status, 'black')
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'


@admin.register(OvertimeLog)
class OvertimeLogAdmin(admin.ModelAdmin):
    """Overtime log administration"""
    
    list_display = [
        'employee_code',
        'employee_name',
        'date',
        'ot_hours_display',
        'ot_type_badge',
    ]
    
    list_filter = ['ot_type', 'date', 'employee__department']
    search_fields = ['employee__employee_code', 'employee__user__first_name']
    date_hierarchy = 'date'
    
    readonly_fields = ['ot_hours', 'ot_type', 'date']
    
    def employee_code(self, obj):
        return obj.employee.employee_code
    employee_code.short_description = 'Emp Code'
    
    def employee_name(self, obj):
        return obj.employee.user.get_full_name()
    employee_name.short_description = 'Name'
    
    def ot_hours_display(self, obj):
        return f"{obj.ot_hours}h"
    ot_hours_display.short_description = 'OT Hours'
    
    def ot_type_badge(self, obj):
        """Show OT type with color"""
        colors = {
            'REGULAR_OT': 'green',
            'AFTER_MIDNIGHT': 'orange',
            'EARLY_MORNING': 'blue',
        }
        color = colors.get(obj.ot_type, 'black')
        return format_html(
            '<span style="color: {};">{}</span>',
            color,
            obj.get_ot_type_display()
        )
    ot_type_badge.short_description = 'Type'


@admin.register(BreakLog)
class BreakLogAdmin(admin.ModelAdmin):
    """Break log administration"""
    
    list_display = [
        'employee_code',
        'employee_name',
        'date',
        'break_type',
        'start_time_display',
        'duration_display',
    ]
    
    list_filter = ['break_type', 'date', 'employee__department']
    search_fields = ['employee__employee_code', 'employee__user__first_name']
    date_hierarchy = 'date'
    
    readonly_fields = ['duration_minutes']
    
    def employee_code(self, obj):
        return obj.employee.employee_code
    employee_code.short_description = 'Emp Code'
    
    def employee_name(self, obj):
        return obj.employee.user.get_full_name()
    employee_name.short_description = 'Name'
    
    def start_time_display(self, obj):
        return obj.start_time.strftime('%I:%M %p')
    start_time_display.short_description = 'Start Time'
    
    def duration_display(self, obj):
        return f"{obj.duration_minutes} min"
    duration_display.short_description = 'Duration' 