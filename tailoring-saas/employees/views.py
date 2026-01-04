from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import date, datetime, time
from .models import Employee, Department, Attendance, OvertimeLog, BreakLog, ShopSettings
from core.permissions import CanManageEmployees, IsManagement
from .serializers import (
    EmployeeSerializer, DepartmentSerializer, AttendanceSerializer,
    OvertimeLogSerializer, BreakLogSerializer, ShopSettingsSerializer
)
from core.subscription_utils import (
    require_active_subscription,
    require_feature,
    check_resource_limit
)


class DepartmentViewSet(viewsets.ReadOnlyModelViewSet):
    """Department API - Read only"""
    serializer_class = DepartmentSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Department.objects.filter(
            tenant=self.request.user.tenant,
            is_active=True
        )


class EmployeeViewSet(viewsets.ReadOnlyModelViewSet):
    """Employee API - Read only"""
    serializer_class = EmployeeSerializer
    permission_classes = [IsAuthenticated, CanManageEmployees]
    
    def get_queryset(self):
        return Employee.objects.filter(
            tenant=self.request.user.tenant,
            is_active=True
        ).select_related('user', 'department')
    
    @action(detail=False, methods=['post'])
    def verify_by_qr(self, request):
        """
        Verify employee by QR code
        POST /api/employees/verify_by_qr/
        {
            "qr_data": "EMP:EMP-001:TENANT:1"
        }
        """
        qr_data = request.data.get('qr_data')
        if not qr_data:
            return Response(
                {'error': 'QR data required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Parse QR data: "EMP:EMP-001:TENANT:1"
            parts = qr_data.split(':')
            if len(parts) != 4 or parts[0] != 'EMP':
                return Response(
                    {'error': 'Invalid QR code'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            employee_code = parts[1]
            tenant_id = int(parts[3])
            
            # Verify tenant matches
            if tenant_id != request.user.tenant.id:
                return Response(
                    {'error': 'Employee not from this shop'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get employee
            employee = Employee.objects.get(
                employee_code=employee_code,
                tenant_id=tenant_id,
                is_active=True
            )
            
            serializer = self.get_serializer(employee)
            return Response({
                'success': True,
                'employee': serializer.data
            })
        
        except Employee.DoesNotExist:
            return Response(
                {'error': 'Employee not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['post'])
    def verify_pin(self, request):
        """
        Verify master PIN for workshop login
        POST /api/employees/verify_pin/
        {
            "pin": "1234"
        }
        """
        pin = request.data.get('pin')
        if not pin:
            return Response(
                {'error': 'PIN required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            employee = Employee.objects.get(
                tenant=request.user.tenant,
                workshop_pin=pin,
                role='DEPARTMENT_MASTER',
                is_active=True
            )
            
            serializer = self.get_serializer(employee)
            return Response({
                'success': True,
                'employee': serializer.data,
                'message': f'Welcome {employee.user.get_full_name()}'
            })
        
        except Employee.DoesNotExist:
            return Response(
                {'error': 'Invalid PIN or not a department master'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
    @require_feature('allow_employee_management')  # ← CHECK FEATURE FIRST
    @check_resource_limit('max_employees')  # ← THEN CHECK LIMIT
    @require_active_subscription
    def create(self, request):
        """Create new employee"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Employee created successfully',
                'employee': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)    

class AttendanceViewSet(viewsets.ModelViewSet):
    """Attendance API"""
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Attendance.objects.filter(
            employee__tenant=self.request.user.tenant
        ).select_related('employee', 'employee__user')
        
        # Filter by date
        date_param = self.request.query_params.get('date')
        if date_param:
            queryset = queryset.filter(date=date_param)
        
        # Filter by employee
        employee_code = self.request.query_params.get('employee_code')
        if employee_code:
            queryset = queryset.filter(employee__employee_code=employee_code)
        
        return queryset.order_by('-date', 'employee__employee_code')
    
    @action(detail=False, methods=['post'])
    @require_feature('allow_attendance')  # ← ADD THIS
    @require_active_subscription  # ← ADD THIS
    def clock_in(self, request):
        """
        Clock in by QR code
        POST /api/attendance/clock_in/
        {
            "qr_data": "EMP:EMP-001:TENANT:1"
        }
        """
        qr_data = request.data.get('qr_data')
        if not qr_data:
            return Response(
                {'error': 'QR data required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # ✅ CHECK IF QR ATTENDANCE IS ALLOWED
        plan = request.user.tenant.subscription.plan
        if plan.allow_attendance != 'QR_SCAN':
            return Response({
                'error': 'QR attendance not available',
                'message': f'QR code attendance is not available in your {plan.name} plan',
                'current_plan': plan.name,
                'attendance_type': plan.allow_attendance,
                'upgrade_url': '/api/core/subscriptions/my-subscription/upgrade/'
            }, status=status.HTTP_402_PAYMENT_REQUIRED)
        
        try:
            # Parse QR
            parts = qr_data.split(':')
            employee_code = parts[1]
            tenant_id = int(parts[3])
            
            # Get employee
            employee = Employee.objects.get(
                employee_code=employee_code,
                tenant_id=tenant_id,
                is_active=True
            )
            
            # Check if already clocked in today
            today = date.today()
            attendance, created = Attendance.objects.get_or_create(
                employee=employee,
                date=today,
                defaults={'clock_in': timezone.now()}
            )
            
            if not created:
                if attendance.clock_in and not attendance.clock_out:
                    return Response({
                        'error': 'Already clocked in',
                        'clock_in_time': attendance.clock_in,
                    }, status=status.HTTP_400_BAD_REQUEST)
                else:
                    return Response({
                        'error': 'Already completed attendance for today',
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            # Determine status
            shop_settings = ShopSettings.objects.filter(tenant=employee.tenant).first()
            if shop_settings:
                opening_time = shop_settings.opening_time
                grace_period = shop_settings.grace_period_minutes
                grace_time = (datetime.combine(date.today(), opening_time) + 
                             timezone.timedelta(minutes=grace_period)).time()
                
                if attendance.clock_in.time() > grace_time:
                    attendance.status = 'LATE'
                else:
                    attendance.status = 'PRESENT'
                attendance.save()
            
            serializer = self.get_serializer(attendance)
            return Response({
                'success': True,
                'message': f'{employee.user.get_full_name()} clocked in successfully',
                'attendance': serializer.data,
                'status': attendance.status
            })
        
        except Employee.DoesNotExist:
            return Response(
                {'error': 'Employee not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['post'])
    @require_feature('allow_attendance')  # ← ADD THIS
    @require_active_subscription  # ← ADD THIS
    def clock_out(self, request):
        """
        Clock out by QR code
        POST /api/attendance/clock_out/
        {
            "qr_data": "EMP:EMP-001:TENANT:1"
        }
        """
        qr_data = request.data.get('qr_data')
        if not qr_data:
            return Response(
                {'error': 'QR data required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # ✅ CHECK IF QR ATTENDANCE IS ALLOWED
        plan = request.user.tenant.subscription.plan
        if plan.allow_attendance != 'QR_SCAN':
            return Response({
                'error': 'QR attendance not available',
                'message': f'QR code attendance is not available in your {plan.name} plan',
                'upgrade_url': '/api/core/subscriptions/my-subscription/upgrade/'
            }, status=status.HTTP_402_PAYMENT_REQUIRED)
        
        try:
            # Parse QR
            parts = qr_data.split(':')
            employee_code = parts[1]
            
            # Get employee
            employee = Employee.objects.get(
                employee_code=employee_code,
                tenant=request.user.tenant,
                is_active=True
            )
            
            # Get today's attendance
            today = date.today()
            try:
                attendance = Attendance.objects.get(
                    employee=employee,
                    date=today
                )
            except Attendance.DoesNotExist:
                return Response({
                    'error': 'Not clocked in today',
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if attendance.clock_out:
                return Response({
                    'error': 'Already clocked out',
                    'clock_out_time': attendance.clock_out,
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Clock out
            attendance.clock_out = timezone.now()
            attendance.calculate_hours()  # This calculates regular, OT, break hours
            attendance.save()
            
            serializer = self.get_serializer(attendance)
            return Response({
                'success': True,
                'message': f'{employee.user.get_full_name()} clocked out successfully',
                'attendance': serializer.data,
                'total_hours': float(attendance.total_working_hours),
                'regular_hours': float(attendance.regular_hours),
                'overtime_hours': float(attendance.overtime_hours)
            })
        
        except Employee.DoesNotExist:
            return Response(
                {'error': 'Employee not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['get'])
    @require_feature('allow_employee_management')  # ← ADD THIS (basic check)
    def today_summary(self, request):
        """
        Get today's attendance summary
        GET /api/attendance/today_summary/
        """
        today = date.today()
        department_id = request.query_params.get('department')
        
        queryset = Attendance.objects.filter(
            employee__tenant=request.user.tenant,
            date=today
        ).select_related('employee', 'employee__user', 'employee__department')
        
        if department_id:
            queryset = queryset.filter(employee__department_id=department_id)
        
        serializer = self.get_serializer(queryset, many=True)
        
        # Calculate summary
        total_employees = Employee.objects.filter(
            tenant=request.user.tenant,
            is_active=True
        )
        if department_id:
            total_employees = total_employees.filter(department_id=department_id)
        total_count = total_employees.count()
        
        present_count = queryset.filter(status__in=['PRESENT', 'LATE']).count()
        absent_count = total_count - present_count
        
        return Response({
            'date': today,
            'summary': {
                'total_employees': total_count,
                'present': present_count,
                'absent': absent_count,
                'late': queryset.filter(status='LATE').count(),
            },
            'attendance': serializer.data
        })

class ShopSettingsViewSet(viewsets.ReadOnlyModelViewSet):
    """Shop settings API - Read only"""
    serializer_class = ShopSettingsSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ShopSettings.objects.filter(tenant=self.request.user.tenant)