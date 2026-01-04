"""
Invoicing app admin - Invoice management
Date: 2026-01-03
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import Invoice, InvoiceItem


# ==================== INVOICE ITEM INLINE ====================

class InvoiceItemInline(admin.TabularInline):
    model = InvoiceItem
    extra = 1
    fields = ['item', 'item_description', 'hsn_sac_code', 'item_type', 'quantity', 'unit_price', 'gst_rate']
    readonly_fields = []


# ==================== INVOICE ADMIN ====================

@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ['invoice_number', 'customer', 'invoice_date', 'status', 'payment_status', 
                   'grand_total', 'balance_due', 'remaining_balance', 'created_at']
    list_filter = ['status', 'payment_status', 'tax_type', 'invoice_date', 'created_at']
    search_fields = ['invoice_number', 'customer__name', 'customer__phone', 'billing_name']
    readonly_fields = ['invoice_number', 'tax_type', 'subtotal', 'total_cgst', 'total_sgst', 
                      'total_igst', 'grand_total', 'balance_due', 'total_paid', 'remaining_balance',
                      'payment_status', 'created_at', 'updated_at']
    date_hierarchy = 'invoice_date'
    inlines = [InvoiceItemInline]
    
    fieldsets = (
        ('Invoice Information', {
            'fields': ('tenant', 'invoice_number', 'invoice_date', 'customer', 'order', 'status')
        }),
        ('Billing Address', {
            'fields': ('billing_name', 'billing_address', 'billing_city', 'billing_state', 
                      'billing_pincode', 'billing_gstin')
        }),
        ('Shipping Address', {
            'fields': ('shipping_name', 'shipping_address', 'shipping_city', 'shipping_state', 
                      'shipping_pincode'),
            'classes': ('collapse',)
        }),
        ('Tax Details', {
            'fields': ('tax_type',)
        }),
        ('Amounts', {
            'fields': ('subtotal', 'total_cgst', 'total_sgst', 'total_igst', 'grand_total')
        }),
        ('Payment Tracking', {
            'fields': ('total_advance_adjusted', 'balance_due', 'total_paid', 
                      'remaining_balance', 'payment_status')
        }),
        ('Additional', {
            'fields': ('notes', 'terms_and_conditions'),
            'classes': ('collapse',)
        }),
        ('Audit', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        readonly = list(self.readonly_fields)
        if obj:  # Editing
            readonly.append('tenant')
            if obj.status in ['ISSUED', 'PAID']:
                readonly.extend(['customer', 'order', 'invoice_date'])
        return readonly
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new
            obj.tenant = request.user.tenant
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


# ==================== INVOICE ITEM ADMIN ====================

@admin.register(InvoiceItem)
class InvoiceItemAdmin(admin.ModelAdmin):
    list_display = ['invoice', 'item_description', 'quantity', 'unit_price', 'gst_rate', 
                   'subtotal_display', 'total_amount_display']
    list_filter = ['item_type', 'gst_rate']
    search_fields = ['invoice__invoice_number', 'item_description', 'hsn_sac_code']
    
    def subtotal_display(self, obj):
        return f"₹{obj.subtotal:,.2f}"
    subtotal_display.short_description = 'Subtotal'
    
    def total_amount_display(self, obj):
        return f"₹{obj.total_amount:,.2f}"
    total_amount_display.short_description = 'Total Amount'