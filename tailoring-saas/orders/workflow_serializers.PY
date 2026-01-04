"""
Serializers for Workflow Management
"""

from rest_framework import serializers
from .workflow_models import (
    WorkflowStage,
    OrderWorkflowStatus,
    TaskAssignment,
    TaskTimeLog,
    TaskComment,
    WorkflowStageHistory,
    QualityCheckResult,
    TrialFeedback
)


class WorkflowStageSerializer(serializers.ModelSerializer):
    """Workflow stage serializer"""
    
    department_name = serializers.CharField(source='department.name', read_only=True, allow_null=True)
    
    class Meta:
        model = WorkflowStage
        fields = [
            'id', 'stage_type', 'name', 'department', 'department_name',
            'sequence_order', 'is_optional', 'requires_approval',
            'estimated_hours', 'is_active'
        ]
        read_only_fields = ['id']


class OrderWorkflowStatusSerializer(serializers.ModelSerializer):
    """Order workflow status serializer"""
    
    current_stage_name = serializers.CharField(source='current_stage.name', read_only=True)
    stage_details = WorkflowStageSerializer(source='current_stage', read_only=True)
    
    class Meta:
        model = OrderWorkflowStatus
        fields = [
            'id', 'order', 'current_stage', 'current_stage_name', 'stage_details',
            'status', 'started_at', 'expected_completion', 'actual_completion',
            'notes', 'updated_at'
        ]
        read_only_fields = ['id', 'updated_at']


class TaskAssignmentListSerializer(serializers.ModelSerializer):
    """Lightweight task serializer for lists"""
    
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    stage_name = serializers.CharField(source='workflow_stage.name', read_only=True)
    assigned_to_name = serializers.CharField(source='assigned_to.user.name', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = TaskAssignment
        fields = [
            'id', 'order', 'order_number', 'workflow_stage', 'stage_name',
            'assigned_to', 'assigned_to_name', 'status', 'priority',
            'is_overdue', 'due_date', 'assigned_at'
        ]


class TaskAssignmentDetailSerializer(serializers.ModelSerializer):
    """Detailed task serializer"""
    
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    customer_name = serializers.CharField(source='order.customer.name', read_only=True)
    stage_details = WorkflowStageSerializer(source='workflow_stage', read_only=True)
    assigned_to_name = serializers.CharField(source='assigned_to.user.name', read_only=True)
    assigned_by_name = serializers.CharField(source='assigned_by.user.name', read_only=True, allow_null=True)
    time_spent = serializers.SerializerMethodField()
    is_overdue = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = TaskAssignment
        fields = [
            'id', 'order', 'order_number', 'customer_name',
            'workflow_stage', 'stage_details',
            'assigned_to', 'assigned_to_name',
            'assigned_by', 'assigned_by_name',
            'priority', 'status', 'task_description',
            'estimated_hours', 'time_spent',
            'assigned_at', 'started_at', 'completed_at', 'due_date',
            'is_rework', 'rework_reason', 'rework_count',
            'is_overdue', 'notes'
        ]
        read_only_fields = ['assigned_at', 'time_spent']
    
    def get_time_spent(self, obj):
        return obj.time_spent


class TaskAssignmentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating tasks"""
    
    class Meta:
        model = TaskAssignment
        fields = [
            'order', 'workflow_stage', 'assigned_to', 'assigned_by',
            'priority', 'task_description', 'estimated_hours', 'due_date'
        ]
    
    def create(self, validated_data):
        # Auto-set tenant from request
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            validated_data['tenant'] = request.user.tenant
        
        return super().create(validated_data)


class TaskTimeLogSerializer(serializers.ModelSerializer):
    """Task time log serializer"""
    
    performed_by_name = serializers.CharField(source='performed_by.user.name', read_only=True, allow_null=True)
    
    class Meta:
        model = TaskTimeLog
        fields = [
            'id', 'task', 'action', 'timestamp',
            'performed_by', 'performed_by_name', 'notes'
        ]
        read_only_fields = ['id', 'timestamp']


class TaskCommentSerializer(serializers.ModelSerializer):
    """Task comment serializer"""
    
    commented_by_name = serializers.CharField(source='commented_by.user.name', read_only=True, allow_null=True)
    photo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = TaskComment
        fields = [
            'id', 'task', 'commented_by', 'commented_by_name',
            'comment', 'photo', 'photo_url', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_photo_url(self, obj):
        if obj.photo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.photo.url)
        return None


class WorkflowStageHistorySerializer(serializers.ModelSerializer):
    """Workflow history serializer"""
    
    from_stage_name = serializers.CharField(source='from_stage.name', read_only=True, allow_null=True)
    to_stage_name = serializers.CharField(source='to_stage.name', read_only=True)
    changed_by_name = serializers.CharField(source='changed_by.user.name', read_only=True, allow_null=True)
    
    class Meta:
        model = WorkflowStageHistory
        fields = [
            'id', 'order', 'from_stage', 'from_stage_name',
            'to_stage', 'to_stage_name', 'changed_by', 'changed_by_name',
            'time_spent_hours', 'notes', 'changed_at'
        ]
        read_only_fields = ['id', 'changed_at']


class QualityCheckResultSerializer(serializers.ModelSerializer):
    """QA result serializer"""
    
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    stage_name = serializers.CharField(source='workflow_stage.name', read_only=True)
    checked_by_name = serializers.CharField(source='checked_by.user.name', read_only=True, allow_null=True)
    send_back_to_name = serializers.CharField(source='send_back_to.name', read_only=True, allow_null=True)
    
    class Meta:
        model = QualityCheckResult
        fields = [
            'id', 'order', 'order_number', 'workflow_stage', 'stage_name',
            'checked_by', 'checked_by_name', 'result', 'issue_type',
            'issues_found', 'photos', 'send_back_to', 'send_back_to_name',
            'checked_at', 'resolved_at'
        ]
        read_only_fields = ['id', 'checked_at']


class TrialFeedbackSerializer(serializers.ModelSerializer):
    """Trial feedback serializer"""
    
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    customer_name = serializers.CharField(source='order.customer.name', read_only=True)
    conducted_by_name = serializers.CharField(source='conducted_by.user.name', read_only=True, allow_null=True)
    
    class Meta:
        model = TrialFeedback
        fields = [
            'id', 'order', 'order_number', 'customer_name',
            'trial_date', 'trial_result', 'customer_feedback',
            'alterations_needed', 'photos', 'conducted_by', 'conducted_by_name',
            'next_trial_date', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']