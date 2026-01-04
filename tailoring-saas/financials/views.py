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
from .models import ReceiptVoucher, Payment, RefundVoucher
from .serializers import (
    ReceiptVoucherListSerializer,
    ReceiptVoucherDetailSerializer,
    ReceiptVoucherCreateSerializer,
    PaymentListSerializer,
    PaymentDetailSerializer,
    PaymentCreateSerializer,
    RefundVoucherListSerializer,
    RefundVoucherDetailSerializer,
    RefundVoucherCreateSerializer
)


# ==================== RECEIPT VOUCHER VIEWSET ====================

class ReceiptVoucherViewSet(viewsets.ModelViewSet):
    """Receipt voucher management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManagePayments]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['payment_mode', 'is_adjusted', 'deposited_to_bank']
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
    
    @action(detail=False, methods=['get'])
    def unadjusted(self, request):
        """Get all unadjusted receipt vouchers"""
        vouchers = self.get_queryset().filter(is_adjusted=False)
        serializer = self.get_serializer(vouchers, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def cash_not_deposited(self, request):
        """Get all cash receipts not yet deposited to bank"""
        vouchers = self.get_queryset().filter(
            payment_mode='CASH',
            deposited_to_bank=False
        )
        serializer = self.get_serializer(vouchers, many=True)
        return Response(serializer.data)


# ==================== PAYMENT VIEWSET ====================

class PaymentViewSet(viewsets.ModelViewSet):
    """Payment management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManagePayments]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['payment_mode', 'deposited_to_bank']
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
    
    @action(detail=False, methods=['get'])
    def cash_not_deposited(self, request):
        """Get all cash payments not yet deposited to bank"""
        payments = self.get_queryset().filter(
            payment_mode='CASH',
            deposited_to_bank=False
        )
        serializer = self.get_serializer(payments, many=True)
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
        serializer = self.get_serializer(payments, many=True)
        
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
    filterset_fields = ['refund_mode']
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
