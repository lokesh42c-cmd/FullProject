"""
Orders app URLs - Simplified for GST Compliance
Date: 2026-01-03
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create router for API viewsets
router = DefaultRouter()
router.register(r'customers', views.CustomerViewSet, basename='customer')
router.register(r'orders', views.OrderViewSet, basename='order')
router.register(r'order-items', views.OrderItemViewSet, basename='orderitem')
router.register(r'items', views.ItemViewSet, basename='item')
router.register(r'item-units', views.ItemUnitViewSet, basename='itemunit')

app_name = 'orders'

urlpatterns = [
    # API routes
    path('', include(router.urls)),
]


# ==================== DEPRECATED ROUTES (COMMENTED OUT) ====================

"""
# OLD FAMILY MEMBER ROUTES - REMOVED
# router.register(r'family-members', views.FamilyMemberViewSet, basename='familymember')
# router.register(r'measurements', views.FamilyMemberMeasurementViewSet, basename='measurement')

# OLD INVOICE/PAYMENT ROUTES - MOVED TO SEPARATE APPS
# router.register(r'invoices', views.InvoiceViewSet, basename='invoice')
# router.register(r'payments', views.OrderPaymentViewSet, basename='payment')

# OLD WORKFLOW ROUTES - COMMENTED FOR NOW
# router.register(r'workflow/stages', workflow_views.WorkflowStageViewSet, basename='workflow-stage')
# router.register(r'workflow/tasks', workflow_views.TaskAssignmentViewSet, basename='task')

# OLD INVOICE PDF ROUTES - MOVED TO INVOICING APP
# path('invoice/<int:invoice_id>/pdf/', views.download_invoice_pdf, name='invoice_pdf')
# path('invoice/<int:invoice_id>/view/', views.view_invoice_pdf, name='invoice_view')
"""