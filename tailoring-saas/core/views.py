"""
Views for Core app - Authentication and User Management
UPDATED: New role structure support
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import authenticate
from django.db import transaction
from datetime import timedelta
from django.utils import timezone
from employees.models import Employee
from django.db.models import Sum, Count, Q
from orders.models import Order,Customer


from .models import User, Tenant, SubscriptionPlan, TenantSubscription
from .serializers import (
    UserSerializer,
    TenantSerializer,
    RegistrationSerializer,
    LoginSerializer
)

class RegistrationView(APIView):
    """
    API endpoint for user registration
    Creates both tenant and owner user
    """
    permission_classes = [AllowAny]
    
    @transaction.atomic
    def post(self, request):
        serializer = RegistrationSerializer(data=request.data)
        
        if serializer.is_valid():
            # Create tenant
            tenant_data = serializer.validated_data.pop('tenant_data')
            tenant = Tenant.objects.create(**tenant_data)
            
            # Create user (WITHOUT role - it's a property)
            user = User.objects.create_user(
                email=serializer.validated_data['email'],
                password=serializer.validated_data['password'],
                name=serializer.validated_data['name'],
                phone_number=serializer.validated_data.get('phone_number'),
                tenant=tenant
            )
            
            # Import Employee model
            from employees.models import Employee
            
            # Create Employee record with OWNER role
            employee = Employee.objects.create(
                user=user,
                tenant=tenant,
                role='OWNER',
                employee_code=f'EMP-{user.id:04d}',
               # name=serializer.validated_data['name'],
                phone_number=serializer.validated_data.get('phone_number'),
                is_active=True,
            )
            
            # Create trial subscription
            try:
                trial_plan = SubscriptionPlan.objects.get(tier='FREE_TRIAL')
                TenantSubscription.objects.create(
                    tenant=tenant,
                    plan=trial_plan,
                    status='TRIAL',
                    billing_cycle='MONTHLY',
                    start_date=timezone.now().date(),
                    trial_end_date=timezone.now().date() + timedelta(days=14),
                    end_date=timezone.now().date() + timedelta(days=14)
                )
            except SubscriptionPlan.DoesNotExist:
                pass
                
            # Generate tokens
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'message': 'Registration successful',
                'user': UserSerializer(user).data,
                'tenant': TenantSerializer(tenant).data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                }
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """
    API endpoint for user login
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        
        if serializer.is_valid():
            email = serializer.validated_data['email']
            password = serializer.validated_data['password']
            
            user = authenticate(email=email, password=password)
            
            if user:
                if not user.is_active:
                    return Response({
                        'error': 'Account is disabled'
                    }, status=status.HTTP_401_UNAUTHORIZED)
                
                # Generate tokens
                refresh = RefreshToken.for_user(user)
                
                return Response({
                    'message': 'Login successful',
                    'user': UserSerializer(user).data,
                    'tokens': {
                        'refresh': str(refresh),
                        'access': str(refresh.access_token),
                    }
                })
            
            return Response({
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(APIView):
    """
    API endpoint for user profile
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
    
    def put(self, request):
        serializer = UserSerializer(
            request.user,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Profile updated successfully',
                'user': serializer.data
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class StaffViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing staff members within a tenant
    UPDATED: Only OWNER and WORKSHOP_MANAGER can manage staff
    """
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer
    http_method_names = ['get', 'post', 'put', 'patch', 'delete']
    
    def get_queryset(self):
        """Get staff for current tenant"""
        user = self.request.user
        
        if user.is_superuser:
            return User.objects.all()
        
        # Filter by tenant
        if hasattr(user, 'tenant') and user.tenant:
            return User.objects.filter(tenant=user.tenant).exclude(id=user.id)
        
        return User.objects.none()
    
    def create(self, request):
        """Create new staff member"""
        user = request.user
        
        # UPDATED: Check permissions - Only OWNER and WORKSHOP_MANAGER can add staff
        if user.role not in ['OWNER', 'WORKSHOP_MANAGER']:
            return Response({
                'error': 'Only owners and workshop managers can add staff'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Validate data
        email = request.data.get('email')
        password = request.data.get('password')
        name = request.data.get('name')
        role = request.data.get('role')
        phone = request.data.get('phone')
        
        if not all([email, password, name, role]):
            return Response({
                'error': 'Email, password, name, and role are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # UPDATED: Validate role - must be valid role
        valid_roles = ['STAFF', 'SPECIALIST', 'WORKSHOP_MANAGER', 'ACCOUNTANT']
        if role not in valid_roles:
            return Response({
                'error': f'Invalid role. Must be one of: {", ".join(valid_roles)}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if email exists
        if User.objects.filter(email=email).exists():
            return Response({
                'error': 'User with this email already exists'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create staff member
        staff = User.objects.create_user(
            email=email,
            password=password,
            name=name,
            role=role,
            phone=phone,
            tenant=user.tenant
        )
        
        return Response({
            'message': 'Staff member created successfully',
            'staff': UserSerializer(staff).data
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['get'])
    def specialists(self, request):
        """Get all specialists (replaces tailors endpoint)"""
        specialists = self.get_queryset().filter(role='SPECIALIST')
        return Response(UserSerializer(specialists, many=True).data)
    
    @action(detail=False, methods=['get'])
    def workshop_managers(self, request):
        """Get all workshop managers"""
        managers = self.get_queryset().filter(role='WORKSHOP_MANAGER')
        return Response(UserSerializer(managers, many=True).data)
    
    @action(detail=False, methods=['get'])
    def staff_members(self, request):
        """Get all staff (front desk)"""
        staff = self.get_queryset().filter(role='STAFF')
        return Response(UserSerializer(staff, many=True).data)
    
    # DEPRECATED: Keep for backward compatibility, but use specialists instead
    @action(detail=False, methods=['get'])
    def tailors(self, request):
        """
        DEPRECATED: Use /specialists/ instead
        Get all specialists (formerly tailors)
        """
        specialists = self.get_queryset().filter(role='SPECIALIST')
        return Response(UserSerializer(specialists, many=True).data)
    
    # DEPRECATED: Keep for backward compatibility
    @action(detail=False, methods=['get'])
    def designers(self, request):
        """
        DEPRECATED: Use /staff_members/ or /specialists/ instead
        Get all staff and specialists
        """
        designers = self.get_queryset().filter(role__in=['STAFF', 'SPECIALIST', 'WORKSHOP_MANAGER'])
        return Response(UserSerializer(designers, many=True).data)
    

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    """
    Get dashboard statistics for the authenticated user's tenant
    """
    user = request.user
    tenant = user.tenant
    
    if not tenant:
        return Response({
            'error': 'User has no tenant'
        }, status=400)
    
    # Get all orders for this tenant
    orders = Order.objects.filter(tenant=tenant)
    
    # Calculate stats
    total_orders = orders.count()
    pending_orders = orders.filter(status='PENDING').count()
    completed_orders = orders.filter(status='DELIVERED').count()
    active_orders = orders.filter(
        status__in=['PENDING', 'IN_PROGRESS', 'READY_FOR_DELIVERY']
    ).count()
    
    # Calculate total revenue (from delivered orders)
    total_revenue = orders.filter(
        status='DELIVERED'
    ).aggregate(
        total=Sum('grand_total')
    )['total'] or 0
    
    # Set customers to 0 for now (we'll add this feature later)
    total_customers = 0
    
    return Response({
        'total_orders': total_orders,
        'total_customers': total_customers,
        'total_revenue': float(total_revenue),
        'pending_orders': pending_orders,
        'completed_orders': completed_orders,
        'active_orders': active_orders,
    })