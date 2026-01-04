"""
Orders app views - Simplified for GST Compliance
Date: 2026-01-03
"""

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q

from core.permissions import CanManageOrders
from .models import Customer, Order, OrderItem, Item
from .serializers import (
    CustomerListSerializer,
    CustomerDetailSerializer,
    CustomerCreateSerializer,
    OrderListSerializer,
    OrderDetailSerializer,
    OrderCreateSerializer,
    OrderItemSerializer,
    ItemSerializer
)


# ==================== CUSTOMER VIEWSET ====================

class CustomerViewSet(viewsets.ModelViewSet):
    """Customer management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['customer_type', 'is_active', 'gender']
    search_fields = ['name', 'phone', 'email', 'whatsapp_number']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return CustomerListSerializer
        elif self.action == 'retrieve':
            return CustomerDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return CustomerCreateSerializer
        return CustomerListSerializer
    
    def get_queryset(self):
        """Filter customers by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Customer.objects.none()
        
        queryset = Customer.objects.filter(tenant=user.tenant)
        
        # Optional search
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) |
                Q(phone__icontains=search) |
                Q(email__icontains=search) |
                Q(whatsapp_number__icontains=search)
            )
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        """Automatically assign tenant"""
        serializer.save(tenant=self.request.user.tenant)
    
    def perform_update(self, serializer):
        """Verify tenant before update"""
        instance = serializer.instance
        if instance.tenant != self.request.user.tenant:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You don't have permission to edit this customer.")
        serializer.save()


# ==================== ORDER VIEWSET ====================

class OrderViewSet(viewsets.ModelViewSet):
    """Order management with tenant isolation"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['order_status', 'delivery_status', 'is_locked']
    search_fields = ['order_number', 'customer__name', 'customer__phone']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return OrderListSerializer
        elif self.action == 'retrieve':
            return OrderDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return OrderCreateSerializer
        return OrderListSerializer
    
    def get_queryset(self):
        """Filter orders by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Order.objects.none()
        
        queryset = Order.objects.filter(tenant=user.tenant).select_related('customer')
        
        return queryset.order_by('-order_date', '-created_at')
    
    def perform_create(self, serializer):
        """Automatically assign tenant and created_by"""
        serializer.save(
            tenant=self.request.user.tenant,
            created_by=self.request.user
        )
    
    def perform_update(self, serializer):
        """Verify tenant and check if locked"""
        instance = serializer.instance
        if instance.tenant != self.request.user.tenant:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You don't have permission to edit this order.")
        
        if instance.is_locked:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("This order is locked and cannot be modified.")
        
        serializer.save(updated_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def lock(self, request, pk=None):
        """Lock order to prevent modifications"""
        order = self.get_object()
        order.is_locked = True
        order.save()
        
        return Response({
            'message': 'Order locked successfully',
            'order_number': order.order_number,
            'is_locked': order.is_locked
        })
    
    @action(detail=True, methods=['post'])
    def unlock(self, request, pk=None):
        """Unlock order (admin only)"""
        order = self.get_object()
        
        # Only allow owner/management to unlock
        if not request.user.is_owner and not request.user.is_management:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only owners can unlock orders.")
        
        order.is_locked = False
        order.save()
        
        return Response({
            'message': 'Order unlocked successfully',
            'order_number': order.order_number,
            'is_locked': order.is_locked
        })


# ==================== ORDER ITEM VIEWSET ====================

class OrderItemViewSet(viewsets.ModelViewSet):
    """Order item management"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    serializer_class = OrderItemSerializer
    
    def get_queryset(self):
        """Filter order items by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return OrderItem.objects.none()
        
        return OrderItem.objects.filter(order__tenant=user.tenant)


# ==================== ITEM VIEWSET ====================

class ItemViewSet(viewsets.ModelViewSet):
    """Item master management"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    serializer_class = ItemSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['item_type', 'is_active']
    search_fields = ['name', 'description', 'hsn_sac_code']
    
    def get_queryset(self):
        """Filter items by tenant"""
        user = self.request.user
        
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Item.objects.none()
        
        return Item.objects.filter(tenant=user.tenant).order_by('name')
    
    def perform_create(self, serializer):
        """Automatically assign tenant"""
        serializer.save(tenant=self.request.user.tenant)


# ==================== DEPRECATED VIEWS (COMMENTED OUT) ====================

"""
# OLD FAMILY MEMBER VIEWSETS
class FamilyMemberViewSet(viewsets.ModelViewSet):
    pass

class FamilyMemberMeasurementViewSet(viewsets.ModelViewSet):
    pass

# OLD INVOICE/PAYMENT VIEWSETS
class InvoiceViewSet(viewsets.ModelViewSet):
    pass

class OrderPaymentViewSet(viewsets.ModelViewSet):
    pass
"""