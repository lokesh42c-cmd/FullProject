"""
Orders app views - Complete with ItemUnit
Date: 2026-01-09
"""

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q
from rest_framework.parsers import MultiPartParser

from core.permissions import CanManageOrders
from .models import Customer, Order, OrderItem, Item, OrderReferencePhoto
from masters.models import ItemUnit
from .serializers import (
    CustomerListSerializer,
    CustomerDetailSerializer,
    CustomerCreateSerializer,
    OrderListSerializer,
    OrderDetailSerializer,
    OrderCreateSerializer,
    OrderItemSerializer,
    ItemSerializer,
    ItemUnitSerializer
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
        user = self.request.user
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Customer.objects.none()
        
        queryset = Customer.objects.filter(tenant=user.tenant)
        
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
        serializer.save(tenant=self.request.user.tenant)
    
    def perform_update(self, serializer):
        instance = serializer.instance
        if instance.tenant != self.request.user.tenant:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You don't have permission to edit this customer.")
        serializer.save()


# ==================== ITEM UNIT VIEWSET ====================

class ItemUnitViewSet(viewsets.ModelViewSet):
    """Item Unit management"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    serializer_class = ItemUnitSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['is_active']
    search_fields = ['name', 'code']
    
    def get_queryset(self):
        user = self.request.user
        if not hasattr(user, 'tenant') or user.tenant is None:
            return ItemUnit.objects.none()
        
        return ItemUnit.objects.filter(tenant=user.tenant).order_by('name')
    
    def perform_create(self, serializer):
        serializer.save(tenant=self.request.user.tenant)


# ==================== ITEM VIEWSET ====================

class ItemViewSet(viewsets.ModelViewSet):
    """Item master management with inventory"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    serializer_class = ItemSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['item_type', 'is_active', 'track_stock']
    search_fields = ['name', 'description', 'hsn_sac_code', 'barcode']
    
    def get_queryset(self):
        user = self.request.user
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Item.objects.none()
        
        return Item.objects.filter(tenant=user.tenant, deleted_at__isnull=True).order_by('name')
    
    def perform_create(self, serializer):
        serializer.save(tenant=self.request.user.tenant)


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
        user = self.request.user
        if not hasattr(user, 'tenant') or user.tenant is None:
            return Order.objects.none()
        
        queryset = Order.objects.filter(tenant=user.tenant).select_related('customer')
        return queryset.order_by('-order_date', '-created_at')
    
    def perform_create(self, serializer):
        serializer.save(
            tenant=self.request.user.tenant,
            created_by=self.request.user
        )
    
    def perform_update(self, serializer):
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
        order = self.get_object()
        
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
    
    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser])
    def upload_photo(self, request, pk=None):
        order = self.get_object()
        photo_file = request.FILES.get('photo')
        
        if not photo_file:
            return Response({'error': 'No photo provided'}, status=400)
        
        photo = OrderReferencePhoto.objects.create(
            order=order,
            photo=photo_file
        )
        
        return Response({
            'id': photo.id,
            'order': order.id,
            'photo': photo.photo.name,
            'photo_url': photo.photo.url,
            'uploaded_at': photo.uploaded_at
        })

    @action(detail=True, methods=['delete'], url_path='delete_photo/(?P<photo_id>[^/.]+)')
    def delete_photo(self, request, pk=None, photo_id=None):
        try:
            photo = OrderReferencePhoto.objects.get(id=photo_id, order_id=pk)
            photo.delete()
            return Response({'message': 'Photo deleted'})
        except OrderReferencePhoto.DoesNotExist:
            return Response({'error': 'Photo not found'}, status=404)


# ==================== ORDER ITEM VIEWSET ====================

class OrderItemViewSet(viewsets.ModelViewSet):
    """Order item management"""
    
    permission_classes = [IsAuthenticated, CanManageOrders]
    serializer_class = OrderItemSerializer
    
    def get_queryset(self):
        user = self.request.user
        if not hasattr(user, 'tenant') or user.tenant is None:
            return OrderItem.objects.none()
        
        return OrderItem.objects.filter(order__tenant=user.tenant)