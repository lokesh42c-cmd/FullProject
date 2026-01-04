"""
Tests for core app
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from .models import Tenant, SubscriptionPlan, TenantSubscription

User = get_user_model()


class TenantModelTest(TestCase):
    """Test Tenant model"""
    
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name="Test Shop",
            email="test@shop.com",
            phone_number="9876543210",
            city="Bangalore",
            state="Karnataka"
        )
    
    def test_tenant_creation(self):
        """Test tenant is created correctly"""
        self.assertEqual(self.tenant.name, "Test Shop")
        self.assertTrue(self.tenant.is_active)
        self.assertIsNotNone(self.tenant.slug)
    
    def test_slug_generation(self):
        """Test slug is auto-generated"""
        self.assertEqual(self.tenant.slug, "test-shop")


class UserModelTest(TestCase):
    """Test User model"""
    
    def setUp(self):
        self.tenant = Tenant.objects.create(
            name="Test Shop",
            email="test@shop.com",
            phone_number="9876543210",
            city="Bangalore",
            state="Karnataka"
        )
        
        self.user = User.objects.create_user(
            email="user@test.com",
            name="Test User",
            password="testpass123",
            tenant=self.tenant,
            role="OWNER"
        )
    
    def test_user_creation(self):
        """Test user is created correctly"""
        self.assertEqual(self.user.email, "user@test.com")
        self.assertEqual(self.user.name, "Test User")
        self.assertEqual(self.user.role, "OWNER")
        self.assertTrue(self.user.check_password("testpass123"))
    
    def test_user_tenant_relation(self):
        """Test user-tenant relationship"""
        self.assertEqual(self.user.tenant, self.tenant)


class SubscriptionTest(TestCase):
    """Test Subscription system"""
    
    def setUp(self):
        # Create plan
        self.plan = SubscriptionPlan.objects.create(
            name="Test Plan",
            plan_type="FREE",
            price_monthly=0,
            max_orders_per_month=10,
            max_customers=50
        )
        
        # Create tenant (subscription auto-created by signal)
        self.tenant = Tenant.objects.create(
            name="Test Shop",
            email="test@shop.com",
            phone_number="9876543210",
            city="Bangalore",
            state="Karnataka"
        )
    
    def test_auto_subscription_creation(self):
        """Test subscription is auto-created on tenant creation"""
        self.assertTrue(hasattr(self.tenant, 'subscription'))
        self.assertEqual(self.tenant.subscription.plan.plan_type, 'FREE')
        self.assertEqual(self.tenant.subscription.status, 'TRIAL')
    
    def test_subscription_limits(self):
        """Test subscription limit checking"""
        subscription = self.tenant.subscription
        
        # Should be able to create orders (0 < 10)
        self.assertTrue(subscription.can_create_order())
        
        # Simulate reaching limit
        subscription.current_month_orders = 10
        subscription.save()
        
        # Should not be able to create more orders
        self.assertFalse(subscription.can_create_order())

# Add more tests as needed
