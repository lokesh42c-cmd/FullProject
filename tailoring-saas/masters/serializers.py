"""
Serializers for masters app
"""
from rest_framework import serializers
from .models import ItemCategory, Unit, MeasurementField, TenantMeasurementConfig,ServiceItem
from core.models import Tenant
from rest_framework.validators import UniqueTogetherValidator
from .models import ItemUnit
''''''
class UnitSerializer(serializers.ModelSerializer):
    """Serializer for Units"""
    
    class Meta:
        model = Unit
        fields = ['id', 'name', 'symbol', 'display_order', 'is_active']


class ItemCategorySerializer(serializers.ModelSerializer):
    """Serializer for Item Categories"""
    category_type_display = serializers.CharField(source='get_category_type_display', read_only=True)
    is_custom = serializers.SerializerMethodField()
    
    class Meta:
        model = ItemCategory
        fields = [
            'id', 'name', 'category_type', 'category_type_display',
            'description', 'is_system_wide', 'is_custom', 
            'display_order', 'is_active', 'created_at'
        ]
        read_only_fields = ['is_system_wide', 'created_at']
    
    def get_is_custom(self, obj):
        """Check if this is a custom category (not system-wide)"""
        return not obj.is_system_wide
    
    def create(self, validated_data):
        """Create custom category for tenant"""
        # Get tenant from request context
        tenant = self.context['request'].user.tenant
        validated_data['tenant'] = tenant
        validated_data['is_system_wide'] = False
        return super().create(validated_data)


class MeasurementFieldSerializer(serializers.ModelSerializer):
    """Serializer for Measurement Fields"""
    category_name = serializers.CharField(source='category.name', read_only=True)
    field_type_display = serializers.CharField(source='get_field_type_display', read_only=True)
    is_custom = serializers.SerializerMethodField()
    
    # Configuration from TenantMeasurementConfig (if exists)
    config = serializers.SerializerMethodField()
    
    class Meta:
        model = MeasurementField
        fields = [
            'id', 'category', 'category_name', 'field_name', 'field_label',
            'field_type', 'field_type_display', 'unit_options', 'default_unit',
            'dropdown_options', 'is_required', 'min_value', 'max_value',
            'display_order', 'help_text', 'is_system_wide', 'is_custom',
            'is_active', 'config', 'created_at'
        ]
        read_only_fields = ['is_system_wide', 'created_at']
    
    def get_is_custom(self, obj):
        """Check if this is a custom field"""
        return not obj.is_system_wide
    
    def get_config(self, obj):
        """Get tenant-specific configuration if exists"""
        request = self.context.get('request')
        if request and request.user.tenant:
            try:
                config = TenantMeasurementConfig.objects.get(
                    tenant=request.user.tenant,
                    measurement_field=obj
                )
                return {
                    'is_visible': config.is_visible,
                    'custom_label': config.custom_label,
                    'custom_help_text': config.custom_help_text,
                    'is_required': config.is_required if config.is_required is not None else obj.is_required,
                    'display_order': config.display_order if config.display_order is not None else obj.display_order
                }
            except TenantMeasurementConfig.DoesNotExist:
                pass
        
        # Return default values
        return {
            'is_visible': True,
            'custom_label': None,
            'custom_help_text': None,
            'is_required': obj.is_required,
            'display_order': obj.display_order
        }
    
    def create(self, validated_data):
        """Create custom measurement field for tenant"""
        tenant = self.context['request'].user.tenant
        validated_data['tenant'] = tenant
        validated_data['is_system_wide'] = False
        return super().create(validated_data)


class TenantMeasurementConfigSerializer(serializers.ModelSerializer):
    """Serializer for Tenant Measurement Configuration"""
    measurement_field_name = serializers.CharField(source='measurement_field.field_label', read_only=True)
    category_name = serializers.CharField(source='measurement_field.category.name', read_only=True)
    
    class Meta:
        model = TenantMeasurementConfig
        fields = [
            'id', 'tenant', 'measurement_field', 'measurement_field_name',
            'category_name', 'is_visible', 'custom_label', 'custom_help_text',
            'is_required', 'display_order', 'created_at', 'updated_at'
        ]
        read_only_fields = ['tenant', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        """Create config for tenant"""
        validated_data['tenant'] = self.context['request'].user.tenant
        return super().create(validated_data)

# ========================================
# ADD THIS TO masters/serializers.py
# ========================================

class ServiceItemSerializer(serializers.ModelSerializer):
    """Serializer for Service Items"""
    service_category_display = serializers.CharField(
        source='get_service_category_display',
        read_only=True
    )
    unit_display = serializers.CharField(
        source='get_unit_display',
        read_only=True
    )
    is_custom = serializers.SerializerMethodField()
    price_display = serializers.CharField(read_only=True)
    
    class Meta:
        model = ServiceItem
        fields = [
            'id', 'name', 'description', 'service_category',
            'service_category_display', 'default_price', 'min_price',
            'max_price', 'price_display', 'unit', 'unit_display',
            'tax_rate', 'sac_code', 'is_active', 'estimated_days',
            'display_order', 'notes', 'is_system_wide', 'is_custom',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['is_system_wide', 'created_at', 'updated_at']
        validators = [
            UniqueTogetherValidator(
                queryset=ServiceItem.objects.all(),
                fields=['name', 'service_category'],
                message="A service with this name already exists in this category."
            )
        ]
    def get_is_custom(self, obj):
        """Check if this is a custom service (not system-wide)"""
        return not obj.is_system_wide
    
    def create(self, validated_data):
        """Create custom service for tenant"""
        # Get tenant from request context
        tenant = self.context['request'].user.tenant
        validated_data['tenant'] = tenant
        validated_data['is_system_wide'] = False
        return super().create(validated_data)
    
    def validate(self, data):
        """Validate price range"""
        min_price = data.get('min_price')
        max_price = data.get('max_price')
        
        if min_price and max_price and min_price > max_price:
            raise serializers.ValidationError({
                'min_price': 'Minimum price cannot be greater than maximum price'
            })
        
        return data
    
class CategoryWithMeasurementsSerializer(serializers.ModelSerializer):
    """Serializer that includes measurement fields for a category"""
    measurement_fields = serializers.SerializerMethodField()
    category_type_display = serializers.CharField(source='get_category_type_display', read_only=True)
    
    class Meta:
        model = ItemCategory
        fields = [
            'id', 'name', 'category_type', 'category_type_display',
            'description', 'measurement_fields'
        ]
    
    def get_measurement_fields(self, obj):
        """Get all measurement fields for this category (system + custom)"""
        request = self.context.get('request')
        tenant = request.user.tenant if request and request.user.tenant else None
        
        # Get system-wide fields
        system_fields = MeasurementField.objects.filter(
            category=obj,
            is_system_wide=True,
            is_active=True
        )
        
        # Get tenant custom fields
        if tenant:
            custom_fields = MeasurementField.objects.filter(
                category=obj,
                tenant=tenant,
                is_active=True
            )
            all_fields = list(system_fields) + list(custom_fields)
        else:
            all_fields = list(system_fields)
        
        # Apply tenant configuration (visibility, custom labels, etc.)
        filtered_fields = []
        for field in all_fields:
            # Check if tenant has hidden this field
            if tenant:
                try:
                    config = TenantMeasurementConfig.objects.get(
                        tenant=tenant,
                        measurement_field=field
                    )
                    if not config.is_visible:
                        continue  # Skip hidden fields
                except TenantMeasurementConfig.DoesNotExist:
                    pass
            
            filtered_fields.append(field)
        
        # Sort by display order
        filtered_fields.sort(key=lambda x: x.display_order)
        
        return MeasurementFieldSerializer(filtered_fields, many=True, context=self.context).data
    #this is used in ITEMS in order tables 

class ItemUnitSerializer(serializers.ModelSerializer):
        class Meta:
            model = ItemUnit
            fields = ['id', 'name', 'code', 'is_active']