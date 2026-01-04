"""
Views for masters app - API endpoints
Updated with new permission system
"""
from rest_framework import status, viewsets
from rest_framework.decorators import api_view, action
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q

from core.permissions import IsManagement, IsOwner

from .models import ItemCategory, Unit, MeasurementField, TenantMeasurementConfig,ServiceItem,ItemUnit
from .serializers import (
    ItemCategorySerializer,
    UnitSerializer,
    ItemUnitSerializer,
    MeasurementFieldSerializer,
    TenantMeasurementConfigSerializer,
    CategoryWithMeasurementsSerializer,ServiceItemSerializer  
)


class ItemCategoryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Item Categories
    GET: List all categories (system + tenant custom)
    POST: Create custom category (tenant-specific)
    """
    serializer_class = ItemCategorySerializer
    permission_classes = [IsAuthenticated, IsManagement]
    
    def get_queryset(self):
        """Get system categories + tenant's custom categories"""
        user = self.request.user
        
        if user.is_superuser:
            # Superuser sees everything
            return ItemCategory.objects.all()
        
        if not user.tenant:
            return ItemCategory.objects.none()
        
        # Regular users see system categories + their own custom categories
        return ItemCategory.objects.filter(
            Q(is_system_wide=True) | Q(tenant=user.tenant)
        ).filter(is_active=True).order_by('category_type', 'display_order', 'name')
    
    def list(self, request):
        """List all available categories"""
        queryset = self.get_queryset()
        
        # Optional filter by category_type
        category_type = request.query_params.get('category_type', None)
        if category_type:
            queryset = queryset.filter(category_type=category_type.upper())
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'count': queryset.count(),
            'categories': serializer.data
        })
    
    def create(self, request):
        """Create custom category for tenant"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Custom category created successfully',
                'category': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['get'])
    def measurements(self, request, pk=None):
        """Get all measurement fields for a category"""
        category = self.get_object()
        serializer = CategoryWithMeasurementsSerializer(category, context={'request': request})
        return Response(serializer.data)


class UnitViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for Units (Read-Only)
    Only system admin can create units
    """
    queryset = Unit.objects.filter(is_active=True).order_by('display_order', 'name')
    serializer_class = UnitSerializer
    permission_classes = [IsAuthenticated]


class MeasurementFieldViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Measurement Fields
    GET: List all fields (system + tenant custom)
    POST: Create custom field (tenant-specific)
    """
    serializer_class = MeasurementFieldSerializer
    permission_classes = [IsAuthenticated, IsManagement]
    
    def get_queryset(self):
        """Get system fields + tenant's custom fields"""
        user = self.request.user
        
        if user.is_superuser:
            return MeasurementField.objects.all()
        
        if not user.tenant:
            return MeasurementField.objects.none()
        
        # Get system fields + tenant custom fields
        queryset = MeasurementField.objects.filter(
            Q(is_system_wide=True) | Q(tenant=user.tenant)
        ).filter(is_active=True)
        
        # Filter by category if provided
        category_id = self.request.query_params.get('category', None)
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        
        return queryset.order_by('category', 'display_order', 'field_name')
    
    def list(self, request):
        """List all measurement fields"""
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({
            'count': queryset.count(),
            'fields': serializer.data
        })
    
    def create(self, request):
        """Create custom measurement field"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Custom measurement field created successfully',
                'field': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TenantMeasurementConfigViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Tenant Measurement Configuration
    Allows tenants to customize visibility and labels of measurement fields
    """
    serializer_class = TenantMeasurementConfigSerializer
    permission_classes = [IsAuthenticated, IsManagement]
    
    def get_queryset(self):
        """Get configs for current tenant"""
        if not self.request.user.tenant:
            return TenantMeasurementConfig.objects.none()
        
        return TenantMeasurementConfig.objects.filter(
            tenant=self.request.user.tenant
        )
    
    def create(self, request):
        """Create or update field configuration"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            # Check if config already exists
            tenant = request.user.tenant
            measurement_field = serializer.validated_data['measurement_field']
            
            config, created = TenantMeasurementConfig.objects.update_or_create(
                tenant=tenant,
                measurement_field=measurement_field,
                defaults=serializer.validated_data
            )
            
            response_serializer = self.get_serializer(config)
            
            return Response({
                'message': 'Configuration saved successfully',
                'config': response_serializer.data
            }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Additional API endpoints

@api_view(['GET'])
def get_categories_by_type(request):
    """
    Get categories grouped by type
    GET /api/masters/categories/grouped/
    """
    user = request.user
    
    if not user.tenant and not user.is_superuser:
        return Response({
            'garments': [],
            'fabrics': [],
            'accessories': []
        })
    
    # Get available categories
    if user.is_superuser:
        categories = ItemCategory.objects.filter(is_active=True)
    else:
        categories = ItemCategory.objects.filter(
            Q(is_system_wide=True) | Q(tenant=user.tenant),
            is_active=True
        )
    
    # Group by type
    grouped = {
        'garments': ItemCategorySerializer(
            categories.filter(category_type='GARMENT').order_by('display_order', 'name'),
            many=True
        ).data,
        'fabrics': ItemCategorySerializer(
            categories.filter(category_type='FABRIC').order_by('display_order', 'name'),
            many=True
        ).data,
        'accessories': ItemCategorySerializer(
            categories.filter(category_type='ACCESSORY').order_by('display_order', 'name'),
            many=True
        ).data,
    }
    
    return Response(grouped)


@api_view(['GET'])
def get_measurement_form(request, category_id):
    """
    Get complete measurement form for a category
    Returns fields with tenant customization applied
    GET /api/masters/measurement-form/{category_id}/
    """
    try:
        # Check if category exists and user has access
        if request.user.is_superuser:
            category = ItemCategory.objects.get(id=category_id)
        else:
            if not request.user.tenant:
                return Response({
                    'error': 'No tenant associated with user'
                }, status=status.HTTP_403_FORBIDDEN)
            
            category = ItemCategory.objects.filter(
                Q(is_system_wide=True) | Q(tenant=request.user.tenant),
                id=category_id,
                is_active=True
            ).first()
            
            if not category:
                return Response({
                    'error': 'Category not found or access denied'
                }, status=status.HTTP_404_NOT_FOUND)
        
        serializer = CategoryWithMeasurementsSerializer(category, context={'request': request})
        return Response(serializer.data)
        
    except ItemCategory.DoesNotExist:
        return Response({
            'error': 'Category not found'
        }, status=status.HTTP_404_NOT_FOUND)

# ========================================
# ADD THIS TO masters/views.py
# ========================================

class ServiceItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Service Items
    GET: List all services (system + tenant custom)
    POST: Create custom service (tenant-specific)
    PUT/PATCH: Update service
    DELETE: Delete service
    """
    serializer_class = ServiceItemSerializer
    permission_classes = [IsAuthenticated, IsManagement]
    
    def get_queryset(self):
        """Get system services + tenant's custom services"""
        user = self.request.user
        
        if user.is_superuser:
            # Superuser sees everything
            return ServiceItem.objects.all()
        
        if not user.tenant:
            return ServiceItem.objects.none()
        
        # Regular users see system services + their own custom services
        queryset = ServiceItem.objects.filter(
            Q(is_system_wide=True) | Q(tenant=user.tenant)
        )
        
        # Optional filters
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            is_active_bool = is_active.lower() in ['true', '1', 'yes']
            queryset = queryset.filter(is_active=is_active_bool)
        
        service_category = self.request.query_params.get('service_category')
        if service_category:
            queryset = queryset.filter(service_category=service_category.upper())
        
        return queryset.order_by('service_category', 'display_order', 'name')
    
    def list(self, request):
        """List all available service items"""
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        
        return Response({
            'count': queryset.count(),
            'service_items': serializer.data
        })
    
    def create(self, request):
        """Create custom service for tenant"""
        serializer = self.get_serializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Service item created successfully',
                'service_item': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def update(self, request, pk=None):
        """Update service item"""
        instance = self.get_object()
        
        # Prevent updating system-wide services unless superuser
        if instance.is_system_wide and not request.user.is_superuser:
            return Response({
                'error': 'Cannot modify system-wide service items'
            }, status=status.HTTP_403_FORBIDDEN)
        
        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=False,
            context={'request': request}
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Service item updated successfully',
                'service_item': serializer.data
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def partial_update(self, request, pk=None):
        """Partially update service item"""
        instance = self.get_object()
        
        # Prevent updating system-wide services unless superuser
        if instance.is_system_wide and not request.user.is_superuser:
            return Response({
                'error': 'Cannot modify system-wide service items'
            }, status=status.HTTP_403_FORBIDDEN)
        
        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=True,
            context={'request': request}
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Service item updated successfully',
                'service_item': serializer.data
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def destroy(self, request, pk=None):
        """Delete service item"""
        instance = self.get_object()
        
        # Prevent deleting system-wide services unless superuser
        if instance.is_system_wide and not request.user.is_superuser:
            return Response({
                'error': 'Cannot delete system-wide service items'
            }, status=status.HTTP_403_FORBIDDEN)
        
        instance.delete()
        return Response({
            'message': 'Service item deleted successfully'
        }, status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        """Toggle active status of service item"""
        instance = self.get_object()
        
        # Prevent modifying system-wide services unless superuser
        if instance.is_system_wide and not request.user.is_superuser:
            return Response({
                'error': 'Cannot modify system-wide service items'
            }, status=status.HTTP_403_FORBIDDEN)
        
        instance.is_active = not instance.is_active
        instance.save()
        
        serializer = self.get_serializer(instance)
        return Response({
            'message': f'Service item {"activated" if instance.is_active else "deactivated"}',
            'service_item': serializer.data
        })


# ========================================
# Additional helper endpoint
# ========================================

@api_view(['GET'])
def get_service_categories(request):
    """
    Get list of service categories with counts
    GET /api/masters/service-categories/
    """
    from django.db.models import Count
    
    user = request.user
    
    if not user.tenant and not user.is_superuser:
        return Response({'categories': []})
    
    # Get available services
    if user.is_superuser:
        services = ServiceItem.objects.filter(is_active=True)
    else:
        services = ServiceItem.objects.filter(
            Q(is_system_wide=True) | Q(tenant=user.tenant),
            is_active=True
        )
    
    # Group by category with counts
    categories = services.values('service_category').annotate(
        count=Count('id')
    ).order_by('service_category')
    
    # Format response
    formatted_categories = []
    for cat in categories:
        formatted_categories.append({
            'value': cat['service_category'],
            'label': dict(ServiceItem.SERVICE_CATEGORY_CHOICES).get(
                cat['service_category'],
                cat['service_category']
            ),
            'count': cat['count']
        })
    
    return Response({'categories': formatted_categories})

#this is used for items in sidebar for service and products only
class ItemUnitViewSet(viewsets.ModelViewSet):
    serializer_class = ItemUnitSerializer
    permission_classes = [IsAuthenticated, IsManagement]

    def get_queryset(self):
        user = self.request.user

        if user.is_superuser:
            return ItemUnit.objects.filter(is_active=True)

        if not user.tenant:
            return ItemUnit.objects.none()

        return ItemUnit.objects.filter(
            tenant=user.tenant,
            is_active=True
        ).order_by('display_order', 'name')

    def perform_create(self, serializer):
        user = self.request.user

        if not user.tenant:
            raise ValidationError("Tenant not resolved")

        serializer.save(tenant=user.tenant)

class ItemUnitViewSet(viewsets.ModelViewSet):
    serializer_class = ItemUnitSerializer
    permission_classes = [IsAuthenticated]
    queryset = ItemUnit.objects.all()
    
    def get_queryset(self):
        queryset = ItemUnit.objects.all()
        
        # Filter by active status
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            is_active_bool = is_active.lower() in ['true', '1']
            queryset = queryset.filter(is_active=is_active_bool)
        
        return queryset.order_by('name')
