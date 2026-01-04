"""
Financials app serializers - Financial API serializers
Date: 2026-01-03
"""

from rest_framework import serializers
from .models import ReceiptVoucher, Payment, RefundVoucher
from decimal import Decimal


# ==================== RECEIPT VOUCHER SERIALIZERS ====================

class ReceiptVoucherListSerializer(serializers.ModelSerializer):
    """Lightweight receipt voucher serializer for lists"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    payment_mode_display = serializers.CharField(source='get_payment_mode_display', read_only=True)
    
    class Meta:
        model = ReceiptVoucher
        fields = [
            'id', 'voucher_number', 'receipt_date', 'customer', 'customer_name',
            'order', 'order_number', 'advance_amount', 'total_amount',
            'payment_mode', 'payment_mode_display', 'is_adjusted',
            'remaining_amount', 'created_at'
        ]


class ReceiptVoucherDetailSerializer(serializers.ModelSerializer):
    """Detailed receipt voucher serializer"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    payment_mode_display = serializers.CharField(source='get_payment_mode_display', read_only=True)
    tax_type_display = serializers.CharField(source='get_tax_type_display', read_only=True)
    
    class Meta:
        model = ReceiptVoucher
        fields = [
            'id', 'voucher_number', 'receipt_date', 'customer', 'customer_name',
            'customer_phone', 'order', 'order_number',
            'advance_amount', 'gst_rate', 'tax_type', 'tax_type_display',
            'cgst_amount', 'sgst_amount', 'igst_amount', 'total_amount',
            'payment_mode', 'payment_mode_display', 'transaction_reference',
            'deposited_to_bank', 'deposit_date',
            'is_adjusted', 'adjusted_amount', 'remaining_amount',
            'notes', 'is_issued', 'created_by', 'created_at', 'updated_at'
        ]


class ReceiptVoucherCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating receipt vouchers"""
    
    class Meta:
        model = ReceiptVoucher
        fields = [
            'customer', 'order', 'receipt_date', 'advance_amount', 'gst_rate',
            'payment_mode', 'transaction_reference', 'notes'
        ]


# ==================== PAYMENT SERIALIZERS ====================

class PaymentListSerializer(serializers.ModelSerializer):
    """Lightweight payment serializer for lists"""
    
    invoice_number = serializers.CharField(source='invoice.invoice_number', read_only=True)
    customer_name = serializers.CharField(source='invoice.customer.name', read_only=True)
    payment_mode_display = serializers.CharField(source='get_payment_mode_display', read_only=True)
    
    class Meta:
        model = Payment
        fields = [
            'id', 'payment_number', 'payment_date', 'invoice', 'invoice_number',
            'customer_name', 'amount', 'payment_mode', 'payment_mode_display',
            'deposited_to_bank', 'created_at'
        ]


class PaymentDetailSerializer(serializers.ModelSerializer):
    """Detailed payment serializer"""
    
    invoice_number = serializers.CharField(source='invoice.invoice_number', read_only=True)
    customer_name = serializers.CharField(source='invoice.customer.name', read_only=True)
    payment_mode_display = serializers.CharField(source='get_payment_mode_display', read_only=True)
    
    class Meta:
        model = Payment
        fields = [
            'id', 'payment_number', 'payment_date', 'invoice', 'invoice_number',
            'customer_name', 'amount', 'payment_mode', 'payment_mode_display',
            'transaction_reference', 'deposited_to_bank', 'deposit_date',
            'notes', 'created_by', 'created_at', 'updated_at'
        ]


class PaymentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating payments"""
    
    class Meta:
        model = Payment
        fields = [
            'invoice', 'payment_date', 'amount', 'payment_mode',
            'transaction_reference', 'notes'
        ]
    
    def validate_amount(self, value):
        """Validate payment amount doesn't exceed invoice balance"""
        invoice = self.initial_data.get('invoice')
        if invoice:
            from invoicing.models import Invoice
            try:
                invoice_obj = Invoice.objects.get(pk=invoice)
                if value > invoice_obj.remaining_balance:
                    raise serializers.ValidationError(
                        f"Payment amount (₹{value}) exceeds remaining balance (₹{invoice_obj.remaining_balance})"
                    )
            except Invoice.DoesNotExist:
                pass
        return value


# ==================== REFUND VOUCHER SERIALIZERS ====================

class RefundVoucherListSerializer(serializers.ModelSerializer):
    """Lightweight refund voucher serializer for lists"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    receipt_voucher_number = serializers.CharField(source='receipt_voucher.voucher_number', read_only=True)
    refund_mode_display = serializers.CharField(source='get_refund_mode_display', read_only=True)
    
    class Meta:
        model = RefundVoucher
        fields = [
            'id', 'refund_number', 'refund_date', 'customer', 'customer_name',
            'receipt_voucher', 'receipt_voucher_number', 'refund_amount',
            'total_refund', 'refund_mode', 'refund_mode_display', 'created_at'
        ]


class RefundVoucherDetailSerializer(serializers.ModelSerializer):
    """Detailed refund voucher serializer"""
    
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    receipt_voucher_number = serializers.CharField(source='receipt_voucher.voucher_number', read_only=True)
    refund_mode_display = serializers.CharField(source='get_refund_mode_display', read_only=True)
    tax_type_display = serializers.CharField(source='get_tax_type_display', read_only=True)
    
    class Meta:
        model = RefundVoucher
        fields = [
            'id', 'refund_number', 'refund_date', 'receipt_voucher',
            'receipt_voucher_number', 'customer', 'customer_name',
            'refund_amount', 'gst_rate', 'tax_type', 'tax_type_display',
            'cgst_amount', 'sgst_amount', 'igst_amount', 'total_refund',
            'refund_mode', 'refund_mode_display', 'transaction_reference',
            'reason', 'notes', 'created_by', 'created_at', 'updated_at'
        ]


class RefundVoucherCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating refund vouchers"""
    
    class Meta:
        model = RefundVoucher
        fields = [
            'receipt_voucher', 'customer', 'refund_date', 'refund_amount',
            'refund_mode', 'transaction_reference', 'reason', 'notes'
        ]
    
    def validate_refund_amount(self, value):
        """Validate refund amount doesn't exceed receipt voucher amount"""
        receipt_voucher = self.initial_data.get('receipt_voucher')
        if receipt_voucher:
            from .models import ReceiptVoucher
            try:
                rv = ReceiptVoucher.objects.get(pk=receipt_voucher)
                if value > rv.total_amount:
                    raise serializers.ValidationError(
                        f"Refund amount (₹{value}) exceeds receipt amount (₹{rv.total_amount})"
                    )
            except ReceiptVoucher.DoesNotExist:
                pass
        return value
