"""
Financials app views - Financial API views
Date: 2026-01-03
"""

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Sum

from core.permissions import CanManageOrders, CanManagePayments
from .models import ReceiptVoucher, Payment, RefundVoucher, PaymentRefund
from .serializers import (
    ReceiptVoucherListSerializer,
    ReceiptVoucherDetailSerializer,
    ReceiptVoucherCreateSerializer,
    PaymentListSerializer,
    PaymentDetailSerializer,
    PaymentCreateSerializer,
    RefundVoucherListSerializer,
    RefundVoucherDetailSerializer,
    RefundVoucherCreateSerializer,
    PaymentRefundListSerializer,
    PaymentRefundDetailSerializer,
    PaymentRefundCreateSerializer
)


# ==================== RECEIPT VOUCHER VIEWSET ====================

class ReceiptVoucherViewSet(viewsets.ModelViewSet):
    """Receipt voucher management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManagePayments]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['payment_mode', 'deposited_to_bank', 'order', 'customer']
    search_fields = ['voucher_number', 'customer__name', 'customer__phone', 'transaction_reference']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return ReceiptVoucherListSerializer
        elif self.action == 'retrieve':
            return ReceiptVoucherDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return ReceiptVoucherCreateSerializer
        return ReceiptVoucherListSerializer
    
    def get_queryset(self):
        """Filter receipt vouchers by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return ReceiptVoucher.objects.none()
        
        queryset = ReceiptVoucher.objects.filter(tenant=user.tenant).select_related('customer', 'order')
        
        return queryset.order_by('-receipt_date', '-created_at')
    
    def perform_create(self, serializer):
        """Automatically assign tenant and created_by"""
        serializer.save(
            tenant=self.request.user.tenant,
            created_by=self.request.user
        )
    
    def create(self, request, *args, **kwargs):
        """Override create to return detailed response"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Return full detail using DetailSerializer
        instance = serializer.instance
        detail_serializer = ReceiptVoucherDetailSerializer(instance)
        headers = self.get_success_headers(detail_serializer.data)
        return Response(detail_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def update(self, request, *args, **kwargs):
        """Override update to return detailed response"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Return full detail using DetailSerializer
        detail_serializer = ReceiptVoucherDetailSerializer(serializer.instance)
        return Response(detail_serializer.data)
    
    @action(detail=False, methods=['get'])
    def unadjusted(self, request):
        """Get all unadjusted receipt vouchers"""
        vouchers = self.get_queryset().filter(is_adjusted=False)
        serializer = ReceiptVoucherListSerializer(vouchers, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def cash_not_deposited(self, request):
        """Get all cash receipts not yet deposited to bank"""
        vouchers = self.get_queryset().filter(
            payment_mode='CASH',
            deposited_to_bank=False
        )
        serializer = ReceiptVoucherListSerializer(vouchers, many=True)
        return Response(serializer.data)


# ==================== PAYMENT VIEWSET ====================

class PaymentViewSet(viewsets.ModelViewSet):
    """Payment management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManagePayments]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['payment_mode', 'deposited_to_bank', 'invoice']
    search_fields = ['payment_number', 'invoice__invoice_number', 'transaction_reference']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return PaymentListSerializer
        elif self.action == 'retrieve':
            return PaymentDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return PaymentCreateSerializer
        return PaymentListSerializer
    
    def get_queryset(self):
        """Filter payments by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Payment.objects.none()
        
        queryset = Payment.objects.filter(tenant=user.tenant).select_related('invoice')
        
        return queryset.order_by('-payment_date', '-created_at')
    
    def perform_create(self, serializer):
        """Automatically assign tenant and created_by"""
        serializer.save(
            tenant=self.request.user.tenant,
            created_by=self.request.user
        )
    
    def create(self, request, *args, **kwargs):
        """Override create to return detailed response"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Return full detail using DetailSerializer
        instance = serializer.instance
        detail_serializer = PaymentDetailSerializer(instance)
        headers = self.get_success_headers(detail_serializer.data)
        return Response(detail_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def update(self, request, *args, **kwargs):
        """Override update to return detailed response"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Return full detail using DetailSerializer
        detail_serializer = PaymentDetailSerializer(serializer.instance)
        return Response(detail_serializer.data)
    
    @action(detail=False, methods=['get'])
    def cash_not_deposited(self, request):
        """Get all cash payments not yet deposited to bank"""
        payments = self.get_queryset().filter(
            payment_mode='CASH',
            deposited_to_bank=False
        )
        serializer = PaymentListSerializer(payments, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_invoice(self, request):
        """Get payments for a specific invoice"""
        invoice_id = request.query_params.get('invoice_id')
        if not invoice_id:
            return Response(
                {'error': 'invoice_id parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        payments = self.get_queryset().filter(invoice_id=invoice_id)
        serializer = PaymentListSerializer(payments, many=True)
        
        total_paid = payments.aggregate(total=Sum('amount'))['total'] or 0
        
        return Response({
            'payments': serializer.data,
            'total_paid': total_paid
        })


# ==================== REFUND VOUCHER VIEWSET ====================

class RefundVoucherViewSet(viewsets.ModelViewSet):
    """Refund voucher management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManagePayments]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['refund_mode', 'customer', 'receipt_voucher']
    search_fields = ['refund_number', 'customer__name', 'receipt_voucher__voucher_number']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return RefundVoucherListSerializer
        elif self.action == 'retrieve':
            return RefundVoucherDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return RefundVoucherCreateSerializer
        return RefundVoucherListSerializer
    
    def get_queryset(self):
        """Filter refund vouchers by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return RefundVoucher.objects.none()
        
        queryset = RefundVoucher.objects.filter(tenant=user.tenant).select_related(
            'customer', 'receipt_voucher'
        )
        
        return queryset.order_by('-refund_date', '-created_at')
    
    def perform_create(self, serializer):
        """Automatically assign tenant and created_by"""
        serializer.save(
            tenant=self.request.user.tenant,
            created_by=self.request.user
        )
    
    def create(self, request, *args, **kwargs):
        """Override create to return detailed response"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Return full detail using DetailSerializer
        instance = serializer.instance
        detail_serializer = RefundVoucherDetailSerializer(instance)
        headers = self.get_success_headers(detail_serializer.data)
        return Response(detail_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def update(self, request, *args, **kwargs):
        """Override update to return detailed response"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Return full detail using DetailSerializer
        detail_serializer = RefundVoucherDetailSerializer(serializer.instance)
        return Response(detail_serializer.data)


# ==================== PAYMENT REFUND VIEWSET ====================

class PaymentRefundViewSet(viewsets.ModelViewSet):
    """
    Payment Refund management with tenant isolation
    Handles refunds for invoice payments (NOT receipt vouchers)
    """
    
    permission_classes = [IsAuthenticated, CanManagePayments]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['refund_mode', 'payment', 'invoice', 'customer']
    search_fields = ['refund_number', 'payment__payment_number', 'invoice__invoice_number', 'customer__name']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return PaymentRefundListSerializer
        elif self.action == 'retrieve':
            return PaymentRefundDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return PaymentRefundCreateSerializer
        return PaymentRefundListSerializer
    
    def get_queryset(self):
        """Filter payment refunds by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return PaymentRefund.objects.none()
        
        queryset = PaymentRefund.objects.filter(tenant=user.tenant).select_related(
            'payment', 'invoice', 'customer', 'created_by'
        )
        
        # Additional filters from query params
        invoice_id = self.request.query_params.get('invoice_id')
        if invoice_id:
            queryset = queryset.filter(invoice_id=invoice_id)
        
        payment_id = self.request.query_params.get('payment_id')
        if payment_id:
            queryset = queryset.filter(payment_id=payment_id)
        
        customer_id = self.request.query_params.get('customer_id')
        if customer_id:
            queryset = queryset.filter(customer_id=customer_id)
        
        # Date range filters
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        if start_date:
            queryset = queryset.filter(refund_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(refund_date__lte=end_date)
        
        return queryset.order_by('-refund_date', '-created_at')
    
    def perform_create(self, serializer):
        """Automatically assign tenant and created_by"""
        serializer.save(
            tenant=self.request.user.tenant,
            created_by=self.request.user
        )
    
    def create(self, request, *args, **kwargs):
        """Override create to return detailed response"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Return full detail using DetailSerializer
        instance = serializer.instance
        detail_serializer = PaymentRefundDetailSerializer(instance)
        headers = self.get_success_headers(detail_serializer.data)
        return Response(detail_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def update(self, request, *args, **kwargs):
        """Override update to return detailed response"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Return full detail using DetailSerializer
        detail_serializer = PaymentRefundDetailSerializer(serializer.instance)
        return Response(detail_serializer.data)
    
    def destroy(self, request, *args, **kwargs):
        """
        Delete payment refund
        Note: This will recalculate invoice totals automatically
        """
        instance = self.get_object()
        invoice = instance.invoice
        
        # Delete the refund
        self.perform_destroy(instance)
        
        # Recalculate invoice totals
        if invoice:
            invoice.calculate_totals()
        
        return Response(
            {"message": "Payment refund deleted successfully"},
            status=status.HTTP_204_NO_CONTENT
        )
    
    @action(detail=False, methods=['get'])
    def by_invoice(self, request):
        """Get all refunds for a specific invoice"""
        invoice_id = request.query_params.get('invoice_id')
        if not invoice_id:
            return Response(
                {'error': 'invoice_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        refunds = self.get_queryset().filter(invoice_id=invoice_id)
        serializer = self.get_serializer(refunds, many=True)
        
        # Calculate total refunded
        total = refunds.aggregate(total=Sum('refund_amount'))['total'] or 0
        
        return Response({
            'refunds': serializer.data,
            'total_refunded': total,
            'count': refunds.count()
        })
    
    @action(detail=False, methods=['get'])
    def by_payment(self, request):
        """Get all refunds for a specific payment"""
        payment_id = request.query_params.get('payment_id')
        if not payment_id:
            return Response(
                {'error': 'payment_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        refunds = self.get_queryset().filter(payment_id=payment_id)
        serializer = self.get_serializer(refunds, many=True)
        
        # Calculate total refunded for this payment
        total = refunds.aggregate(total=Sum('refund_amount'))['total'] or 0
        
        return Response({
            'refunds': serializer.data,
            'total_refunded': total,
            'count': refunds.count()
        })
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get refund summary statistics"""
        queryset = self.get_queryset()
        
        # Date filters
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(refund_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(refund_date__lte=end_date)
        
        # Calculate summary
        from django.db.models import Count
        summary = queryset.aggregate(
            total_refunds=Sum('refund_amount'),
            count=Count('id')
        )
        
        # Group by refund mode
        by_mode = queryset.values('refund_mode').annotate(
            total=Sum('refund_amount'),
            count=Count('id')
        )
        
        return Response({
            'total_refunded': summary['total_refunds'] or 0,
            'total_count': summary['count'] or 0,
            'by_mode': list(by_mode)
        })