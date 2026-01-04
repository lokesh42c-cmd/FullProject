"""
Orders app serializers - Simplified for GST Compliance
Date: 2026-01-03
"""

from rest_framework import serializers
from .models import Customer, Order, OrderItem, Item
from decimal import Decimal


# ==================== CUSTOMER SERIALIZERS ====================

class CustomerListSerializer(serializers.ModelSerializer):
    """Lightweight customer serializer for lists"""
    
    total_orders = serializers.SerializerMethodField()
    
    class Meta:
        model = Customer
        fields = [
            'id', 'name', 'phone', 'whatsapp_number', 'email',
            'customer_type', 'business_name', 'gstin', 'gender',
            'city', 'state', 'is_active', 'created_at', 'total_orders'
        ]
    
    def get_total_orders(self, obj):
        return obj.orders.count()


class CustomerDetailSerializer(serializers.ModelSerializer):
    """Detailed customer serializer with measurements"""
    
    total_orders = serializers.SerializerMethodField()
    
    class Meta:
        model = Customer
        fields = [
            'id', 'name', 'phone', 'whatsapp_number', 'email', 'gender',
            'customer_type', 'business_name', 'gstin', 'pan',
            'address_line1', 'address_line2', 'city', 'state', 'country', 'pincode',
            # Basic & Common Measurements
            'height', 'weight', 'shoulder_width', 'bust_chest', 'waist', 'hip',
            'shoulder', 'sleeve_length', 'armhole', 'garment_length',
            # Women-Specific Measurements
            'front_neck_depth', 'back_neck_depth', 'upper_chest', 'under_bust', 
            'shoulder_to_apex', 'bust_point_distance', 'front_cross', 'back_cross', 
            'lehenga_length', 'pant_waist', 'ankle_opening',
            # Men-Specific Measurements
            'neck_round', 'stomach_round', 'yoke_width', 'front_width', 'back_width',
            'trouser_waist', 'front_rise', 'back_rise', 'bottom_opening',
            # Sleeves & Legs Measurements
            'upper_arm_bicep', 'sleeve_loose', 'wrist_round', 'thigh', 'knee', 'ankle',
            'rise', 'inseam', 'outseam',
            # Custom Fields
            'custom_field_1', 'custom_field_2', 'custom_field_3', 'custom_field_4',
            'custom_field_5', 'custom_field_6', 'custom_field_7', 'custom_field_8',
            'custom_field_9', 'custom_field_10',
            'measurement_notes',
            # Meta
            'notes', 'is_active', 'created_at', 'updated_at', 'total_orders'
        ]
    
    def get_total_orders(self, obj):
        return obj.orders.count()


class CustomerCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating customers"""
    
    class Meta:
        model = Customer
        fields = [
            'id',  # ✅ ADDED - Required for Flutter to get customer ID
            'name', 'phone', 'whatsapp_number', 'email', 'gender',
            'customer_type', 'business_name', 'gstin', 'pan',
            'address_line1', 'address_line2', 'city', 'state', 'country', 'pincode',
            # Basic & Common Measurements
            'height', 'weight', 'shoulder_width', 'bust_chest', 'waist', 'hip',
            'shoulder', 'sleeve_length', 'armhole', 'garment_length',
            # Women-Specific Measurements
            'front_neck_depth', 'back_neck_depth', 'upper_chest', 'under_bust', 
            'shoulder_to_apex', 'bust_point_distance', 'front_cross', 'back_cross', 
            'lehenga_length', 'pant_waist', 'ankle_opening',
            # Men-Specific Measurements
            'neck_round', 'stomach_round', 'yoke_width', 'front_width', 'back_width',
            'trouser_waist', 'front_rise', 'back_rise', 'bottom_opening',
            # Sleeves & Legs Measurements
            'upper_arm_bicep', 'sleeve_loose', 'wrist_round', 'thigh', 'knee', 'ankle',
            'rise', 'inseam', 'outseam',
            # Custom Fields
            'custom_field_1', 'custom_field_2', 'custom_field_3', 'custom_field_4',
            'custom_field_5', 'custom_field_6', 'custom_field_7', 'custom_field_8',
            'custom_field_9', 'custom_field_10',
            'measurement_notes', 'notes', 'is_active'
        ]
        read_only_fields = ['id']  # ✅ ADDED - ID is auto-generated

# ==================== ORDER ITEM SERIALIZERS ====================

class OrderItemSerializer(serializers.ModelSerializer):
    """Order item serializer"""
    
    item_name = serializers.CharField(source='item.name', read_only=True)
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    tax_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = OrderItem
        fields = [
            'id', 'item_type', 'item', 'item_name', 'item_description',
            'quantity', 'unit_price', 'tax_percentage',
            'subtotal', 'tax_amount', 'total_price',
            'status', 'notes'
        ]


# ==================== ORDER SERIALIZERS ====================

class OrderListSerializer(serializers.ModelSerializer):
    """Lightweight order serializer for lists"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    order_status_display = serializers.CharField(source='get_order_status_display', read_only=True)
    delivery_status_display = serializers.CharField(source='get_delivery_status_display', read_only=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'customer', 'customer_name', 'customer_phone',
            'order_date', 'expected_delivery_date', 'actual_delivery_date',
            'order_status', 'order_status_display',
            'delivery_status', 'delivery_status_display',
            'estimated_total', 'is_locked', 'created_at'
        ]


class OrderDetailSerializer(serializers.ModelSerializer):
    """Detailed order serializer with items"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    items = OrderItemSerializer(many=True, read_only=True)
    order_status_display = serializers.CharField(source='get_order_status_display', read_only=True)
    delivery_status_display = serializers.CharField(source='get_delivery_status_display', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    days_until_delivery = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'customer', 'customer_name', 'customer_phone',
            'order_date', 'expected_delivery_date', 'actual_delivery_date',
            'order_status', 'order_status_display',
            'delivery_status', 'delivery_status_display',
            'estimated_total', 'payment_terms',
            'order_summary', 'customer_instructions',
            'is_locked', 'is_overdue', 'days_until_delivery',
            'items', 'created_by', 'updated_by', 'created_at', 'updated_at'
        ]


class OrderCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating orders"""
    
    items = OrderItemSerializer(many=True, required=False)
    
    class Meta:
        model = Order
        fields = [
            'customer', 'order_date', 'expected_delivery_date',
            'order_status', 'estimated_total', 'payment_terms',
            'order_summary', 'customer_instructions', 'items'
        ]
    
    def create(self, validated_data):
        items_data = validated_data.pop('items', [])
        order = Order.objects.create(**validated_data)
        
        for item_data in items_data:
            OrderItem.objects.create(order=order, **item_data)
        
        return order
    
    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        
        # Update order fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update items if provided
        if items_data is not None:
            # Delete existing items
            instance.items.all().delete()
            # Create new items
            for item_data in items_data:
                OrderItem.objects.create(order=instance, **item_data)
        
        return instance


# ==================== ITEM SERIALIZERS ====================

class ItemSerializer(serializers.ModelSerializer):
    """Item master serializer"""
    
    unit_name = serializers.CharField(source='unit.name', read_only=True)
    
    class Meta:
        model = Item
        fields = [
            'id', 'item_type', 'name', 'description',
            'unit', 'unit_name', 'hsn_sac_code',
            'price', 'tax_percent', 'is_active', 'created_at'
        ]


# ==================== DEPRECATED SERIALIZERS (COMMENTED OUT) ====================

"""
# OLD FAMILY MEMBER SERIALIZERS
class FamilyMemberSerializer(serializers.ModelSerializer):
    pass

class FamilyMemberMeasurementSerializer(serializers.ModelSerializer):
    pass

# OLD INVOICE/PAYMENT SERIALIZERS
class InvoiceSerializer(serializers.ModelSerializer):
    pass

class OrderPaymentSerializer(serializers.ModelSerializer):
    pass
"""