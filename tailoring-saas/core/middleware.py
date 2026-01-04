"""
Middleware for tenant isolation
Sets current tenant in thread-local storage on every request
"""

from threading import local

# Thread-local storage for current tenant
_thread_locals = local()


def get_current_tenant():
    """
    Get current tenant from thread-local storage
    
    Returns:
        Tenant object or None
    """
    return getattr(_thread_locals, 'tenant', None)


def set_current_tenant(tenant):
    """
    Set current tenant in thread-local storage
    
    Args:
        tenant: Tenant object or None
    """
    _thread_locals.tenant = tenant


class TenantMiddleware:
    """
    Middleware to automatically set current tenant from authenticated user
    
    This runs on EVERY request and ensures:
    1. Current tenant is set from logged-in user
    2. All database queries are filtered by tenant
    3. Thread-local storage is cleaned after request
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        """Process the request"""
        
        # Reset tenant at start of each request
        set_current_tenant(None)
        
        # Set tenant if user is authenticated
        if request.user.is_authenticated:
            # Superuser can see all data
            if request.user.is_superuser:
                set_current_tenant(None)
            # Regular users only see their tenant's data
            elif hasattr(request.user, 'tenant') and request.user.tenant:
                set_current_tenant(request.user.tenant)
        
        # Process the request
        response = self.get_response(request)
        
        # Clean up thread-local storage after request
        set_current_tenant(None)
        
        return response
    
    def process_exception(self, request, exception):
        """Clean up even if there's an exception"""
        set_current_tenant(None)
        return None