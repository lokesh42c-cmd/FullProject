"""
URL Configuration for Tailoring SaaS project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # Django Admin
    path('admin/', admin.site.urls),
    
    # API URLs
    path('api/auth/', include('core.urls')),
    path('api/masters/', include('masters.urls')),
     path('api/orders/', include('orders.urls')),
     path('api/employees/', include('employees.urls')),
   #  path('api/inventory/', include('inventory.urls')),
    # path('api/purchase/', include('purchase_management.urls')),
    path('api/invoicing/', include('invoicing.urls')),
    path('api/financials/', include('financials.urls')),
    path('api/appointments/', include('appointments.urls')),

]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Customize admin site
admin.site.site_header = "Tailoring SaaS Administration"
admin.site.site_title = "Tailoring SaaS Admin"
admin.site.index_title = "Welcome to Tailoring SaaS Admin Panel"
