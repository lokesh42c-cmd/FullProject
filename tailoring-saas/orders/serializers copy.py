"""
Orders app serializers - Complete with Inventory
Date: 2026-01-09
FIXED: Order number generation moved to serializer
FIXED v2: Tenant access from request.user.tenant
"""

from rest_framework import serializers
from .models import Customer, Order, OrderItem, Item
from masters.models import ItemUnit
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
            'id',
            'name', 'phone', 'whatsapp_number', 'email', 'gender',
            'customer_type', 'business_name', 'gstin', 'pan',
            'address_line1', 'address_line2', 'city', 'state', 'country', 'pincode',
            # All measurement fields
            'height', 'weight', 'shoulder_width', 'bust_chest', 'waist', 'hip',
            'shoulder', 'sleeve_length', 'armhole', 'garment_length',
            'front_neck_depth', 'back_neck_depth', 'upper_chest', 'under_bust', 
            'shoulder_to_apex', 'bust_point_distance', 'front_cross', 'back_cross', 
            'lehenga_length', 'pant_waist', 'ankle_opening',
            'neck_round', 'stomach_round', 'yoke_width', 'front_width', 'back_width',
            'trouser_waist', 'front_rise', 'back_rise', 'bottom_opening',
            'upper_arm_bicep', 'sleeve_loose', 'wrist_round', 'thigh', 'knee', 'ankle',
            'rise', 'inseam', 'outseam',
            'custom_field_1', 'custom_field_2', 'custom_field_3', 'custom_field_4',
            'custom_field_5', 'custom_field_6', 'custom_field_7', 'custom_field_8',
            'custom_field_9', 'custom_field_10',
            'measurement_notes', 'notes', 'is_active'
        ]
        read_only_fields = ['id']


# ==================== ITEM UNIT SERIALIZERS ====================

class ItemUnitSerializer(serializers.ModelSerializer):
    """Item Unit serializer"""
    
    class Meta:
        model = ItemUnit
        fields = [
            'id', 'name', 'code', 'is_active', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


# ==================== ITEM SERIALIZERS ====================

class ItemSerializer(serializers.ModelSerializer):
    """Item master serializer with full inventory support"""
    
    unit_name = serializers.CharField(source='unit.name', read_only=True)
    
    class Meta:
        model = Item
        fields = [
            'id', 'item_type', 'name', 'description',
            # Unit
            'unit', 'unit_name',
            # Stock Control
            'track_stock', 'allow_negative_stock',
            # Stock Fields
            'opening_stock', 'current_stock', 'min_stock_level',
            # Pricing
            'purchase_price', 'selling_price',
            # GST
            'hsn_sac_code', 'tax_percent',
            # Barcode
            'barcode',
            # Status
            'has_been_used', 'is_active', 'deleted_at',
            # Audit
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'current_stock', 'has_been_used', 'created_at', 'updated_at']


# ==================== ORDER ITEM SERIALIZERS ====================

class OrderItemSerializer(serializers.ModelSerializer):
    """Order item serializer with discount support"""
    
    item_name = serializers.CharField(source='item.name', read_only=True)
    item_barcode = serializers.CharField(source='item.barcode', read_only=True)
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    tax_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = OrderItem
        fields = [
            'id', 'item_type', 'item', 'item_name', 'item_barcode', 'item_description',
            'quantity', 'unit_price', 'discount', 'tax_percentage',
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
            'delivery_status', 'delivery_status_display','priority',
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
            'is_locked', 'is_overdue', 'days_until_delivery','priority',
            'items', 'created_by', 'updated_by', 'created_at', 'updated_at'
        ]


class OrderCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating orders"""
    
    items = OrderItemSerializer(many=True, required=False)
    
    class Meta:
        model = Order
        fields = [
            'customer', 'order_date', 'expected_delivery_date', 'actual_delivery_date',
            'order_status', 'delivery_status', 'estimated_total', 'payment_terms','priority',
            'order_summary', 'customer_instructions', 'items'
        ]
    
    def create(self, validated_data):
        from django.utils import timezone
        
        items_data = validated_data.pop('items', [])
        
        # ============ CRITICAL FIX #1 - v2 ============
        # Generate order_number HERE in serializer BEFORE save
        # FIXED: Get tenant from request.user.tenant instead of request.tenant
        if 'order_number' not in validated_data or not validated_data.get('order_number'):
            # Get tenant from user - this is the correct way for multi-tenant apps
            request = self.context.get('request')
            if request and hasattr(request.user, 'tenant'):
                tenant = request.user.tenant
            else:
                # Fallback: This shouldn't happen, but handle gracefully
                raise serializers.ValidationError("User tenant not found")
            
            year_month = timezone.now().strftime('%Y%m')
            
            # Get last order number for this tenant and month
            last_order = Order.objects.filter(
                tenant=tenant,
                order_number__startswith=f'ORD-{year_month}'
            ).order_by('-order_number').first()
            
            if last_order:
                try:
                    last_num = int(last_order.order_number.split('-')[-1])
                    new_num = last_num + 1
                except (ValueError, IndexError):
                    new_num = 1
            else:
                new_num = 1
            
            validated_data['order_number'] = f'ORD-{year_month}-{new_num:05d}'
        
        # These will be passed from the view's perform_create
        # Don't override them here - let the view handle it
        # The view calls: serializer.save(tenant=..., created_by=...)
        
        # Create order with generated order_number
        order = Order.objects.create(**validated_data)
        
        # Create order items
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
            instance.items.all().delete()
            for item_data in items_data:
                OrderItem.objects.create(order=instance, **item_data)
        
        return instance