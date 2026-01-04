"""
Financials app admin - Financial management
Date: 2026-01-03
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import ReceiptVoucher, Payment, RefundVoucher


# ==================== RECEIPT VOUCHER ADMIN ====================

@admin.register(ReceiptVoucher)
class ReceiptVoucherAdmin(admin.ModelAdmin):
    list_display = ['voucher_number', 'customer', 'receipt_date', 'advance_amount', 
                   'total_amount', 'payment_mode', 'adjusted_amount', 'remaining_amount', 'created_at']
    list_filter = ['payment_mode', 'tax_type', 'deposited_to_bank', 'receipt_date']
    search_fields = ['voucher_number', 'customer__name', 'customer__phone', 'transaction_reference']
    readonly_fields = ['voucher_number', 'tax_type', 'cgst_amount', 'sgst_amount', 'igst_amount',
                      'total_amount', 'remaining_amount', 'created_at', 'updated_at']
    date_hierarchy = 'receipt_date'
    
    fieldsets = (
        ('Receipt Information', {
            'fields': ('tenant', 'voucher_number', 'receipt_date', 'customer', 'order')
        }),
        ('Amount Details', {
            'fields': ('advance_amount', 'gst_rate', 'tax_type', 'cgst_amount', 
                      'sgst_amount', 'igst_amount', 'total_amount')
        }),
        ('Payment Details', {
            'fields': ('payment_mode', 'transaction_reference', 'deposited_to_bank', 'deposit_date')
        }),
        ('Adjustment Tracking', {
            'fields': ('adjusted_amount', 'remaining_amount')
        }),
        ('Additional', {
            'fields': ('notes', 'is_issued'),
            'classes': ('collapse',)
        }),
        ('Audit', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        readonly = list(self.readonly_fields)
        if obj and obj.is_issued:  # Cannot edit issued vouchers
            readonly.extend(['customer', 'order', 'advance_amount', 'gst_rate', 
                           'payment_mode', 'receipt_date'])
        if obj:
            readonly.append('tenant')
        return readonly
    
    def save_model(self, request, obj, form, change):
        if not change:
            obj.tenant = request.user.tenant
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


# ==================== PAYMENT ADMIN ====================

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['payment_number', 'invoice', 'payment_date', 'amount', 
                   'payment_mode', 'deposited_to_bank', 'created_at']
    list_filter = ['payment_mode', 'deposited_to_bank', 'payment_date']
    search_fields = ['payment_number', 'invoice__invoice_number', 'transaction_reference']
    readonly_fields = ['payment_number', 'created_at', 'updated_at']
    date_hierarchy = 'payment_date'
    
    fieldsets = (
        ('Payment Information', {
            'fields': ('tenant', 'payment_number', 'payment_date', 'invoice', 'amount')
        }),
        ('Payment Details', {
            'fields': ('payment_mode', 'transaction_reference', 'deposited_to_bank', 'deposit_date')
        }),
        ('Additional', {
            'fields': ('notes',),
            'classes': ('collapse',)
        }),
        ('Audit', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        readonly = list(self.readonly_fields)
        if obj:
            readonly.extend(['tenant', 'invoice', 'amount', 'payment_date'])
        return readonly
    
    def save_model(self, request, obj, form, change):
        if not change:
            obj.tenant = request.user.tenant
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


# ==================== REFUND VOUCHER ADMIN ====================

@admin.register(RefundVoucher)
class RefundVoucherAdmin(admin.ModelAdmin):
    list_display = ['refund_number', 'customer', 'receipt_voucher', 'refund_date', 
                   'refund_amount', 'total_refund', 'refund_mode', 'created_at']
    list_filter = ['refund_mode', 'tax_type', 'refund_date']
    search_fields = ['refund_number', 'customer__name', 'receipt_voucher__voucher_number']
    readonly_fields = ['refund_number', 'tax_type', 'gst_rate', 'cgst_amount', 
                      'sgst_amount', 'igst_amount', 'total_refund', 'created_at', 'updated_at']
    date_hierarchy = 'refund_date'
    
    fieldsets = (
        ('Refund Information', {
            'fields': ('tenant', 'refund_number', 'refund_date', 'receipt_voucher', 'customer')
        }),
        ('Refund Amount', {
            'fields': ('refund_amount', 'gst_rate', 'tax_type', 'cgst_amount', 
                      'sgst_amount', 'igst_amount', 'total_refund')
        }),
        ('Refund Details', {
            'fields': ('refund_mode', 'transaction_reference', 'reason')
        }),
        ('Additional', {
            'fields': ('notes',),
            'classes': ('collapse',)
        }),
        ('Audit', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        readonly = list(self.readonly_fields)
        if obj:
            readonly.extend(['tenant', 'receipt_voucher', 'customer', 'refund_amount'])
        return readonly
    
    def save_model(self, request, obj, form, change):
        if not change:
            obj.tenant = request.user.tenant
            obj.created_by = request.user
        super().save_model(request, obj, form, change)