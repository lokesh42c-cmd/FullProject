"""
Serializers for Core app
"""
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, Tenant
# ← REMOVED: SubscriptionPlan, TenantSubscription imports


class TenantSerializer(serializers.ModelSerializer):
    """Serializer for Tenant"""
    class Meta:
        model = Tenant
        fields = [
            'id', 'name', 'slug', 'email', 'phone_number',
            'address', 'city', 'state', 'pincode',
            'gstin', 'pan_number', 'logo',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User"""
    tenant = TenantSerializer(read_only=True)
    role = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'phone_number', 'role',
            'tenant', 'is_active', 'is_staff', 'is_superuser',
            'date_joined'
        ]
        read_only_fields = ['id', 'date_joined']
    
    def get_role(self, obj):
        """Get role from employee profile"""
        try:
            if hasattr(obj, 'employee_profile') and obj.employee_profile:
                return obj.employee_profile.role
        except:
            pass
        return None


class RegistrationSerializer(serializers.Serializer):
    """Serializer for user registration"""
    # User fields
    email = serializers.EmailField(required=True)
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )
    password_confirm = serializers.CharField(write_only=True, required=True)
    name = serializers.CharField(required=True, max_length=200)
    phone_number = serializers.CharField(required=False, max_length=17)
    
    # Tenant fields
    tenant_data = serializers.DictField(required=True)
    
    def validate(self, data):
        """Validate passwords match"""
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({
                'password_confirm': 'Passwords do not match'
            })
        
        # Validate email uniqueness
        if User.objects.filter(email=data['email']).exists():
            raise serializers.ValidationError({
                'email': 'User with this email already exists'
            })
        
        # Validate tenant data
        tenant_data = data.get('tenant_data', {})
        required_tenant_fields = ['name', 'email', 'phone_number', 'city']
        for field in required_tenant_fields:
            if field not in tenant_data:
                raise serializers.ValidationError({
                    'tenant_data': f'{field} is required in tenant_data'
                })
        
        return data


class LoginSerializer(serializers.Serializer):
    """Serializer for user login"""
    email = serializers.EmailField(required=True)
    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )

# ← DELETED OLD SubscriptionPlanSerializer and TenantSubscriptionSerializer
# ← They're now in core/subscription_serializers.py with correct fields