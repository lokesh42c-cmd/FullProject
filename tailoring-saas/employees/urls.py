from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    DepartmentViewSet,
    EmployeeViewSet,
    AttendanceViewSet,
    ShopSettingsViewSet
)

router = DefaultRouter()
router.register(r'departments', DepartmentViewSet, basename='department')
router.register(r'employees', EmployeeViewSet, basename='employee')
router.register(r'attendance', AttendanceViewSet, basename='attendance')
router.register(r'shop-settings', ShopSettingsViewSet, basename='shop-settings')

urlpatterns = [
    path('', include(router.urls)),
]