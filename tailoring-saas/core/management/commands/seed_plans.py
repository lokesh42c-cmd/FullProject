"""
Management command to seed subscription plans
Usage: python manage.py seed_plans
"""
from django.core.management.base import BaseCommand
from core.models import SubscriptionPlan


class Command(BaseCommand):
    help = 'Seed subscription plans (FREE, STARTER, PROFESSIONAL, ENTERPRISE)'
    
    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding subscription plans...')
        
        plans_data = [
            {
                'name': 'Free Trial',
                'plan_type': 'FREE',
                'description': '14-day free trial with basic features to get started',
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
            },
            {
                'name': 'Starter',
                'plan_type': 'STARTER',
                'description': 'Perfect for small tailoring shops just starting out',
                'price_monthly': 999,
                'price_yearly': 9990,  # ~₹833/month (17% discount)
                'max_orders_per_month': 100,
                'max_customers': 500,
                'max_staff_users': 3,
                'max_inventory_items': 100,
                'has_inventory': True,
                'has_advanced_reports': False,
                'has_api_access': False,
                'has_custom_fields': False,
                'has_whatsapp_integration': False,
                'has_data_export': True,
                'has_multi_location': False,
                'is_active': True,
                'is_visible': True,
                'display_order': 1
            },
            {
                'name': 'Professional',
                'plan_type': 'PROFESSIONAL',
                'description': 'For established businesses with growing customer base',
                'price_monthly': 2999,
                'price_yearly': 29990,  # ~₹2499/month (17% discount)
                'max_orders_per_month': None,  # Unlimited
                'max_customers': None,  # Unlimited
                'max_staff_users': 10,
                'max_inventory_items': None,  # Unlimited
                'has_inventory': True,
                'has_advanced_reports': True,
                'has_api_access': True,
                'has_custom_fields': True,
                'has_whatsapp_integration': True,
                'has_data_export': True,
                'has_multi_location': False,
                'is_active': True,
                'is_visible': True,
                'display_order': 2
            },
            {
                'name': 'Enterprise',
                'plan_type': 'ENTERPRISE',
                'description': 'For large tailoring businesses with multiple locations',
                'price_monthly': 9999,
                'price_yearly': 99990,  # ~₹8332/month (17% discount)
                'max_orders_per_month': None,  # Unlimited
                'max_customers': None,  # Unlimited
                'max_staff_users': None,  # Unlimited
                'max_inventory_items': None,  # Unlimited
                'has_inventory': True,
                'has_advanced_reports': True,
                'has_api_access': True,
                'has_custom_fields': True,
                'has_whatsapp_integration': True,
                'has_data_export': True,
                'has_multi_location': True,
                'is_active': True,
                'is_visible': True,
                'display_order': 3
            }
        ]
        
        created_count = 0
        updated_count = 0
        
        for plan_data in plans_data:
            plan, created = SubscriptionPlan.objects.update_or_create(
                plan_type=plan_data['plan_type'],
                defaults=plan_data
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Created plan: {plan.name}')
                )
            else:
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(f'↻ Updated plan: {plan.name}')
                )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'\nSuccessfully seeded subscription plans!\n'
                f'Created: {created_count}, Updated: {updated_count}'
            )
        )
