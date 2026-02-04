"""
Financials app serializers - Financial API serializers
Date: 2026-01-27
PERMANENT FIX: Dynamic validation + flexible field names
"""

from rest_framework import serializers
from .models import ReceiptVoucher, Payment, RefundVoucher, PaymentRefund
from decimal import Decimal
from datetime import datetime

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
    """Serializer for creating receipt vouchers - FLEXIBLE FIELD NAMES"""
    
    # ✅ Accept both 'amount' and 'advance_amount' for backward compatibility
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, write_only=True)
    receipt_date = serializers.DateField()
    #customer = serializers.CharField(source='customer.name', read_only=True)
    class Meta:
        model = ReceiptVoucher
        fields = [
            'order', 'receipt_date', 'advance_amount', 'amount', 'gst_rate',
            'payment_mode', 'transaction_reference', 'notes'
        ]
    
    def validate(self, data):
        """Accept either 'amount' or 'advance_amount'"""
        if 'amount' in data and 'advance_amount' not in data:
            data['advance_amount'] = data.pop('amount')
        elif 'amount' in data:
            # Both provided, remove 'amount'
            data.pop('amount')
        if 'receipt_date' in data and hasattr(data['receipt_date'], 'date'):
            if isinstance(data['payment_date'], datetime):
                data['receipt_date'] = data['payment_date'].date()
        
        # If order provided, auto-populate customer
        order_instance = data.get('order')
        if order_instance and 'customer' not in data:
            # We can access the customer directly from the order instance
            data['customer'] = order_instance.customer

        return data


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


class PaymentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating payments - DYNAMIC VALIDATION"""
    
    class Meta:
        model = Payment
        fields = [
            'invoice', 'payment_date', 'amount', 'payment_mode',
            'transaction_reference', 'notes'
        ]
    
    def validate_amount(self, value):
        """✅ FIXED: Validate payment amount using DYNAMIC balance calculation"""
        invoice_id = self.initial_data.get('invoice')
        if invoice_id:
            from invoicing.models import Invoice
            from financials.models import ReceiptVoucher, Payment as PaymentModel, RefundVoucher
            
            try:
                invoice = Invoice.objects.get(pk=invoice_id)
                
                # ✅ Calculate dynamic remaining balance
                grand_total = invoice.grand_total
                
                # Get advances (minus refunds)
                advances = Decimal('0.00')
                if invoice.order:
                    receipts = ReceiptVoucher.objects.filter(order=invoice.order, tenant=invoice.tenant)
                    for receipt in receipts:
                        advances += receipt.total_amount
                    
                    # Subtract refunds
                    refunds = RefundVoucher.objects.filter(receipt_voucher__order=invoice.order, tenant=invoice.tenant)
                    for refund in refunds:
                        advances -= refund.total_refund
                
                # Get invoice payments
                payments = PaymentModel.objects.filter(invoice=invoice, tenant=invoice.tenant)
                invoice_payments = sum(p.amount for p in payments)
                
                # Calculate dynamic remaining balance
                remaining = grand_total - advances - invoice_payments
                
                if value > remaining:
                    raise serializers.ValidationError(
                        f"Payment amount (₹{value}) exceeds remaining balance (₹{remaining})"
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


# ==================== PAYMENT REFUND SERIALIZERS ====================

class PaymentRefundListSerializer(serializers.ModelSerializer):
    """Lightweight payment refund serializer for lists"""
    
    payment_number = serializers.CharField(source='payment.payment_number', read_only=True)
    invoice_number = serializers.CharField(source='invoice.invoice_number', read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    refund_mode_display = serializers.CharField(source='refund_mode_display', read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = PaymentRefund
        fields = [
            'id', 'refund_number', 'refund_date', 'payment', 'payment_number',
            'invoice', 'invoice_number', 'customer', 'customer_name',
            'refund_amount', 'refund_mode', 'refund_mode_display',
            'created_by_name', 'created_at'
        ]


class PaymentRefundDetailSerializer(serializers.ModelSerializer):
    """Detailed payment refund serializer"""
    
    payment_number = serializers.CharField(source='payment.payment_number', read_only=True)
    invoice_number = serializers.CharField(source='invoice.invoice_number', read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    refund_mode_display = serializers.CharField(source='refund_mode_display', read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = PaymentRefund
        fields = [
            'id', 'refund_number', 'refund_date', 'payment', 'payment_number',
            'invoice', 'invoice_number', 'customer', 'customer_name',
            'refund_amount', 'refund_mode', 'refund_mode_display',
            'transaction_reference', 'reason', 'notes',
            'created_by', 'created_by_name', 'created_at', 'updated_at'
        ]


class PaymentRefundCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating payment refunds"""
    
    class Meta:
        model = PaymentRefund
        fields = [
            'payment', 'refund_date', 'refund_amount', 'refund_mode',
            'transaction_reference', 'reason', 'notes'
        ]
    
    def validate_refund_amount(self, value):
        """Validate refund amount"""
        if value <= 0:
            raise serializers.ValidationError("Refund amount must be greater than zero")
        return value
    
    def validate_reason(self, value):
        """Validate reason is provided"""
        if not value or not value.strip():
            raise serializers.ValidationError("Reason for refund is required")
        if len(value.strip()) < 10:
            raise serializers.ValidationError("Reason must be at least 10 characters")
        return value.strip()
    
    def validate(self, data):
        """Cross-field validation"""
        payment = data.get('payment')
        refund_amount = data.get('refund_amount')
        
        if payment and refund_amount:
            # Check if refund amount exceeds available amount
            existing_refunds = PaymentRefund.objects.filter(payment=payment)
            
            # Exclude current instance if updating
            if self.instance:
                existing_refunds = existing_refunds.exclude(id=self.instance.id)
            
            total_refunded = sum(r.refund_amount for r in existing_refunds)
            max_refundable = payment.amount - total_refunded
            
            if refund_amount > max_refundable:
                raise serializers.ValidationError({
                    'refund_amount': f"Refund amount (₹{refund_amount}) exceeds available amount (₹{max_refundable})"
                })
        
        return data
    
    def create(self, validated_data):
        """Create payment refund with auto-set fields"""
        # Set tenant from request user
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['tenant'] = request.user.tenant
            validated_data['created_by'] = request.user
        
        # Auto-set invoice and customer from payment
        payment = validated_data.get('payment')
        if payment:
            validated_data['invoice'] = payment.invoice
            validated_data['customer'] = payment.invoice.customer
        
        return super().create(validated_data)


# ==================== UPDATED PAYMENT SERIALIZERS ====================
# Add refund information to existing Payment serializers

class PaymentDetailSerializer(serializers.ModelSerializer):
    """Detailed payment serializer with refund information"""
    
    invoice_number = serializers.CharField(source='invoice.invoice_number', read_only=True)
    customer_name = serializers.CharField(source='invoice.customer.name', read_only=True)
    payment_mode_display = serializers.CharField(source='get_payment_mode_display', read_only=True)
    
    # ✅ Add refund-related fields
    total_refunded = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    refundable_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    is_fully_refunded = serializers.BooleanField(read_only=True)
    refunds = PaymentRefundListSerializer(many=True, read_only=True)
    
    class Meta:
        model = Payment
        fields = [
            'id', 'payment_number', 'payment_date', 'invoice', 'invoice_number',
            'customer_name', 'amount', 'payment_mode', 'payment_mode_display',
            'transaction_reference', 'deposited_to_bank', 'deposit_date',
            'notes', 'created_by', 'created_at', 'updated_at',
            # ✅ New refund fields
            'total_refunded', 'refundable_amount', 'is_fully_refunded', 'refunds'
        ]