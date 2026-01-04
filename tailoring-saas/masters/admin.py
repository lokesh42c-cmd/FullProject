"""
Django Admin configuration for masters app
"""
from django.contrib import admin
from django.utils.html import format_html
from .models import ItemCategory, Unit, MeasurementField, TenantMeasurementConfig,ServiceItem


@admin.register(ItemCategory)
class ItemCategoryAdmin(admin.ModelAdmin):
    """Admin interface for Item Categories"""
    list_display = ['name', 'category_type','default_hsn_code','tenant_display', 'is_system_wide', 'is_active', 'display_order']
    list_filter = ['category_type', 'is_system_wide', 'is_active', 'tenant']
    search_fields = ['name', 'description','default_hsn_code']
    ordering = ['category_type', 'display_order', 'name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'category_type', 'description', 'default_hsn_code','display_order')
        }),
        ('Tenant & System', {
            'fields': ('tenant', 'is_system_wide', 'is_active'),
            'description': 'Leave tenant blank and check is_system_wide for Super Admin categories'
        }),
    )
    
    def tenant_display(self, obj):
        """Display tenant or System"""
        if obj.is_system_wide:
            return format_html('<strong style="color: green;">SYSTEM</strong>')
        elif obj.tenant:
            return obj.tenant.name
        return '-'
    tenant_display.short_description = 'Tenant'


@admin.register(Unit)
class UnitAdmin(admin.ModelAdmin):
    """Admin interface for Units"""
    list_display = ['name', 'symbol', 'is_active', 'display_order']
    list_filter = ['is_active']
    search_fields = ['name', 'symbol']
    ordering = ['display_order', 'name']


@admin.register(MeasurementField)
class MeasurementFieldAdmin(admin.ModelAdmin):
    """Admin interface for Measurement Fields"""
    list_display = [
        'field_label', 'category', 'field_type', 'tenant_display', 
        'is_system_wide', 'is_required', 'display_order'
    ]
    list_filter = ['field_type', 'is_system_wide', 'is_required', 'category__category_type', 'tenant']
    search_fields = ['field_name', 'field_label', 'category__name']
    ordering = ['category', 'display_order', 'field_name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('category', 'field_name', 'field_label', 'field_type', 'help_text', 'display_order')
        }),
        ('Units (for NUMBER fields)', {
            'fields': ('unit_options', 'default_unit'),
            'classes': ('collapse',)
        }),
        ('Dropdown Options (for DROPDOWN fields)', {
            'fields': ('dropdown_options',),
            'classes': ('collapse',)
        }),
        ('Validation', {
            'fields': ('is_required', 'min_value', 'max_value')
        }),
        ('Tenant & System', {
            'fields': ('tenant', 'is_system_wide', 'is_active'),
            'description': 'Leave tenant blank and check is_system_wide for Super Admin fields'
        }),
    )
    
    def tenant_display(self, obj):
        """Display tenant or System"""
        if obj.is_system_wide:
            return format_html('<strong style="color: green;">SYSTEM</strong>')
        elif obj.tenant:
            return obj.tenant.name
        return '-'
    tenant_display.short_description = 'Tenant'



@admin.register(ServiceItem)
class ServiceItemAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'service_category', 'default_price', 'tax_rate',
        'is_active', 'is_system_wide', 'tenant', 'created_at'
    ]
    list_filter = ['service_category', 'is_active', 'is_system_wide', 'tenant']
    search_fields = ['name', 'description']
    ordering = ['service_category', 'display_order', 'name']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'service_category')
        }),
        ('Tenant & Access', {
            'fields': ('tenant', 'is_system_wide', 'is_active')
        }),
        ('Pricing', {
            'fields': ('default_price', 'min_price', 'max_price', 'unit')
        }),
        ('Tax & Compliance', {
            'fields': ('tax_rate', 'hsn_code')
        }),
        ('Operational', {
            'fields': ('estimated_days', 'display_order', 'notes')
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        # Non-superusers see only their tenant's services
        if hasattr(request.user, 'tenant') and request.user.tenant:
            return qs.filter(tenant=request.user.tenant)
        return qs.none()
    
@admin.register(TenantMeasurementConfig)
class TenantMeasurementConfigAdmin(admin.ModelAdmin):
    """Admin interface for Tenant Measurement Configs"""
    list_display = [
        'tenant', 'measurement_field', 'is_visible', 
        'custom_label_display', 'is_required'
    ]
    list_filter = ['is_visible', 'tenant', 'measurement_field__category']
    search_fields = ['tenant__name', 'measurement_field__field_label', 'custom_label']
    
    fieldsets = (
        ('Configuration', {
            'fields': ('tenant', 'measurement_field', 'is_visible')
        }),
        ('Customization', {
            'fields': ('custom_label', 'custom_help_text', 'is_required', 'display_order')
        }),
    )
    
    def custom_label_display(self, obj):
        """Show custom label if set"""
        if obj.custom_label:
            return format_html('<em>{}</em>', obj.custom_label)
        return '-'
    custom_label_display.short_description = 'Custom Label'
