"""
Invoicing app views - Invoice API views
Date: 2026-01-03
"""

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q

from core.permissions import CanManageOrders
from .models import Invoice, InvoiceItem
from .serializers import (
    InvoiceListSerializer,
    InvoiceDetailSerializer,
    InvoiceCreateSerializer,
    InvoiceItemSerializer
)


# ==================== INVOICE VIEWSET ====================

class InvoiceViewSet(viewsets.ModelViewSet):
    """Invoice management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['status', 'payment_status', 'tax_type', 'customer', 'order']
    search_fields = ['invoice_number', 'customer__name', 'customer__phone', 'billing_name']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return InvoiceListSerializer
        elif self.action == 'retrieve':
            return InvoiceDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return InvoiceCreateSerializer
        return InvoiceListSerializer
    
    def get_queryset(self):
        """Filter invoices by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Invoice.objects.none()
        
        queryset = Invoice.objects.filter(tenant=user.tenant).select_related('customer', 'order')
        
        return queryset.order_by('-invoice_date', '-created_at')
    
    def perform_create(self, serializer):
        """Automatically assign tenant and created_by"""
        invoice = serializer.save(
            tenant=self.request.user.tenant,
            created_by=self.request.user
        )
        
        # If linked to order, lock the order
        if invoice.order:
            invoice.order.is_locked = True
            invoice.order.save()
    
    def perform_update(self, serializer):
        """Verify tenant before update"""
        instance = serializer.instance
        if instance.tenant != self.request.user.tenant:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You don't have permission to edit this invoice.")
        
        serializer.save()
    
    @action(detail=True, methods=['post'])
    def issue(self, request, pk=None):
        """Issue invoice (change status from DRAFT to ISSUED)"""
        invoice = self.get_object()
        
        if invoice.status != 'DRAFT':
            return Response(
                {'error': 'Only draft invoices can be issued'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        invoice.status = 'ISSUED'
        invoice.save()
        
        return Response({
            'message': 'Invoice issued successfully',
            'invoice_number': invoice.invoice_number,
            'status': invoice.status
        })
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel invoice"""
        invoice = self.get_object()
        
        if invoice.status == 'PAID':
            return Response(
                {'error': 'Cannot cancel paid invoices'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        invoice.status = 'CANCELLED'
        invoice.save()
        
        return Response({
            'message': 'Invoice cancelled successfully',
            'invoice_number': invoice.invoice_number,
            'status': invoice.status
        })
    
    @action(detail=False, methods=['get'])
    def unpaid(self, request):
        """Get all unpaid/partially paid invoices"""
        invoices = self.get_queryset().filter(
            status='ISSUED',
            payment_status__in=['UNPAID', 'PARTIAL']
        )
        
        serializer = self.get_serializer(invoices, many=True)
        return Response(serializer.data)


# ==================== INVOICE ITEM VIEWSET ====================

class InvoiceItemViewSet(viewsets.ModelViewSet):
    """Invoice item management"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    serializer_class = InvoiceItemSerializer
    
    def get_queryset(self):
        """Filter invoice items by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return InvoiceItem.objects.none()
        
        return InvoiceItem.objects.filter(invoice__tenant=user.tenant)