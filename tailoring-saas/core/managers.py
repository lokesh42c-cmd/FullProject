"""
Custom managers for tenant isolation
Ensures all queries are automatically filtered by current tenant
"""

from django.db import models


class TenantManager(models.Manager):
    """
    Manager that automatically filters queries by current tenant
    Prevents data leakage between tenants (shops)
    
    Usage in models:
        objects = TenantManager()  # Auto-filters by tenant
        all_objects = models.Manager()  # Bypass filter (admin only)
    """
    
    def get_queryset(self):
        """Override to add automatic tenant filter"""
        from .middleware import get_current_tenant
        
        # Get base queryset
        qs = super().get_queryset()
        
        # Get current tenant from thread-local storage
        tenant = get_current_tenant()
        
        # Filter by tenant if one is set
        if tenant:
            return qs.filter(tenant=tenant)
        
        # Return unfiltered if no tenant (e.g., superuser)
        return qs