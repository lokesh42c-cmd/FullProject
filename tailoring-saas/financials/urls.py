"""
Financials app URLs
Date: 2026-01-03
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create router for API viewsets
router = DefaultRouter()
router.register(r'receipts', views.ReceiptVoucherViewSet, basename='receipt')
router.register(r'payments', views.PaymentViewSet, basename='payment')
router.register(r'refunds', views.RefundVoucherViewSet, basename='refund')

app_name = 'financials'

urlpatterns = [
    # API routes
    path('', include(router.urls)),
]
