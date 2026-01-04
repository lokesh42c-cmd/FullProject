"""
URL routing for masters app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from .views import ItemUnitViewSet

app_name = 'masters'

# Create router for ViewSets
router = DefaultRouter()

router.register(r'categories', views.ItemCategoryViewSet, basename='categories')
router.register(r'units', views.UnitViewSet, basename='units')
router.register(r'measurement-fields', views.MeasurementFieldViewSet, basename='measurement-fields')
router.register(r'configs', views.TenantMeasurementConfigViewSet, basename='configs')
router.register(r'service-items', views.ServiceItemViewSet, basename='service-item')
router.register(r'item-units', views.ItemUnitViewSet, basename='item-unit') 
urlpatterns = [
    # Additional endpoints (MUST come BEFORE router.urls)
    
    path('categories/grouped/', views.get_categories_by_type, name='categories-grouped'),
    path('measurement-form/<int:category_id>/', views.get_measurement_form, name='measurement-form'),
    path('service-categories/', views.get_service_categories, name='service-categories'),
    # ViewSet routes
    path('', include(router.urls)),
    
]