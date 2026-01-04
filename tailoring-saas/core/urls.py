"""
URL patterns for Core app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from . import views
from . import subscription_views
from .views import RegistrationView, LoginView, ProfileView, dashboard_stats  


# Router for staff management
router = DefaultRouter()
router.register(r'staff', views.StaffViewSet, basename='staff')

# Router for subscriptions
subscription_router = DefaultRouter()
subscription_router.register(r'plans', subscription_views.SubscriptionPlanViewSet, basename='subscription-plan')
subscription_router.register(r'my-subscription', subscription_views.TenantSubscriptionViewSet, basename='tenant-subscription')

app_name = 'core'

urlpatterns = [
    # JWT Authentication
    path('register/', views.RegistrationView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('dashboard/stats/', views.dashboard_stats, name='dashboard-stats'),
    # Staff management routes
    path('', include(router.urls)),

    # Subscription routes
    path('subscriptions/', include(subscription_router.urls)),
]