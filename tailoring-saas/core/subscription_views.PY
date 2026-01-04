"""
API Views for Subscription Management
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.utils import timezone
from datetime import timedelta

from .models import SubscriptionPlan, TenantSubscription
from .subscription_serializers import (
    SubscriptionPlanSerializer,
    SubscriptionPlanDetailSerializer,
    TenantSubscriptionSerializer,
    UpgradeSubscriptionSerializer
)


class SubscriptionPlanViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public subscription plans
    GET /api/core/subscriptions/plans/
    """
    queryset = SubscriptionPlan.objects.filter(is_active=True).order_by('display_order')
    permission_classes = [AllowAny]
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return SubscriptionPlanDetailSerializer
        return SubscriptionPlanSerializer
    
    @action(detail=False, methods=['get'])
    def compare(self, request):
        """
        Compare all plans side by side
        GET /api/core/subscriptions/plans/compare/
        """
        plans = self.get_queryset()
        serializer = SubscriptionPlanDetailSerializer(
            plans, 
            many=True,
            context={'request': request}
        )
        
        return Response({
            'plans': serializer.data
        })


class TenantSubscriptionViewSet(viewsets.ModelViewSet):
    """
    Tenant subscription management
    """
    serializer_class = TenantSubscriptionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Get subscription for current tenant"""
        if self.request.user.tenant:
            return TenantSubscription.objects.filter(
                tenant=self.request.user.tenant
            )
        return TenantSubscription.objects.none()
    
    @action(detail=False, methods=['get'])
    def current(self, request):
        """
        Get current subscription details
        GET /api/core/subscriptions/my-subscription/current/
        """
        try:
            subscription = request.user.tenant.subscription
            serializer = self.get_serializer(subscription)
            
            return Response({
                'subscription': serializer.data,
                'is_active': subscription.is_active(),
                'status_message': self.get_status_message(subscription)
            })
        
        except:
            return Response({
                'error': 'No active subscription',
                'message': 'Please subscribe to a plan'
            }, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def upgrade(self, request):
        """
        Upgrade/change subscription plan
        POST /api/core/subscriptions/my-subscription/upgrade/
        {
            "new_plan_id": 3,
            "billing_cycle": "MONTHLY"
        }
        """
        serializer = UpgradeSubscriptionSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        tenant = request.user.tenant
        new_plan_id = serializer.validated_data['new_plan_id']
        billing_cycle = serializer.validated_data['billing_cycle']
        
        try:
            new_plan = SubscriptionPlan.objects.get(id=new_plan_id, is_active=True)
        except SubscriptionPlan.DoesNotExist:
            return Response({
                'error': 'Invalid plan'
            }, status=status.HTTP_404_NOT_FOUND)
        
        try:
            subscription = tenant.subscription
            old_plan = subscription.plan
            
            # Update subscription
            subscription.plan = new_plan
            subscription.billing_cycle = billing_cycle
            subscription.status = 'ACTIVE'
            
            # Extend subscription period
            if billing_cycle == 'YEARLY':
                subscription.end_date = timezone.now().date() + timedelta(days=365)
            else:
                subscription.end_date = timezone.now().date() + timedelta(days=30)
            
            subscription.save()
            
            result_serializer = TenantSubscriptionSerializer(subscription, context={'request': request})
            
            return Response({
                'message': f'Successfully upgraded from {old_plan.name} to {new_plan.name}',
                'subscription': result_serializer.data
            })
        
        except:
            # No existing subscription, create new one
            subscription = TenantSubscription.objects.create(
                tenant=tenant,
                plan=new_plan,
                billing_cycle=billing_cycle,
                status='ACTIVE',
                start_date=timezone.now().date(),
                end_date=timezone.now().date() + timedelta(days=365 if billing_cycle == 'YEARLY' else 30)
            )
            
            result_serializer = TenantSubscriptionSerializer(subscription, context={'request': request})
            
            return Response({
                'message': f'Successfully subscribed to {new_plan.name}',
                'subscription': result_serializer.data
            }, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['post'])
    def cancel(self, request):
        """
        Cancel subscription
        POST /api/core/subscriptions/my-subscription/cancel/
        """
        try:
            subscription = request.user.tenant.subscription
            subscription.status = 'CANCELLED'
            subscription.auto_renew = False
            subscription.save()
            
            return Response({
                'message': 'Subscription cancelled successfully',
                'message_detail': f'Your subscription will remain active until {subscription.end_date}'
            })
        
        except:
            return Response({
                'error': 'No active subscription found'
            }, status=status.HTTP_404_NOT_FOUND)
    
    def get_status_message(self, subscription):
        """Get human-readable status message"""
        if subscription.is_trial():
            days = subscription.days_remaining()
            return f'Trial period - {days} days remaining'
        
        if subscription.status == 'ACTIVE':
            days = subscription.days_remaining()
            if days <= 7:
                return f'Expiring soon - {days} days remaining'
            return f'Active - {days} days remaining'
        
        if subscription.status == 'EXPIRED':
            return 'Subscription expired - Please renew'
        
        if subscription.status == 'CANCELLED':
            return 'Subscription cancelled'
        
        return subscription.get_status_display()