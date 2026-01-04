"""
Orders App Admin - Simplified for GST Compliance
Date: 2026-01-03
"""

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from .models import Customer, Order, OrderItem, Item, StockTransaction, OrderReferencePhoto


# ==================== CUSTOMER ADMIN ====================

@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ['name', 'phone', 'whatsapp_number', 'customer_type', 'city', 'is_active', 'created_at']
    list_filter = ['customer_type', 'is_active', 'state', 'gender', 'created_at']
    search_fields = ['name', 'phone', 'whatsapp_number', 'email', 'business_name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('tenant', 'customer_type', 'name', 'phone', 'whatsapp_number', 'email', 'gender')
        }),
        ('Business Details (B2B)', {
            'fields': ('business_name', 'gstin', 'pan'),
            'classes': ('collapse',),
        }),
        ('Address', {
            'fields': ('address_line1', 'address_line2', 'city', 'state', 'country', 'pincode')
        }),
        ('Basic Measurements', {
            'fields': ('height', 'weight', 'shoulder_width', 'bust_chest', 'waist', 'hip', 
                      'shoulder', 'sleeve_length', 'armhole', 'garment_length'),
            'classes': ('collapse',),
        }),
        ('Women-Specific Measurements', {
            'fields': ('front_neck_depth', 'back_neck_depth', 'upper_chest', 'under_bust', 
                      'shoulder_to_apex', 'bust_point_distance', 'front_cross', 'back_cross', 
                      'lehenga_length', 'pant_waist', 'ankle_opening'),
            'classes': ('collapse',),
        }),
        ('Men-Specific Measurements', {
            'fields': ('neck_round', 'stomach_round', 'yoke_width', 'front_width', 'back_width',
                      'trouser_waist', 'front_rise', 'back_rise', 'bottom_opening'),
            'classes': ('collapse',),
        }),
        ('Sleeves & Legs Measurements', {
            'fields': ('upper_arm_bicep', 'sleeve_loose', 'wrist_round', 'thigh', 'knee', 
                      'ankle', 'rise', 'inseam', 'outseam'),
            'classes': ('collapse',),
        }),
        ('Custom Measurements', {
            'fields': ('custom_field_1', 'custom_field_2', 'custom_field_3', 'custom_field_4', 
                      'custom_field_5', 'custom_field_6', 'custom_field_7', 'custom_field_8',
                      'custom_field_9', 'custom_field_10'),
            'classes': ('collapse',),
        }),
        ('Measurement Notes', {
            'fields': ('measurement_notes',),
            'classes': ('collapse',),
        }),
        ('Additional', {
            'fields': ('notes', 'is_active')
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        if obj:  # Editing existing
            return ['tenant']
        return []
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new
            obj.tenant = request.user.tenant
        super().save_model(request, obj, form, change)


# ==================== ORDER ADMIN ====================

class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 1
    fields = ['item_type', 'item', 'item_description', 'quantity', 'unit_price', 'tax_percentage', 'status']
    readonly_fields = []


class OrderReferencePhotoInline(admin.TabularInline):
    model = OrderReferencePhoto
    extra = 1
    fields = ['photo', 'description', 'uploaded_by', 'uploaded_at']
    readonly_fields = ['uploaded_by', 'uploaded_at']


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['order_number', 'customer', 'order_status', 'delivery_status', 
                   'expected_delivery_date', 'assigned_to', 'estimated_total', 'is_locked', 'created_at']
    list_filter = ['order_status', 'delivery_status', 'is_locked', 'created_at']
    search_fields = ['order_number', 'customer__name', 'customer__phone']
    readonly_fields = ['order_number', 'qr_code', 'created_at', 'updated_at']
    date_hierarchy = 'order_date'
    inlines = [OrderItemInline, OrderReferencePhotoInline]
    
    fieldsets = (
        ('Order Information', {
            'fields': ('tenant', 'customer', 'order_number', 'order_date', 'assigned_to', 'qr_code')
        }),
        ('Delivery', {
            'fields': ('expected_delivery_date', 'actual_delivery_date', 'delivery_status')
        }),
        ('Status', {
            'fields': ('order_status', 'is_locked')
        }),
        ('Pricing', {
            'fields': ('estimated_total', 'payment_terms')
        }),
        ('Details', {
            'fields': ('order_summary', 'customer_instructions')
        }),
        ('Audit', {
            'fields': ('created_by', 'updated_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        readonly = ['order_number', 'created_at', 'updated_at']
        if obj:  # Editing
            readonly.append('tenant')
            if obj.is_locked:
                readonly.extend(['customer', 'order_date'])
        return readonly
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new
            obj.tenant = request.user.tenant
            obj.created_by = request.user
        else:
            obj.updated_by = request.user
        super().save_model(request, obj, form, change)


# ==================== ITEM ADMIN ====================

@admin.register(Item)
class ItemAdmin(admin.ModelAdmin):
    list_display = ['name', 'item_type', 'track_stock', 'current_stock', 'selling_price', 
                   'is_low_stock_badge', 'is_active']
    list_filter = ['item_type', 'track_stock', 'is_active', 'has_been_used']
    search_fields = ['name', 'description', 'hsn_sac_code', 'barcode']
    readonly_fields = ['current_stock', 'has_been_used', 'deleted_at', 'created_at', 'updated_at', 
                      'is_low_stock', 'stock_value']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('tenant', 'name', 'description', 'item_type')
        }),
        ('Stock Control', {
            'fields': ('track_stock', 'allow_negative_stock', 'unit', 'opening_stock', 
                      'current_stock', 'min_stock_level', 'is_low_stock', 'stock_value'),
        }),
        ('Pricing', {
            'fields': ('purchase_price', 'selling_price'),
        }),
        ('GST & Barcode', {
            'fields': ('hsn_sac_code', 'tax_percent', 'barcode'),
        }),
        ('Status & Tracking', {
            'fields': ('is_active', 'has_been_used', 'deleted_at', 'created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )
    
    def is_low_stock_badge(self, obj):
        if not obj.track_stock:
            return '-'
        if obj.is_low_stock:
            return format_html(
                '<span style="background-color: #dc3545; color: white; padding: 3px 10px; border-radius: 3px;">LOW</span>'
            )
        return format_html(
            '<span style="background-color: #28a745; color: white; padding: 3px 10px; border-radius: 3px;">OK</span>'
        )
    is_low_stock_badge.short_description = 'Stock Status'
    
    def get_readonly_fields(self, request, obj=None):
        readonly = list(self.readonly_fields)
        if obj and obj.has_been_used:
            # Lock critical fields after usage
            readonly.extend(['item_type', 'track_stock', 'unit'])
        if obj:
            readonly.append('tenant')
            # Lock opening_stock after creation
            readonly.append('opening_stock')
        return readonly
    
    def save_model(self, request, obj, form, change):
        if not change:
            obj.tenant = request.user.tenant
        super().save_model(request, obj, form, change)


# ==================== STOCK TRANSACTION ADMIN ====================

@admin.register(StockTransaction)
class StockTransactionAdmin(admin.ModelAdmin):
    list_display = ['created_at', 'item', 'transaction_type', 'quantity_display', 
                   'stock_before', 'stock_after', 'reference_type', 'reference_id']
    list_filter = ['transaction_type', 'reference_type', 'created_at']
    search_fields = ['item__name', 'reference_id', 'notes']
    readonly_fields = ['tenant', 'item', 'transaction_type', 'quantity', 'stock_before', 
                      'stock_after', 'reference_type', 'reference_id', 'notes', 
                      'created_by', 'created_at']
    
    def has_add_permission(self, request):
        return False  # Transactions created automatically
    
    def has_delete_permission(self, request, obj=None):
        return False  # Audit trail - no deletion
    
    def quantity_display(self, obj):
        if obj.quantity >= 0:
            return format_html(
                '<span style="color: green;">+{}</span>',
                obj.quantity
            )
        return format_html(
            '<span style="color: red;">{}</span>',
            obj.quantity
        )
    quantity_display.short_description = 'Qty'



# ==================== DEPRECATED ADMIN (COMMENTED OUT) ====================
# TODO: Remove after migration complete

"""
# OLD FAMILY MEMBER ADMIN
@admin.register(FamilyMember)
class FamilyMemberAdmin(admin.ModelAdmin):
    pass

@admin.register(FamilyMemberMeasurement)
class FamilyMemberMeasurementAdmin(admin.ModelAdmin):
    pass

# OLD INVOICE/PAYMENT ADMIN
@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    pass

@admin.register(OrderPayment)
class OrderPaymentAdmin(admin.ModelAdmin):
    pass
"""