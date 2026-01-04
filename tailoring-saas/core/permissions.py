"""
Custom permission classes for role-based access control
Uses Employee role from employee profile to determine permissions
"""

from rest_framework import permissions


class IsAuthenticated(permissions.BasePermission):
    """User must be authenticated"""
    
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated


class HasEmployeeProfile(permissions.BasePermission):
    """User must have an employee profile"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        try:
            return hasattr(request.user, 'employee_profile') and request.user.employee_profile is not None
        except:
            return False


class IsOwner(permissions.BasePermission):
    """Only shop owners can access"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Check through employee profile
        try:
            return request.user.employee_profile.role == 'OWNER'
        except:
            return False


class IsManagement(permissions.BasePermission):
    """Only management (Owner, Workshop Manager, HR Manager) can access"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Check through employee profile
        try:
            return request.user.employee_profile.is_management
        except:
            return False


class CanManageOrders(permissions.BasePermission):
    """
    Can create/edit orders
    Roles: Owner, Workshop Manager, Designer, Receptionist
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Allow read for everyone authenticated
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Allow write for specific roles
        try:
            return request.user.employee_profile.can_manage_orders
        except:
            return False


class CanManageInventory(permissions.BasePermission):
    """
    Can manage inventory
    Roles: Owner, Workshop Manager, Store Manager
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Allow read for everyone authenticated
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Allow write for specific roles
        try:
            return request.user.employee_profile.can_manage_inventory
        except:
            return False


class CanManageEmployees(permissions.BasePermission):
    """
    Can manage employee records
    Roles: Owner, HR Manager
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Allow read for management
        if request.method in permissions.SAFE_METHODS:
            try:
                return request.user.employee_profile.is_management
            except:
                return False
        
        # Allow write only for HR roles
        try:
            return request.user.employee_profile.can_manage_employees
        except:
            return False


class CanManagePayments(permissions.BasePermission):
    """
    Can handle payments
    Roles: Owner, Accountant, Receptionist
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Allow read for management
        if request.method in permissions.SAFE_METHODS:
            try:
                return request.user.employee_profile.is_management
            except:
                return False
        
        # Allow write for payment roles
        try:
            return request.user.employee_profile.can_manage_payments
        except:
            return False


class CanAssignTasks(permissions.BasePermission):
    """
    Can assign tasks to workers
    Roles: Owner, Workshop Manager, Department Master
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        try:
            return request.user.employee_profile.can_assign_tasks
        except:
            return False


class IsOwnerOrReadOnly(permissions.BasePermission):
    """Owner can edit, others can only read"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Allow read for authenticated users
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Allow write only for owners
        try:
            return request.user.employee_profile.role == 'OWNER'
        except:
            return False


class CanViewReports(permissions.BasePermission):
    """
    Can view reports and analytics
    Roles: Management only (Owner, Workshop Manager, HR Manager)
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        try:
            return request.user.employee_profile.is_management
        except:
            return False


class IsDepartmentMaster(permissions.BasePermission):
    """
    Is a department master
    Can manage their department's tasks
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        try:
            employee = request.user.employee_profile
            return employee.role == 'DEPARTMENT_MASTER' or employee.is_management
        except:
            return False


class CanAccessWorkshopTablet(permissions.BasePermission):
    """
    Can access workshop tablet with PIN
    Roles: Department Master, Workshop Manager
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        try:
            return request.user.employee_profile.needs_workshop_pin
        except:
            return False


# ==================== SUBSCRIPTION CHECKS ====================

class HasActiveSubscription(permissions.BasePermission):
    """Tenant must have active subscription"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Superuser bypass
        if request.user.is_superuser:
            return True
        
        # Check tenant subscription
        try:
            if not request.user.tenant:
                return False
            
            subscription = request.user.tenant.subscription
            return subscription and subscription.is_active()
        except:
            # Allow if no subscription system set up yet
            return True