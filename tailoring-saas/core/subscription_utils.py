"""
Subscription & Feature Check Utilities
"""

from functools import wraps
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone


def require_active_subscription(view_func):
    """
    Decorator to check if tenant has active subscription
    """
    @wraps(view_func)
    def wrapper(self, request, *args, **kwargs):
        tenant = request.user.tenant
        
        if not tenant:
            return Response({
                'error': 'No tenant associated with user'
            }, status=status.HTTP_403_FORBIDDEN)
        
        try:
            subscription = tenant.subscription
        except:
            return Response({
                'error': 'No active subscription',
                'message': 'Please subscribe to a plan to continue',
                'subscribe_url': '/api/subscriptions/plans/'
            }, status=status.HTTP_402_PAYMENT_REQUIRED)
        
        if not subscription.is_active():
            return Response({
                'error': 'Subscription expired',
                'message': f'Your subscription expired. Please renew.',
                'status': subscription.status,
                'renew_url': '/api/subscriptions/renew/'
            }, status=status.HTTP_402_PAYMENT_REQUIRED)
        
        return view_func(self, request, *args, **kwargs)
    
    return wrapper


def require_feature(feature_flag):
    """
    Decorator to check if plan allows specific feature
    
    Usage:
        @require_feature('allow_gst_invoicing')
        def create_gst_invoice(self, request):
            ...
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(self, request, *args, **kwargs):
            tenant = request.user.tenant
            
            try:
                subscription = tenant.subscription
                plan = subscription.plan
                
                # Check if feature is allowed
                feature_value = getattr(plan, feature_flag, False)
                
                # Handle different feature types
                if isinstance(feature_value, bool):
                    if not feature_value:
                        return feature_not_allowed_response(feature_flag, plan)
                elif isinstance(feature_value, str):
                    if feature_value == 'NONE':
                        return feature_not_allowed_response(feature_flag, plan)
                
            except Exception as e:
                return Response({
                    'error': 'Subscription error',
                    'message': str(e)
                }, status=status.HTTP_403_FORBIDDEN)
            
            return view_func(self, request, *args, **kwargs)
        
        return wrapper
    return decorator


def check_order_limit(view_func):
    """
    Decorator to check monthly order limit before creating order
    """
    @wraps(view_func)
    def wrapper(self, request, *args, **kwargs):
        tenant = request.user.tenant
        
        try:
            subscription = tenant.subscription
            can_create, error_msg = subscription.can_create_order()
            
            if not can_create:
                plan = subscription.plan
                return Response({
                    'error': 'Order limit reached',
                    'message': error_msg,
                    'current_plan': plan.name,
                    'limit': plan.max_orders_per_month,
                    'used': subscription.orders_this_month,
                    'upgrade_url': '/api/subscriptions/upgrade/'
                }, status=status.HTTP_402_PAYMENT_REQUIRED)
            
        except Exception as e:
            return Response({
                'error': 'Subscription check failed',
                'message': str(e)
            }, status=status.HTTP_403_FORBIDDEN)
        
        return view_func(self, request, *args, **kwargs)
    
    return wrapper


def check_resource_limit(limit_field):
    """
    Decorator to check resource limits (employees, customers, etc.)
    
    Usage:
        @check_resource_limit('max_employees')
        def create_employee(self, request):
            ...
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(self, request, *args, **kwargs):
            tenant = request.user.tenant
            
            try:
                subscription = tenant.subscription
                plan = subscription.plan
                max_limit = getattr(plan, limit_field, 0)
                
                # 0 means unlimited
                if max_limit == 0:
                    return view_func(self, request, *args, **kwargs)
                
                # Get current count
                current_count = get_current_count(tenant, limit_field)
                
                if current_count >= max_limit:
                    resource_name = limit_field.replace('max_', '').replace('_', ' ')
                    
                    return Response({
                        'error': 'Limit reached',
                        'message': f'{resource_name.title()} limit reached for your plan',
                        'limit': max_limit,
                        'current': current_count,
                        'current_plan': plan.name,
                        'upgrade_url': '/api/subscriptions/upgrade/'
                    }, status=status.HTTP_402_PAYMENT_REQUIRED)
                
            except Exception as e:
                return Response({
                    'error': 'Subscription error',
                    'message': str(e)
                }, status=status.HTTP_403_FORBIDDEN)
            
            return view_func(self, request, *args, **kwargs)
        
        return wrapper
    return decorator


def get_current_count(tenant, limit_field):
    """Get current count for a limit field"""
    
    if limit_field == 'max_employees':
        from employees.models import Employee
        return Employee.objects.filter(tenant=tenant, is_active=True).count()
    
    elif limit_field == 'max_customers':
        from orders.models import Customer
        return Customer.objects.filter(tenant=tenant, is_active=True).count()
    
    elif limit_field == 'max_inventory_items':
        from inventory.models import InventoryItem
        return InventoryItem.objects.filter(tenant=tenant, is_active=True).count()
    
    elif limit_field == 'max_vendors':
        from orders.models import Vendor
        return Vendor.objects.filter(tenant=tenant, is_active=True).count()
    
    elif limit_field == 'max_users':
        from core.models import User
        return User.objects.filter(tenant=tenant, is_active=True).count()
    
    return 0


def feature_not_allowed_response(feature_flag, plan):
    """Generate response for feature not allowed"""
    feature_name = feature_flag.replace('allow_', '').replace('_', ' ').title()
    
    # Get plans that have this feature
    from core.models import SubscriptionPlan
    
    available_plans = SubscriptionPlan.objects.filter(
        **{feature_flag: True},
        is_active=True
    ).values_list('name', 'price_monthly')
    
    upgrade_options = [
        {'name': name, 'price': float(price)}
        for name, price in available_plans
    ]
    
    return Response({
        'error': 'Feature not available',
        'message': f'{feature_name} is not available in your {plan.name} plan',
        'feature': feature_name,
        'current_plan': plan.name,
        'available_in': upgrade_options,
        'upgrade_url': '/api/subscriptions/upgrade/'
    }, status=status.HTTP_402_PAYMENT_REQUIRED)


def get_plan_features(plan):
    """Get list of enabled features for a plan"""
    features = []
    
    # Orders
    if plan.max_orders_per_month > 0:
        features.append(f"{plan.max_orders_per_month} orders/month")
    else:
        features.append("Unlimited orders")
    
    # Customers
    if plan.max_customers > 0:
        features.append(f"Up to {plan.max_customers} customers")
    else:
        features.append("Unlimited customers")
    
    # Employees
    if plan.allow_employee_management:
        if plan.max_employees > 0:
            features.append(f"Up to {plan.max_employees} employees")
        else:
            features.append("Unlimited employees")
    
    # GST
    if plan.allow_gst_invoicing:
        features.append("GST-compliant invoicing")
    
    # Inventory
    if plan.allow_inventory:
        features.append("Inventory management")
        if plan.allow_barcode_sku:
            features.append("Barcode/SKU support")
    
    # Workflow
    if plan.allow_workflow:
        features.append("Workshop workflow tracking")
        if plan.allow_task_assignment:
            features.append("Task assignment system")
        if plan.allow_qa_system:
            features.append("Quality control system")
    
    # Attendance
    if plan.allow_attendance == 'QR_SCAN':
        features.append("QR code attendance")
    elif plan.allow_attendance == 'MANUAL':
        features.append("Manual attendance")
    
    # Measurements
    if plan.allow_measurement_profiles:
        features.append("Measurement profiles")
    
    # B2B
    if plan.allow_b2b_customers:
        features.append("B2B customer support")
    
    # Data export
    if plan.allow_data_export:
        features.append("Data export (Excel/PDF)")
    
    # API
    if plan.allow_api_access:
        features.append("API access")
    
    return features

def increment_order_count(tenant):
    """
    Increment order count for tenant's subscription tracking
    
    Args:
        tenant: Tenant instance
    """
    from core.models import TenantSubscription  # ← Changed from Subscription
    import logging
    
    logger = logging.getLogger(__name__)
    
    try:
        # Get active subscription for tenant
        subscription = TenantSubscription.objects.filter(
            tenant=tenant,
            status='ACTIVE'
        ).first()
        
        if subscription:
            # Increment order count (if field exists)
            if hasattr(subscription, 'orders_created'):
                subscription.orders_created = (subscription.orders_created or 0) + 1
                subscription.save(update_fields=['orders_created'])
                
                logger.info(
                    f'Order count incremented for tenant {tenant.name}: '
                    f'{subscription.orders_created} orders'
                )
            else:
                logger.info(f'Order created for tenant {tenant.name}')
        else:
            logger.warning(f'No active subscription found for tenant {tenant.name}')
            
    except Exception as e:
        # Don't fail order creation if subscription tracking fails
        logger.error(f'Error incrementing order count for tenant {tenant.id}: {str(e)}')
        pass

