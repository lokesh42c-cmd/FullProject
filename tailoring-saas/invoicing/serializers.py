"""
Invoicing app serializers - Invoice API serializers
Date: 2026-01-03
"""

from rest_framework import serializers
from .models import Invoice, InvoiceItem
from decimal import Decimal


# ==================== INVOICE ITEM SERIALIZERS ====================

class InvoiceItemSerializer(serializers.ModelSerializer):
    """Invoice item serializer with calculated fields"""
    
    item_name = serializers.CharField(source='item.name', read_only=True)
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
            'item_type', 'quantity', 'unit_price', 'gst_rate',
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
    """Serializer for creating/updating invoices"""
    
    items = InvoiceItemSerializer(many=True, required=False)
    
    class Meta:
        model = Invoice
        fields = [
            'customer', 'order', 'invoice_date', 'status',
            'billing_name', 'billing_address', 'billing_city', 'billing_state',
            'billing_pincode', 'billing_gstin',
            'shipping_name', 'shipping_address', 'shipping_city', 'shipping_state',
            'shipping_pincode',
            'notes', 'terms_and_conditions', 'items'
        ]
    
    def create(self, validated_data):
        items_data = validated_data.pop('items', [])
        invoice = Invoice.objects.create(**validated_data)
        
        for item_data in items_data:
            InvoiceItem.objects.create(invoice=invoice, **item_data)
        
        # Calculate totals
        invoice.calculate_totals()
        
        return invoice
    
    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        
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
                InvoiceItem.objects.create(invoice=instance, **item_data)
        
        # Recalculate totals
        instance.calculate_totals()
        
        return instance