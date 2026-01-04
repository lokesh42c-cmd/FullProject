"""
Purchase Management Views
Complete ViewSets with tenant isolation and permissions
Created: 30-Dec-2025
"""

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum, Q, Count
from django.utils import timezone
from decimal import Decimal
from datetime import datetime, timedelta

from core.permissions import IsManagement  # Adjust based on your permissions
from core.subscription_utils import (
    require_active_subscription,
    require_feature,
    check_resource_limit
)

from .models import Vendor, PurchaseBill, Expense, Payment
from .serializers import (
    # Vendor
    VendorListSerializer,
    VendorDetailSerializer,
    VendorCreateUpdateSerializer,
    # Purchase Bill
    PurchaseBillListSerializer,
    PurchaseBillDetailSerializer,
    PurchaseBillCreateUpdateSerializer,
    # Expense
    ExpenseListSerializer,
    ExpenseDetailSerializer,
    ExpenseCreateUpdateSerializer,
    # Payment
    PaymentListSerializer,
    PaymentDetailSerializer,
    PaymentCreateSerializer,
    # Summary
    PaymentSummarySerializer,
    VendorSummarySerializer,
)


# ==================== VENDOR VIEWSET ====================

class VendorViewSet(viewsets.ModelViewSet):
    """
    Vendor management with tenant isolation
    List, create, update, delete vendors
    """
    permission_classes = [IsAuthenticated, IsManagement]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_active']
    search_fields = ['name', 'business_name', 'phone', 'gstin', 'city']
    ordering_fields = ['name', 'outstanding_balance', 'created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """🔒 SECURITY: Filter vendors by tenant"""
        return Vendor.objects.filter(tenant=self.request.user.tenant)
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'retrieve':
            return VendorDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return VendorCreateUpdateSerializer
        return VendorListSerializer
    
    @check_resource_limit('max_vendors')
    @require_active_subscription
    def create(self, request, *args, **kwargs):
        """Create new vendor"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            vendor = serializer.save()
            return Response({
                'message': 'Vendor created successfully',
                'vendor': VendorDetailSerializer(vendor, context={'request': request}).data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def with_outstanding(self, request):
        """Get vendors with outstanding balance"""
        vendors = self.get_queryset().filter(outstanding_balance__gt=0).order_by('-outstanding_balance')
        serializer = VendorListSerializer(vendors, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get vendor statistics"""
        queryset = self.get_queryset()
        
        summary = {
            'total_vendors': queryset.count(),
            'active_vendors': queryset.filter(is_active=True).count(),
            'total_outstanding': queryset.aggregate(
                total=Sum('outstanding_balance')
            )['total'] or Decimal('0.00'),
            'vendors_with_outstanding': queryset.filter(outstanding_balance__gt=0).count()
        }
        
        serializer = VendorSummarySerializer(summary)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def bills(self, request, pk=None):
        """Get all bills for a vendor"""
        vendor = self.get_object()
        bills = vendor.bills.all()
        serializer = PurchaseBillListSerializer(bills, many=True, context={'request': request})
        return Response(serializer.data)


# ==================== PURCHASE BILL VIEWSET ====================

class PurchaseBillViewSet(viewsets.ModelViewSet):
    """
    Purchase Bill management with tenant isolation
    Tracks vendor invoices and payment status
    """
    permission_classes = [IsAuthenticated, IsManagement]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['payment_status', 'vendor']
    search_fields = ['bill_number', 'vendor__name', 'vendor__business_name', 'description']
    ordering_fields = ['bill_date', 'bill_amount', 'balance_amount', 'created_at']
    ordering = ['-bill_date']
    
    def get_queryset(self):
        """🔒 SECURITY: Filter bills by tenant"""
        return PurchaseBill.objects.filter(tenant=self.request.user.tenant).select_related('vendor')
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'retrieve':
            return PurchaseBillDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return PurchaseBillCreateUpdateSerializer
        return PurchaseBillListSerializer
    
    @require_active_subscription
    def create(self, request, *args, **kwargs):
        """Create new purchase bill"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            bill = serializer.save()
            return Response({
                'message': 'Purchase bill created successfully',
                'bill': PurchaseBillDetailSerializer(bill, context={'request': request}).data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def unpaid(self, request):
        """Get all unpaid bills"""
        bills = self.get_queryset().filter(
            payment_status__in=['UNPAID', 'PARTIALLY_PAID']
        ).order_by('bill_date')
        serializer = PurchaseBillListSerializer(bills, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_vendor(self, request):
        """Get bills grouped by vendor"""
        vendor_id = request.query_params.get('vendor_id')
        if not vendor_id:
            return Response(
                {'error': 'vendor_id parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        bills = self.get_queryset().filter(vendor_id=vendor_id).order_by('-bill_date')
        serializer = PurchaseBillListSerializer(bills, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def payments(self, request, pk=None):
        """Get all payments for a bill"""
        bill = self.get_object()
        payments = bill.payments.all().order_by('-payment_date')
        serializer = PaymentListSerializer(payments, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get purchase bill statistics"""
        queryset = self.get_queryset()
        
        # Date filters
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(bill_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(bill_date__lte=end_date)
        
        summary = {
            'total_bills': queryset.count(),
            'total_amount': queryset.aggregate(total=Sum('bill_amount'))['total'] or Decimal('0.00'),
            'total_paid': queryset.aggregate(total=Sum('paid_amount'))['total'] or Decimal('0.00'),
            'total_outstanding': queryset.aggregate(total=Sum('balance_amount'))['total'] or Decimal('0.00'),
            'unpaid_count': queryset.filter(payment_status='UNPAID').count(),
            'partially_paid_count': queryset.filter(payment_status='PARTIALLY_PAID').count(),
            'fully_paid_count': queryset.filter(payment_status='FULLY_PAID').count(),
        }
        
        return Response(summary)


# ==================== EXPENSE VIEWSET ====================

class ExpenseViewSet(viewsets.ModelViewSet):
    """
    Expense management with tenant isolation
    Daily operational expenses tracking
    """
    permission_classes = [IsAuthenticated, IsManagement]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'payment_status']
    search_fields = ['description', 'notes']
    ordering_fields = ['expense_date', 'expense_amount', 'created_at']
    ordering = ['-expense_date']
    
    def get_queryset(self):
        """🔒 SECURITY: Filter expenses by tenant"""
        return Expense.objects.filter(tenant=self.request.user.tenant)
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'retrieve':
            return ExpenseDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return ExpenseCreateUpdateSerializer
        return ExpenseListSerializer
    
    @require_active_subscription
    def create(self, request, *args, **kwargs):
        """Create new expense"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            expense = serializer.save()
            return Response({
                'message': 'Expense created successfully',
                'expense': ExpenseDetailSerializer(expense, context={'request': request}).data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """Get expenses grouped by category"""
        # Date filters
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        queryset = self.get_queryset()
        if start_date:
            queryset = queryset.filter(expense_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(expense_date__lte=end_date)
        
        # Group by category
        categories = queryset.values('category').annotate(
            total=Sum('expense_amount'),
            count=Count('id')
        ).order_by('-total')
        
        return Response(list(categories))
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get expense statistics"""
        # Date filters
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        queryset = self.get_queryset()
        if start_date:
            queryset = queryset.filter(expense_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(expense_date__lte=end_date)
        
        summary = {
            'total_expenses': queryset.count(),
            'total_amount': queryset.aggregate(total=Sum('expense_amount'))['total'] or Decimal('0.00'),
            'total_paid': queryset.aggregate(total=Sum('paid_amount'))['total'] or Decimal('0.00'),
            'total_outstanding': queryset.aggregate(total=Sum('balance_amount'))['total'] or Decimal('0.00'),
            'by_category': list(queryset.values('category').annotate(
                total=Sum('expense_amount')
            ).order_by('-total'))
        }
        
        return Response(summary)
    
    @action(detail=True, methods=['get'])
    def payments(self, request, pk=None):
        """Get all payments for an expense"""
        expense = self.get_object()
        payments = expense.payments.all().order_by('-payment_date')
        serializer = PaymentListSerializer(payments, many=True, context={'request': request})
        return Response(serializer.data)


# ==================== PAYMENT VIEWSET ====================

class PaymentViewSet(viewsets.ModelViewSet):
    """
    Payment management with tenant isolation
    Unified payment tracking for bills and expenses
    """
    permission_classes = [IsAuthenticated, IsManagement]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['payment_type', 'payment_method']
    search_fields = ['payment_number', 'reference_number', 'notes']
    ordering_fields = ['payment_date', 'amount', 'created_at']
    ordering = ['-payment_date']
    
    def get_queryset(self):
        """🔒 SECURITY: Filter payments by tenant"""
        return Payment.objects.filter(
            tenant=self.request.user.tenant
        ).select_related('purchase_bill', 'expense', 'purchase_bill__vendor')
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'retrieve':
            return PaymentDetailSerializer
        elif self.action == 'create':
            return PaymentCreateSerializer
        return PaymentListSerializer
    
    @require_active_subscription
    def create(self, request, *args, **kwargs):
        """Create new payment"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            payment = serializer.save()
            return Response({
                'message': 'Payment recorded successfully',
                'payment': PaymentDetailSerializer(payment, context={'request': request}).data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def update(self, request, *args, **kwargs):
        """Payments cannot be updated - delete and recreate instead"""
        return Response(
            {'error': 'Payments cannot be modified. Please delete and create a new payment.'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
    
    def partial_update(self, request, *args, **kwargs):
        """Payments cannot be partially updated"""
        return Response(
            {'error': 'Payments cannot be modified. Please delete and create a new payment.'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
    
    @action(detail=False, methods=['get'])
    def today(self, request):
        """Get today's payments"""
        today = timezone.now().date()
        payments = self.get_queryset().filter(payment_date=today)
        serializer = PaymentListSerializer(payments, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_date_range(self, request):
        """Get payments within date range"""
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        if not start_date or not end_date:
            return Response(
                {'error': 'start_date and end_date parameters are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        payments = self.get_queryset().filter(
            payment_date__gte=start_date,
            payment_date__lte=end_date
        )
        
        serializer = PaymentListSerializer(payments, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get payment statistics"""
        # Date filters
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        queryset = self.get_queryset()
        if start_date:
            queryset = queryset.filter(payment_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(payment_date__lte=end_date)
        
        # Calculate totals
        total_payments = queryset.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        cash_payments = queryset.filter(
            payment_method='CASH'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        digital_payments = queryset.filter(
            payment_method__in=['UPI', 'BANK_TRANSFER', 'CARD']
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        purchase_payments = queryset.filter(
            payment_type='PURCHASE_BILL'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        expense_payments = queryset.filter(
            payment_type='EXPENSE'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        summary = {
            'total_payments': total_payments,
            'cash_payments': cash_payments,
            'digital_payments': digital_payments,
            'purchase_payments': purchase_payments,
            'expense_payments': expense_payments,
            'total_count': queryset.count()
        }
        
        serializer = PaymentSummarySerializer(summary)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_method(self, request):
        """Get payments grouped by payment method"""
        queryset = self.get_queryset()
        
        # Date filters
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(payment_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(payment_date__lte=end_date)
        
        methods = queryset.values('payment_method').annotate(
            total=Sum('amount'),
            count=Count('id')
        ).order_by('-total')
        
        return Response(list(methods))


# ==================== DASHBOARD/ANALYTICS ====================

@require_active_subscription
class DashboardViewSet(viewsets.ViewSet):
    """
    Dashboard analytics and overview
    Read-only viewset for statistics
    """
    permission_classes = [IsAuthenticated, IsManagement]
    
    @action(detail=False, methods=['get'])
    def overview(self, request):
        """Get complete purchase management overview"""
        tenant = request.user.tenant
        
        # Vendors
        vendors = Vendor.objects.filter(tenant=tenant)
        vendor_stats = {
            'total': vendors.count(),
            'active': vendors.filter(is_active=True).count(),
            'with_outstanding': vendors.filter(outstanding_balance__gt=0).count(),
            'total_outstanding': vendors.aggregate(
                total=Sum('outstanding_balance')
            )['total'] or Decimal('0.00')
        }
        
        # Purchase Bills
        bills = PurchaseBill.objects.filter(tenant=tenant)
        bill_stats = {
            'total': bills.count(),
            'unpaid': bills.filter(payment_status='UNPAID').count(),
            'partially_paid': bills.filter(payment_status='PARTIALLY_PAID').count(),
            'fully_paid': bills.filter(payment_status='FULLY_PAID').count(),
            'total_amount': bills.aggregate(total=Sum('bill_amount'))['total'] or Decimal('0.00'),
            'total_outstanding': bills.aggregate(
                total=Sum('balance_amount')
            )['total'] or Decimal('0.00')
        }
        
        # Expenses (this month)
        today = timezone.now().date()
        month_start = today.replace(day=1)
        expenses = Expense.objects.filter(
            tenant=tenant,
            expense_date__gte=month_start
        )
        expense_stats = {
            'this_month': expenses.aggregate(total=Sum('expense_amount'))['total'] or Decimal('0.00'),
            'by_category': list(expenses.values('category').annotate(
                total=Sum('expense_amount')
            ).order_by('-total')[:5])
        }
        
        # Payments (this month)
        payments = Payment.objects.filter(
            tenant=tenant,
            payment_date__gte=month_start
        )
        payment_stats = {
            'this_month': payments.aggregate(total=Sum('amount'))['total'] or Decimal('0.00'),
            'cash': payments.filter(payment_method='CASH').aggregate(
                total=Sum('amoun    t')
            )['total'] or Decimal('0.00'),
            'digital': payments.filter(
                payment_method__in=['UPI', 'BANK_TRANSFER', 'CARD']
            ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        }
        
        return Response({
            'vendors': vendor_stats,
            'bills': bill_stats,
            'expenses': expense_stats,
            'payments': payment_stats
        })