from rest_framework import serializers
from .models import Employee, Department, Attendance, OvertimeLog, BreakLog, ShopSettings
from django.contrib.auth import get_user_model

User = get_user_model()


class DepartmentSerializer(serializers.ModelSerializer):
    """Department serializer"""
    
    class Meta:
        model = Department
        fields = ['id', 'name', 'description', 'is_active']


class EmployeeSerializer(serializers.ModelSerializer):
    """Employee serializer"""
    
    user_name = serializers.SerializerMethodField()
    department_name = serializers.CharField(source='department.name', read_only=True)
    age = serializers.IntegerField(read_only=True)
    qr_code_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Employee
        fields = [
            'id', 'employee_code', 'user_name', 'role', 'department', 
            'department_name', 'specialization', 'phone_number', 
            'photo', 'qr_code_url', 'is_active', 'date_joined',
            'payment_type', 'age', 'blood_group', 'workshop_pin'
        ]
        extra_kwargs = {
            'workshop_pin': {'write_only': True}
        }
    
    def get_user_name(self, obj):
        return obj.user.get_full_name() or obj.user.email
    
    def get_qr_code_url(self, obj):
        if obj.qr_code:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.qr_code.url)
        return None


class AttendanceSerializer(serializers.ModelSerializer):
    """Attendance serializer"""
    
    employee_code = serializers.CharField(source='employee.employee_code', read_only=True)
    employee_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Attendance
        fields = [
            'id', 'employee', 'employee_code', 'employee_name', 'date',
            'clock_in', 'clock_out', 'regular_hours', 'overtime_hours',
            'break_hours', 'total_working_hours', 'status', 'notes'
        ]
        read_only_fields = [
            'regular_hours', 'overtime_hours', 'break_hours', 
            'total_working_hours', 'status'
        ]
    
    def get_employee_name(self, obj):
        return obj.employee.user.get_full_name()


class OvertimeLogSerializer(serializers.ModelSerializer):
    """Overtime log serializer"""
    
    employee_code = serializers.CharField(source='employee.employee_code', read_only=True)
    
    class Meta:
        model = OvertimeLog
        fields = [
            'id', 'employee', 'employee_code', 'date', 'ot_start', 
            'ot_end', 'ot_hours', 'ot_type', 'notes'
        ]
        read_only_fields = ['ot_hours', 'ot_type', 'date']


class BreakLogSerializer(serializers.ModelSerializer):
    """Break log serializer"""
    
    class Meta:
        model = BreakLog
        fields = [
            'id', 'employee', 'attendance', 'date', 'break_type',
            'start_time', 'end_time', 'duration_minutes', 'notes'
        ]
        read_only_fields = ['duration_minutes']


class ShopSettingsSerializer(serializers.ModelSerializer):
    """Shop settings serializer"""
    
    class Meta:
        model = ShopSettings
        fields = [
            'id', 'opening_time', 'closing_time', 'lunch_start', 'lunch_end',
            'tea_break_1_start', 'tea_break_1_end', 'tea_break_2_start', 
            'tea_break_2_end', 'grace_period_minutes', 
            'overtime_after_midnight_cutoff', 'weekly_off_days', 
            'overtime_multiplier'
        ]