"""
Signals for automatic subscription creation
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from datetime import timedelta
from .models import Tenant, SubscriptionPlan, TenantSubscription


@receiver(post_save, sender=Tenant)
def create_tenant_subscription(sender, instance, created, **kwargs):
    """
    Automatically create a FREE trial subscription when a new tenant is created.
    This ensures every new shop gets 14-day free trial immediately.
    """
    if created:
        try:
            # Get or create FREE plan
            free_plan, plan_created = SubscriptionPlan.objects.get_or_create(
                plan_type='FREE',
                defaults={
                    'name': 'Free Trial',
                    'description': '14-day free trial with basic features',
                    'price_monthly': 0,
                    'price_yearly': 0,
                    'max_orders_per_month': 10,
                    'max_customers': 50,
                    'max_staff_users': 1,
                    'max_inventory_items': 20,
                    'has_inventory': False,
                    'has_advanced_reports': False,
                    'has_api_access': False,
                    'has_custom_fields': False,
                    'has_whatsapp_integration': False,
                    'has_data_export': False,
                    'has_multi_location': False,
                    'is_active': True,
                    'is_visible': True,
                    'display_order': 0
                }
            )
            
            # Calculate dates
            now = timezone.now()
            trial_ends = now + timedelta(days=14)  # 14-day trial
            period_end = now + timedelta(days=30)   # 30-day billing period
            
            # Create subscription
            TenantSubscription.objects.create(
                tenant=instance,
                plan=free_plan,
                status='TRIAL',
                billing_cycle='MONTHLY',
                trial_ends_at=trial_ends,
                current_period_start=now,
                current_period_end=period_end,
                current_month_orders=0,
                total_customers=0,
                total_staff_users=1,  # Owner counts as 1
                total_inventory_items=0
            )
            
            print(f"✅ Created FREE trial subscription for tenant: {instance.name}")
            
        except Exception as e:
            print(f"❌ Error creating subscription for tenant {instance.name}: {str(e)}")
