"""
Invoicing app URLs
Date: 2026-01-03
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create router for API viewsets
router = DefaultRouter()
router.register(r'invoices', views.InvoiceViewSet, basename='invoice')
router.register(r'invoice-items', views.InvoiceItemViewSet, basename='invoiceitem')

app_name = 'invoicing'

urlpatterns = [
    # API routes
    path('', include(router.urls)),
]