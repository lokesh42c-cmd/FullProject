"""
Django Admin configuration for core app
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from .models import Tenant, User, SubscriptionPlan, TenantSubscription


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    """Admin interface for Tenant model"""
    list_display = ['name', 'email', 'city', 'state', 'is_active', 'created_at']
    list_filter = ['is_active', 'city', 'state', 'created_at']
    search_fields = ['name', 'email', 'phone_number', 'slug']
    readonly_fields = ['slug', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'email', 'phone_number', 'is_active')
        }),
        ('Address', {
            'fields': ('address', 'city', 'state', 'pincode')
        }),
        ('Business Details', {
            'fields': ('gstin', 'pan_number', 'logo'),
            'classes': ('collapse',)
        }),
        ('Bank Details', {
            'fields': ('bank_name', 'bank_account_number', 'bank_ifsc_code', 'bank_branch'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin interface for User model"""
    list_display = ['email', 'name', 'tenant', 'get_role', 'is_active', 'date_joined']
    list_filter = ['is_active', 'is_staff', 'is_superuser', 'date_joined']
    search_fields = ['email', 'name', 'phone_number']
    ordering = ['-date_joined']
    
    fieldsets = (
        ('Login Credentials', {
            'fields': ('email', 'password')
        }),
        ('Personal Information', {
            'fields': ('name', 'phone_number')
        }),
        ('Tenant', {
            'fields': ('tenant',)
        }),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
            'classes': ('collapse',)
        }),
        ('Important Dates', {
            'fields': ('last_login', 'date_joined'),
            'classes': ('collapse',)
        }),
    )
    
    add_fieldsets = (
        ('Create New User', {
            'classes': ('wide',),
            'fields': ('email', 'name', 'password1', 'password2', 'tenant', 'is_active'),
        }),
    )
    
    readonly_fields = ['last_login', 'date_joined']
    filter_horizontal = ('groups', 'user_permissions',)
    
    def get_role(self, obj):
        """Display role from employee profile"""
        if obj.employee:
            return obj.employee.get_role_display()
        return '-'
    get_role.short_description = 'Role'

# core/admin.py

@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    """Admin for Subscription Plans"""
    list_display = ['name', 'tier', 'price_monthly', 'price_yearly', 'max_orders_per_month', 'is_popular', 'is_active']
    list_filter = ['tier', 'is_active', 'is_popular']
    search_fields = ['name', 'description']
    
    fieldsets = (
        ('Plan Details', {
            'fields': ('tier', 'name', 'description', 'is_popular', 'is_active', 'display_order')
        }),
        ('Pricing', {
            'fields': ('price_monthly', 'price_yearly', 'trial_days')
        }),
        ('Limits', {
            'fields': (
                'max_orders_per_month', 'max_customers', 'max_employees',
                'max_users', 'max_inventory_items', 'max_vendors', 'max_photos_per_order'
            )
        }),
        ('Customer Features', {
            'fields': ('allow_b2b_customers', 'allow_measurement_profiles'),
            'classes': ('collapse',)
        }),
        ('Invoicing Features', {
            'fields': ('allow_gst_invoicing', 'allow_item_discount', 'allow_invoice_customization'),
            'classes': ('collapse',)
        }),
        ('Inventory Features', {
            'fields': ('allow_inventory', 'allow_barcode_sku', 'allow_purchase_orders'),
            'classes': ('collapse',)
        }),
        ('Employee Features', {
            'fields': ('allow_employee_management', 'allow_attendance', 'allow_leave_management', 'allow_payroll'),
            'classes': ('collapse',)
        }),
        ('Workflow Features', {
            'fields': ('allow_workflow', 'max_workflow_stages', 'allow_task_assignment', 'allow_qa_system', 'allow_trial_feedback'),
            'classes': ('collapse',)
        }),
        ('QR & Reports', {
            'fields': ('allow_order_qr', 'allow_employee_qr', 'report_types', 'allow_data_export'),
            'classes': ('collapse',)
        }),
        ('Support & API', {
            'fields': ('support_level', 'allow_api_access'),
            'classes': ('collapse',)
        }),
    )


@admin.register(TenantSubscription)
class TenantSubscriptionAdmin(admin.ModelAdmin):
    """Admin for Tenant Subscriptions"""
    list_display = ['tenant', 'plan', 'status', 'billing_cycle', 'start_date', 'end_date', 'orders_this_month', 'days_remaining_display']
    list_filter = ['status', 'billing_cycle', 'plan']
    search_fields = ['tenant__name']
    readonly_fields = ['orders_this_month', 'last_reset_date', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Subscription', {
            'fields': ('tenant', 'plan', 'status', 'billing_cycle')
        }),
        ('Dates', {
            'fields': ('start_date', 'end_date', 'trial_end_date', 'auto_renew')
        }),
        ('Usage Tracking', {
            'fields': ('orders_this_month', 'last_reset_date')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    def days_remaining_display(self, obj):
        """Display days remaining"""
        days = obj.days_remaining()
        if days > 0:
            return f"{days} days"
        return "Expired"
    days_remaining_display.short_description = 'Days Left'