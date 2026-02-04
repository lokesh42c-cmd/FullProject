"""
Invoicing app serializers - Invoice API serializers + DISCOUNT SUPPORT
Date: 2026-02-02
UPDATED: Made GST fields writable to accept frontend calculations
"""

from rest_framework import serializers
from .models import Invoice, InvoiceItem
from decimal import Decimal


# ==================== INVOICE ITEM SERIALIZERS ====================

class InvoiceItemSerializer(serializers.ModelSerializer):
    """Invoice item serializer with calculated fields + discount support"""
    
    item_name = serializers.CharField(source='item.name', read_only=True)
    # ✅ These are @property fields in the model, keep them read_only
    # Frontend sends them, but we don't save them - model calculates them
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    cgst_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    sgst_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    igst_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_tax = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = InvoiceItem
        fields = [
            'id', 'item', 'item_name', 'item_description', 'hsn_sac_code',
            'item_type', 'quantity', 'unit_price', 'discount', 'gst_rate',
            'subtotal', 'cgst_amount', 'sgst_amount', 'igst_amount',
            'total_tax', 'total_amount'
        ]


# ==================== INVOICE SERIALIZERS ====================

class InvoiceListSerializer(serializers.ModelSerializer):
    """Lightweight invoice serializer for lists"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    
    class Meta:
        model = Invoice
        fields = [
            'id', 'invoice_number', 'invoice_date', 'customer', 'customer_name',
            'order', 'order_number', 'status', 'status_display',
            'payment_status', 'payment_status_display',
            'grand_total', 'balance_due', 'remaining_balance', 'created_at'
        ]


class InvoiceDetailSerializer(serializers.ModelSerializer):
    """Detailed invoice serializer with items"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    items = InvoiceItemSerializer(many=True, read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    tax_type_display = serializers.CharField(source='get_tax_type_display', read_only=True)
    
    class Meta:
        model = Invoice
        fields = [
            'id', 'invoice_number', 'invoice_date', 'customer', 'customer_name', 
            'customer_phone', 'order', 'order_number', 'status', 'status_display',
            'billing_name', 'billing_address', 'billing_city', 'billing_state',
            'billing_pincode', 'billing_gstin',
            'shipping_name', 'shipping_address', 'shipping_city', 'shipping_state',
            'shipping_pincode',
            'tax_type', 'tax_type_display',
            'subtotal', 'total_cgst', 'total_sgst', 'total_igst', 'grand_total',
            'total_advance_adjusted', 'balance_due', 'total_paid', 'remaining_balance',
            'payment_status', 'payment_status_display',
            'notes', 'terms_and_conditions',
            'items', 'created_by', 'created_at', 'updated_at'
        ]


class InvoiceCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating invoices - USES MODEL PROPERTIES FOR GST"""
    
    items = InvoiceItemSerializer(many=True, required=False)
    
    # ✅ Accept totals from frontend but DON'T save them (model calculates via calculate_totals())
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, write_only=True)
    total_cgst = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, write_only=True)
    total_sgst = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, write_only=True)
    total_igst = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, write_only=True)
    grand_total = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, write_only=True)
    
    class Meta:
        model = Invoice
        fields = [
            'customer', 'order', 'invoice_date', 'status', 'tax_type',
            'billing_name', 'billing_address', 'billing_city', 'billing_state',
            'billing_pincode', 'billing_gstin',
            'shipping_name', 'shipping_address', 'shipping_city', 'shipping_state',
            'shipping_pincode',
            'notes', 'terms_and_conditions', 'items',
            # Accept but don't save (write_only)
            'subtotal', 'total_cgst', 'total_sgst', 'total_igst', 'grand_total'
        ]
    
    def create(self, validated_data):
        items_data = validated_data.pop('items', [])
        order = validated_data.get('order')
        
        # ✅ Remove frontend totals (we'll calculate via model properties)
        validated_data.pop('subtotal', None)
        validated_data.pop('total_cgst', None)
        validated_data.pop('total_sgst', None)
        validated_data.pop('total_igst', None)
        validated_data.pop('grand_total', None)
        
        invoice = Invoice.objects.create(**validated_data)
        
        # ✅ AUTO-COPY ITEMS FROM ORDER (with discount support)
        if order and not items_data:
            from orders.models import OrderItem
            
            order_items = OrderItem.objects.filter(order=order)
            for order_item in order_items:
                # Get GST rate from item master
                gst_rate = Decimal('0.00')
                if order_item.item and hasattr(order_item.item, 'tax_percent'):
                    gst_rate = order_item.item.tax_percent
                
                # Get HSN/SAC code from item master
                hsn_sac = ''
                if order_item.item and hasattr(order_item.item, 'hsn_sac_code'):
                    hsn_sac = order_item.item.hsn_sac_code or ''
                
                # Get discount from order item
                discount = Decimal('0.00')
                if hasattr(order_item, 'discount'):
                    discount = order_item.discount or Decimal('0.00')
                
                InvoiceItem.objects.create(
                    invoice=invoice,
                    item=order_item.item,
                    item_description=order_item.item_description,
                    hsn_sac_code=hsn_sac,
                    quantity=order_item.quantity,
                    unit_price=order_item.unit_price,
                    discount=discount,
                    gst_rate=gst_rate,
                    item_type='SERVICE'
                )
        else:
            # ✅ Manual items from frontend (walk-in invoice)
            # Save only the base fields, not the calculated ones
            for item_data in items_data:
                # Remove calculated fields (they're @property in model)
                item_data.pop('subtotal', None)
                item_data.pop('cgst_amount', None)
                item_data.pop('sgst_amount', None)
                item_data.pop('igst_amount', None)
                item_data.pop('total_tax', None)
                item_data.pop('total_amount', None)
                
                InvoiceItem.objects.create(invoice=invoice, **item_data)
        
        # ✅ Calculate totals using model's @property methods
        invoice.calculate_totals()
        
        return invoice
    
    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        
        # ✅ Remove frontend totals
        validated_data.pop('subtotal', None)
        validated_data.pop('total_cgst', None)
        validated_data.pop('total_sgst', None)
        validated_data.pop('total_igst', None)
        validated_data.pop('grand_total', None)
        
        # Update invoice fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update items if provided
        if items_data is not None:
            # Delete existing items
            instance.items.all().delete()
            # Create new items
            for item_data in items_data:
                # Remove calculated fields
                item_data.pop('subtotal', None)
                item_data.pop('cgst_amount', None)
                item_data.pop('sgst_amount', None)
                item_data.pop('igst_amount', None)
                item_data.pop('total_tax', None)
                item_data.pop('total_amount', None)
                
                InvoiceItem.objects.create(invoice=instance, **item_data)
        
        # Recalculate totals
        instance.calculate_totals()
        
        return instance