"""
Serializers for Subscription Management
"""

from rest_framework import serializers
from .models import SubscriptionPlan, TenantSubscription
from .subscription_utils import get_plan_features


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    """Subscription plan serializer for public listing"""
    
    features = serializers.SerializerMethodField()
    is_current_plan = serializers.SerializerMethodField()
    
    class Meta:
        model = SubscriptionPlan
        fields = [
            'id', 'tier', 'name', 'description',
            'price_monthly', 'price_yearly',
            'trial_days', 'is_popular',
            'features', 'is_current_plan',
            'display_order'
        ]
    
    def get_features(self, obj):
        """Get list of features for this plan"""
        return get_plan_features(obj)
    
    def get_is_current_plan(self, obj):
        """Check if this is user's current plan"""
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            try:
                subscription = request.user.tenant.subscription
                return subscription.plan.id == obj.id
            except:
                pass
        return False


class SubscriptionPlanDetailSerializer(serializers.ModelSerializer):
    """Detailed plan serializer with all limits"""
    
    features = serializers.SerializerMethodField()
    
    class Meta:
        model = SubscriptionPlan
        fields = [
            'id', 'tier', 'name', 'description',
            'price_monthly', 'price_yearly', 'trial_days',
            
            # Limits
            'max_orders_per_month', 'max_customers', 'max_employees',
            'max_users', 'max_inventory_items', 'max_vendors',
            'max_photos_per_order',
            
            # Features
            'allow_b2b_customers', 'allow_measurement_profiles',
            'allow_gst_invoicing', 'allow_item_discount',
            'allow_invoice_customization',
            'allow_inventory', 'allow_barcode_sku', 'allow_purchase_orders',
            'allow_employee_management', 'allow_attendance',
            'allow_leave_management', 'allow_payroll',
            'allow_workflow', 'max_workflow_stages',
            'allow_task_assignment', 'allow_qa_system', 'allow_trial_feedback',
            'allow_order_qr', 'allow_employee_qr',
            'report_types', 'allow_data_export', 'allow_api_access',
            'support_level',
            
            'features', 'is_popular'
        ]
    
    def get_features(self, obj):
        """Get list of features"""
        return get_plan_features(obj)


class TenantSubscriptionSerializer(serializers.ModelSerializer):
    """Tenant subscription serializer"""
    
    plan_details = SubscriptionPlanSerializer(source='plan', read_only=True)
    days_left = serializers.SerializerMethodField()
    usage_stats = serializers.SerializerMethodField()
    is_trial = serializers.SerializerMethodField()
    
    class Meta:
        model = TenantSubscription
        fields = [
            'id', 'plan', 'plan_details', 'status', 'billing_cycle',
            'start_date', 'end_date', 'trial_end_date',
            'is_trial', 'days_left', 'auto_renew',
            'usage_stats', 'created_at'
        ]
        read_only_fields = ['created_at']
    
    def get_days_left(self, obj):
        """Get days remaining"""
        return obj.days_remaining()
    
    def get_is_trial(self, obj):
        """Check if in trial"""
        return obj.is_trial()
    
    def get_usage_stats(self, obj):
        """Get usage statistics"""
        plan = obj.plan
        tenant = obj.tenant
        
        from employees.models import Employee
        from orders.models import Customer, Vendor
        from inventory.models import InventoryItem
        from core.models import User
        
        stats = {
            'orders': {
                'used': obj.orders_this_month,
                'limit': plan.max_orders_per_month,
                'unlimited': plan.max_orders_per_month == 0,
                'percentage': 0
            },
            'employees': {
                'used': Employee.objects.filter(tenant=tenant, is_active=True).count() if plan.allow_employee_management else 0,
                'limit': plan.max_employees,
                'unlimited': plan.max_employees == 0
            },
            'customers': {
                'used': Customer.objects.filter(tenant=tenant, is_active=True).count(),
                'limit': plan.max_customers,
                'unlimited': plan.max_customers == 0
            },
            'inventory_items': {
                'used': InventoryItem.objects.filter(tenant=tenant, is_active=True).count() if plan.allow_inventory else 0,
                'limit': plan.max_inventory_items,
                'unlimited': plan.max_inventory_items == 0
            },
            'vendors': {
                'used': Vendor.objects.filter(tenant=tenant, is_active=True).count() if plan.allow_purchase_orders else 0,
                'limit': plan.max_vendors,
                'unlimited': plan.max_vendors == 0
            },
            'users': {
                'used': User.objects.filter(tenant=tenant, is_active=True).count(),
                'limit': plan.max_users,
                'unlimited': plan.max_users == 0
            }
        }
        
        # Calculate percentages
        for key, value in stats.items():
            if not value['unlimited'] and value['limit'] > 0:
                value['percentage'] = int((value['used'] / value['limit']) * 100)
            else:
                value['percentage'] = 0
        
        return stats


class UpgradeSubscriptionSerializer(serializers.Serializer):
    """Serializer for upgrading subscription"""
    
    new_plan_id = serializers.IntegerField(required=True)
    billing_cycle = serializers.ChoiceField(
        choices=['MONTHLY', 'YEARLY'],
        default='MONTHLY'
    )
