"""
Purchase Management Admin
Django admin configuration
"""

from django.contrib import admin
from .models import Vendor, PurchaseBill, Expense, Payment


@admin.register(Vendor)
class VendorAdmin(admin.ModelAdmin):
    """Vendor admin configuration"""
    
    list_display = [
        'name', 'business_name', 'phone', 'city', 'state',
        'outstanding_balance', 'is_active', 'created_at'
    ]
    
    list_filter = ['is_active', 'state', 'created_at']
    
    search_fields = ['name', 'business_name', 'phone', 'gstin', 'city']
    
    readonly_fields = [
        'total_purchases', 'total_paid', 'outstanding_balance',
        'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'phone', 'alternate_phone', 'email')
        }),
        ('Business Information', {
            'fields': ('business_name', 'gstin', 'pan', 'payment_terms_days')
        }),
        ('Address', {
            'fields': ('address_line1', 'address_line2', 'city', 'state', 'pincode')
        }),
        ('Financial Summary', {
            'fields': ('total_purchases', 'total_paid', 'outstanding_balance'),
            'classes': ('collapse',)
        }),
        ('Additional', {
            'fields': ('notes', 'is_active')
        }),
        ('Meta', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new
            obj.tenant = request.user.tenant
        super().save_model(request, obj, form, change)
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if hasattr(request.user, 'tenant'):
            return qs.filter(tenant=request.user.tenant)
        return qs


@admin.register(PurchaseBill)
class PurchaseBillAdmin(admin.ModelAdmin):
    """Purchase Bill admin configuration"""
    
    list_display = [
        'bill_number', 'vendor', 'bill_date', 'bill_amount',
        'paid_amount', 'balance_amount', 'payment_status', 'created_at'
    ]
    
    list_filter = ['payment_status', 'bill_date', 'created_at']
    
    search_fields = ['bill_number', 'vendor__name', 'vendor__business_name', 'description']
    
    readonly_fields = [
        'paid_amount', 'balance_amount', 'payment_status',
        'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Bill Information', {
            'fields': ('bill_number', 'bill_date', 'vendor')
        }),
        ('Amounts', {
            'fields': ('bill_amount', 'paid_amount', 'balance_amount', 'payment_status')
        }),
        ('Details', {
            'fields': ('description', 'bill_image')
        }),
        ('Additional', {
            'fields': ('notes',)
        }),
        ('Meta', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new
            obj.tenant = request.user.tenant
        super().save_model(request, obj, form, change)
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if hasattr(request.user, 'tenant'):
            return qs.filter(tenant=request.user.tenant)
        return qs


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    """Expense admin configuration"""
    
    list_display = [
        'expense_date', 'category', 'expense_amount',
        'paid_amount', 'balance_amount', 'payment_status', 'created_at'
    ]
    
    list_filter = ['payment_status', 'category', 'expense_date', 'created_at']
    
    search_fields = ['description', 'notes']
    
    readonly_fields = [
        'paid_amount', 'balance_amount', 'payment_status',
        'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Expense Information', {
            'fields': ('expense_date', 'category')
        }),
        ('Amounts', {
            'fields': ('expense_amount', 'paid_amount', 'balance_amount', 'payment_status')
        }),
        ('Details', {
            'fields': ('description', 'receipt_image')
        }),
        ('Additional', {
            'fields': ('notes',)
        }),
        ('Meta', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new
            obj.tenant = request.user.tenant
        super().save_model(request, obj, form, change)
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if hasattr(request.user, 'tenant'):
            return qs.filter(tenant=request.user.tenant)
        return qs


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    """Payment admin configuration"""
    
    list_display = [
        'payment_number', 'payment_date', 'payment_type',
        'amount', 'payment_method', 'display_reference', 'created_at'
    ]
    
    list_filter = ['payment_type', 'payment_method', 'payment_date', 'created_at']
    
    search_fields = ['payment_number', 'reference_number', 'notes']
    
    readonly_fields = ['payment_number', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Payment Information', {
            'fields': ('payment_number', 'payment_date', 'payment_type')
        }),
        ('Links', {
            'fields': ('purchase_bill', 'expense')
        }),
        ('Payment Details', {
            'fields': ('amount', 'payment_method', 'reference_number')
        }),
        ('Additional', {
            'fields': ('notes',)
        }),
        ('Meta', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new
            obj.tenant = request.user.tenant
        super().save_model(request, obj, form, change)
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if hasattr(request.user, 'tenant'):
            return qs.filter(tenant=request.user.tenant)
        return qs