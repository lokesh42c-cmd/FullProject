"""
Purchase Management URLs
All API endpoints for vendors, bills, expenses, and payments
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create router for API viewsets
router = DefaultRouter()

# Register ViewSets (NOT functions!)
router.register(r'vendors', views.VendorViewSet, basename='vendor')
router.register(r'bills', views.PurchaseBillViewSet, basename='bill')
router.register(r'expenses', views.ExpenseViewSet, basename='expense')
router.register(r'payments', views.PaymentViewSet, basename='payment')


app_name = 'purchase_management'

urlpatterns = [
    path('', include(router.urls)),
]

"""
AVAILABLE ENDPOINTS:
====================

VENDORS:
  GET    /api/purchase/vendors/                     - List all vendors
  POST   /api/purchase/vendors/                     - Create vendor
  GET    /api/purchase/vendors/{id}/                - Get vendor detail
  PUT    /api/purchase/vendors/{id}/                - Update vendor
  DELETE /api/purchase/vendors/{id}/                - Delete vendor
  GET    /api/purchase/vendors/with_outstanding/    - Vendors with balance
  GET    /api/purchase/vendors/summary/             - Vendor summary
  GET    /api/purchase/vendors/{id}/bills/          - Vendor's bills

PURCHASE BILLS:
  GET    /api/purchase/bills/                       - List all bills
  POST   /api/purchase/bills/                       - Create bill
  GET    /api/purchase/bills/{id}/                  - Get bill detail
  PUT    /api/purchase/bills/{id}/                  - Update bill
  DELETE /api/purchase/bills/{id}/                  - Delete bill
  GET    /api/purchase/bills/unpaid/                - Unpaid bills
  GET    /api/purchase/bills/by_vendor/             - Bills by vendor (query: ?vendor_id=X)
  GET    /api/purchase/bills/summary/               - Bills summary
  GET    /api/purchase/bills/{id}/payments/         - Bill's payments

EXPENSES:
  GET    /api/purchase/expenses/                    - List all expenses
  POST   /api/purchase/expenses/                    - Create expense
  GET    /api/purchase/expenses/{id}/               - Get expense detail
  PUT    /api/purchase/expenses/{id}/               - Update expense
  DELETE /api/purchase/expenses/{id}/               - Delete expense
  GET    /api/purchase/expenses/by_category/        - Expenses by category
  GET    /api/purchase/expenses/summary/            - Expenses summary
  GET    /api/purchase/expenses/{id}/payments/      - Expense's payments

PAYMENTS:
  GET    /api/purchase/payments/                    - List all payments
  POST   /api/purchase/payments/                    - Create payment
  GET    /api/purchase/payments/{id}/               - Get payment detail
  DELETE /api/purchase/payments/{id}/               - Delete payment
  GET    /api/purchase/payments/today/              - Today's payments
  GET    /api/purchase/payments/by_date_range/      - Payments by date range
  GET    /api/purchase/payments/summary/            - Payments summary
  GET    /api/purchase/payments/by_method/          - Payments by method

DASHBOARD:
  GET    /api/purchase/dashboard/overview/          - Complete overview stats

QUERY PARAMETERS:
  ?search=term          - Search in relevant fields
  ?ordering=field       - Sort by field (prefix - for desc)
  ?page=N              - Page number for pagination
  ?page_size=N         - Items per page
  
  Vendor filters:
    ?is_active=true/false
  
  Bill filters:
    ?payment_status=UNPAID/PARTIALLY_PAID/FULLY_PAID
    ?vendor=vendor_id
    ?start_date=YYYY-MM-DD
    ?end_date=YYYY-MM-DD
  
  Expense filters:
    ?category=RENT/ELECTRICITY/etc
    ?payment_status=UNPAID/PARTIALLY_PAID/FULLY_PAID
  
  Payment filters:
    ?payment_type=PURCHASE_BILL/EXPENSE
    ?payment_method=CASH/UPI/BANK_TRANSFER/CARD/CHEQUE
"""