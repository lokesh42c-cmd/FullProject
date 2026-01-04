"""
Purchase Management Serializers
Complete serializers following TailorPro standards
"""

from rest_framework import serializers
from decimal import Decimal
from .models import Vendor, PurchaseBill, Expense, Payment


# ==================== VENDOR SERIALIZERS ====================

class VendorListSerializer(serializers.ModelSerializer):
    """Lightweight vendor serializer for lists"""
    
    total_bills = serializers.IntegerField(read_only=True)
    has_outstanding = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Vendor
        fields = [
            'id', 'name', 'phone', 'alternate_phone', 'email',
            'business_name', 'gstin', 'pan',
            'address_line1', 'city', 'state', 'pincode',
            'total_purchases', 'total_paid', 'outstanding_balance',
            'total_bills', 'has_outstanding',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'total_purchases', 'total_paid', 'outstanding_balance',
            'created_at', 'updated_at'
        ]


class VendorDetailSerializer(serializers.ModelSerializer):
    """Detailed vendor serializer with bills"""
    
    bills = serializers.SerializerMethodField()
    total_bills = serializers.IntegerField(read_only=True)
    has_outstanding = serializers.BooleanField(read_only=True)
    display_name = serializers.CharField(read_only=True)
    
    class Meta:
        model = Vendor
        fields = [
            'id', 'name', 'display_name', 'phone', 'alternate_phone', 'email',
            'business_name', 'gstin', 'pan',
            'address_line1', 'address_line2', 'city', 'state', 'pincode',
            'payment_terms_days',
            'total_purchases', 'total_paid', 'outstanding_balance',
            'total_bills', 'has_outstanding', 'bills',
            'notes', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'total_purchases', 'total_paid', 'outstanding_balance',
            'created_at', 'updated_at'
        ]
    
    def get_bills(self, obj):
        """Get recent bills for this vendor"""
        recent_bills = obj.bills.all()[:10]  # Last 10 bills
        return PurchaseBillListSerializer(
            recent_bills,
            many=True,
            context=self.context
        ).data


class VendorCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating vendors"""
    
    class Meta:
        model = Vendor
        fields = [
            'id', 'name', 'phone', 'alternate_phone', 'email',
            'business_name', 'gstin', 'pan',
            'address_line1', 'address_line2', 'city', 'state', 'pincode',
            'payment_terms_days', 'notes', 'is_active'
        ]
    
    def validate_gstin(self, value):
        """Validate GSTIN format if provided"""
        if value and len(value) != 15:
            raise serializers.ValidationError('GSTIN must be exactly 15 characters')
        return value
    
    def validate_pan(self, value):
        """Validate PAN format if provided"""
        if value and len(value) != 10:
            raise serializers.ValidationError('PAN must be exactly 10 characters')
        return value.upper() if value else value
    
    def create(self, validated_data):
        # Auto-set tenant
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            validated_data['tenant'] = request.user.tenant
        return super().create(validated_data)


# ==================== PURCHASE BILL SERIALIZERS ====================

class PurchaseBillListSerializer(serializers.ModelSerializer):
    """Lightweight purchase bill serializer for lists"""
    
    vendor_name = serializers.CharField(source='vendor.name', read_only=True)
    vendor_business_name = serializers.CharField(source='vendor.business_name', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    bill_image_url = serializers.SerializerMethodField()
    payment_percentage = serializers.FloatField(read_only=True)
    
    class Meta:
        model = PurchaseBill
        fields = [
            'id', 'bill_number', 'bill_date', 'vendor', 'vendor_name', 'vendor_business_name',
            'bill_amount', 'paid_amount', 'balance_amount',
            'payment_status', 'payment_status_display', 'payment_percentage',
            'description', 'bill_image', 'bill_image_url',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'paid_amount', 'balance_amount', 'payment_status',
            'created_at', 'updated_at'
        ]
    
    def get_bill_image_url(self, obj):
        if obj.bill_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.bill_image.url)
        return None


class PurchaseBillDetailSerializer(serializers.ModelSerializer):
    """Detailed purchase bill serializer with payments"""
    
    vendor_name = serializers.CharField(source='vendor.name', read_only=True)
    vendor_display_name = serializers.CharField(source='vendor.display_name', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    bill_image_url = serializers.SerializerMethodField()
    payment_percentage = serializers.FloatField(read_only=True)
    payments = serializers.SerializerMethodField()
    
    class Meta:
        model = PurchaseBill
        fields = [
            'id', 'bill_number', 'bill_date', 'vendor', 'vendor_name', 'vendor_display_name',
            'bill_amount', 'paid_amount', 'balance_amount',
            'payment_status', 'payment_status_display', 'payment_percentage',
            'description', 'bill_image', 'bill_image_url',
            'payments', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'paid_amount', 'balance_amount', 'payment_status',
            'created_at', 'updated_at'
        ]
    
    def get_bill_image_url(self, obj):
        if obj.bill_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.bill_image.url)
        return None
    
    def get_payments(self, obj):
        """Get all payments for this bill"""
        return PaymentListSerializer(
            obj.payments.all(),
            many=True,
            context=self.context
        ).data


class PurchaseBillCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating purchase bills"""
    
    class Meta:
        model = PurchaseBill
        fields = [
            'id', 'bill_number', 'bill_date', 'vendor',
            'bill_amount', 'description', 'bill_image', 'notes'
        ]
    
    def validate(self, data):
        """Validate bill number uniqueness per vendor"""
        request = self.context.get('request')
        if not request or not hasattr(request.user, 'tenant'):
            return data
        
        tenant = request.user.tenant
        bill_number = data.get('bill_number')
        vendor = data.get('vendor')
        
        if bill_number and vendor:
            # Check for duplicate bill number for this vendor
            queryset = PurchaseBill.objects.filter(
                tenant=tenant,
                bill_number=bill_number,
                vendor=vendor
            )
            
            # Exclude current instance if updating
            if self.instance:
                queryset = queryset.exclude(pk=self.instance.pk)
            
            if queryset.exists():
                raise serializers.ValidationError({
                    'bill_number': f'Bill number "{bill_number}" already exists for this vendor'
                })
        
        return data
    
    def create(self, validated_data):
        # Auto-set tenant and balance
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            validated_data['tenant'] = request.user.tenant
        
        # Set initial balance = bill amount
        validated_data['balance_amount'] = validated_data['bill_amount']
        
        return super().create(validated_data)


# ==================== EXPENSE SERIALIZERS ====================

class ExpenseListSerializer(serializers.ModelSerializer):
    """Lightweight expense serializer for lists"""
    
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    receipt_image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Expense
        fields = [
            'id', 'expense_date', 'category', 'category_display',
            'expense_amount', 'paid_amount', 'balance_amount',
            'payment_status', 'payment_status_display',
            'description', 'receipt_image', 'receipt_image_url',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'paid_amount', 'balance_amount', 'payment_status',
            'created_at', 'updated_at'
        ]
    
    def get_receipt_image_url(self, obj):
        if obj.receipt_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.receipt_image.url)
        return None


class ExpenseDetailSerializer(serializers.ModelSerializer):
    """Detailed expense serializer with payments"""
    
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    receipt_image_url = serializers.SerializerMethodField()
    payments = serializers.SerializerMethodField()
    
    class Meta:
        model = Expense
        fields = [
            'id', 'expense_date', 'category', 'category_display',
            'expense_amount', 'paid_amount', 'balance_amount',
            'payment_status', 'payment_status_display',
            'description', 'receipt_image', 'receipt_image_url',
            'payments', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'paid_amount', 'balance_amount', 'payment_status',
            'created_at', 'updated_at'
        ]
    
    def get_receipt_image_url(self, obj):
        if obj.receipt_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.receipt_image.url)
        return None
    
    def get_payments(self, obj):
        """Get all payments for this expense"""
        return PaymentListSerializer(
            obj.payments.all(),
            many=True,
            context=self.context
        ).data


class ExpenseCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating expenses"""
    
    class Meta:
        model = Expense
        fields = [
            'id', 'expense_date', 'category',
            'expense_amount', 'description', 'receipt_image', 'notes'
        ]
    
    def create(self, validated_data):
        # Auto-set tenant and balance
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            validated_data['tenant'] = request.user.tenant
        
        # Set initial balance = expense amount
        validated_data['balance_amount'] = validated_data['expense_amount']
        
        return super().create(validated_data)


# ==================== PAYMENT SERIALIZERS ====================

class PaymentListSerializer(serializers.ModelSerializer):
    """Lightweight payment serializer for lists"""
    
    payment_type_display = serializers.CharField(source='get_payment_type_display', read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    vendor_name = serializers.CharField(read_only=True)
    display_reference = serializers.CharField(read_only=True)
    
    class Meta:
        model = Payment
        fields = [
            'id', 'payment_number', 'payment_date',
            'payment_type', 'payment_type_display',
            'amount', 'payment_method', 'payment_method_display',
            'vendor_name', 'display_reference',
            'reference_number', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['payment_number', 'created_at', 'updated_at']


class PaymentDetailSerializer(serializers.ModelSerializer):
    """Detailed payment serializer"""
    
    payment_type_display = serializers.CharField(source='get_payment_type_display', read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    vendor_name = serializers.CharField(read_only=True)
    display_reference = serializers.CharField(read_only=True)
    
    # Nested bill/expense details
    purchase_bill_details = serializers.SerializerMethodField()
    expense_details = serializers.SerializerMethodField()
    
    class Meta:
        model = Payment
        fields = [
            'id', 'payment_number', 'payment_date',
            'payment_type', 'payment_type_display',
            'purchase_bill', 'purchase_bill_details',
            'expense', 'expense_details',
            'amount', 'payment_method', 'payment_method_display',
            'vendor_name', 'display_reference',
            'reference_number', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['payment_number', 'created_at', 'updated_at']
    
    def get_purchase_bill_details(self, obj):
        if obj.purchase_bill:
            return {
                'id': obj.purchase_bill.id,
                'bill_number': obj.purchase_bill.bill_number,
                'bill_amount': obj.purchase_bill.bill_amount,
                'balance_amount': obj.purchase_bill.balance_amount,
                'vendor_name': obj.purchase_bill.vendor.name
            }
        return None
    
    def get_expense_details(self, obj):
        if obj.expense:
            return {
                'id': obj.expense.id,
                'category': obj.expense.category,
                'category_display': obj.expense.get_category_display(),
                'expense_amount': obj.expense.expense_amount,
                'balance_amount': obj.expense.balance_amount
            }
        return None


class PaymentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating payments"""
    
    class Meta:
        model = Payment
        fields = [
            'payment_date', 'payment_type',
            'purchase_bill', 'expense',
            'amount', 'payment_method', 'reference_number', 'notes'
        ]
    
    def validate(self, data):
        """Validate payment data"""
        payment_type = data.get('payment_type')
        purchase_bill = data.get('purchase_bill')
        expense = data.get('expense')
        amount = data.get('amount')
        
        # Validate links based on payment type
        if payment_type == Payment.PaymentType.PURCHASE_BILL:
            if not purchase_bill:
                raise serializers.ValidationError({
                    'purchase_bill': 'Purchase bill is required for purchase bill payment'
                })
            if expense:
                raise serializers.ValidationError({
                    'expense': 'Cannot link expense for purchase bill payment'
                })
            
            # Validate amount doesn't exceed balance
            remaining = purchase_bill.bill_amount - purchase_bill.paid_amount
            if amount > remaining:
                raise serializers.ValidationError({
                    'amount': f'Payment amount (₹{amount}) exceeds remaining balance (₹{remaining})'
                })
        
        elif payment_type == Payment.PaymentType.EXPENSE:
            if not expense:
                raise serializers.ValidationError({
                    'expense': 'Expense is required for expense payment'
                })
            if purchase_bill:
                raise serializers.ValidationError({
                    'purchase_bill': 'Cannot link purchase bill for expense payment'
                })
            
            # Validate amount doesn't exceed balance
            remaining = expense.expense_amount - expense.paid_amount
            if amount > remaining:
                raise serializers.ValidationError({
                    'amount': f'Payment amount (₹{amount}) exceeds remaining balance (₹{remaining})'
                })
        
        return data
    
    def create(self, validated_data):
        # Auto-set tenant
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            validated_data['tenant'] = request.user.tenant
        
        return super().create(validated_data)


# ==================== SUMMARY/STATS SERIALIZERS ====================

class PaymentSummarySerializer(serializers.Serializer):
    """Summary statistics for payments"""
    total_payments = serializers.DecimalField(max_digits=12, decimal_places=2)
    cash_payments = serializers.DecimalField(max_digits=12, decimal_places=2)
    digital_payments = serializers.DecimalField(max_digits=12, decimal_places=2)
    purchase_payments = serializers.DecimalField(max_digits=12, decimal_places=2)
    expense_payments = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_count = serializers.IntegerField()


class VendorSummarySerializer(serializers.Serializer):
    """Summary statistics for vendors"""
    total_vendors = serializers.IntegerField()
    active_vendors = serializers.IntegerField()
    total_outstanding = serializers.DecimalField(max_digits=12, decimal_places=2)
    vendors_with_outstanding = serializers.IntegerField()