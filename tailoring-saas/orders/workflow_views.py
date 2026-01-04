"""
API Views for Workflow Management
Workshop tablet and task management endpoints
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Q

from core.permissions import CanAssignTasks, IsManagement
from core.subscription_utils import require_feature, require_active_subscription  # ← ADDED

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
from .workflow_serializers import (
    WorkflowStageSerializer,
    OrderWorkflowStatusSerializer,
    TaskAssignmentListSerializer,
    TaskAssignmentDetailSerializer,
    TaskAssignmentCreateSerializer,
    TaskTimeLogSerializer,
    TaskCommentSerializer,
    WorkflowStageHistorySerializer,
    QualityCheckResultSerializer,
    TrialFeedbackSerializer
)
from .models import Order


class WorkflowStageViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Workflow stages for the tenant
    Read-only for workers, manageable by admins
    """
    serializer_class = WorkflowStageSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        if not self.request.user.tenant:
            return WorkflowStage.objects.none()
        
        return WorkflowStage.objects.filter(
            tenant=self.request.user.tenant,
            is_active=True
        ).order_by('sequence_order')


class TaskAssignmentViewSet(viewsets.ModelViewSet):
    """
    Task assignment and management
    """
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'list':
            return TaskAssignmentListSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return TaskAssignmentCreateSerializer
        return TaskAssignmentDetailSerializer
    
    def get_queryset(self):
        if not self.request.user.tenant:
            return TaskAssignment.objects.none()
        
        queryset = TaskAssignment.objects.filter(
            tenant=self.request.user.tenant
        ).select_related(
            'order', 'workflow_stage', 'assigned_to', 'assigned_by'
        )
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by assigned employee
        employee_id = self.request.query_params.get('employee')
        if employee_id:
            queryset = queryset.filter(assigned_to_id=employee_id)
        
        # Filter by order
        order_id = self.request.query_params.get('order')
        if order_id:
            queryset = queryset.filter(order_id=order_id)
        
        return queryset.order_by('-assigned_at')
    
    @require_feature('allow_task_assignment')  # ← ADDED
    @require_active_subscription  # ← ADDED
    def create(self, request):
        """Create task assignment"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Task assigned successfully',
                'task': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    @require_feature('allow_workflow')  # ← ADDED
    def start(self, request, pk=None):
        """
        Start working on a task
        POST /api/orders/workflow/tasks/{id}/start/
        """
        task = self.get_object()
        
        if task.status == 'IN_PROGRESS':
            return Response({
                'error': 'Task already in progress'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        task.status = 'IN_PROGRESS'
        task.started_at = timezone.now()
        task.save()
        
        # Log the action
        try:
            TaskTimeLog.objects.create(
                task=task,
                action='START',
                performed_by=request.user.employee_profile,
                timestamp=timezone.now()
            )
        except:
            pass
        
        serializer = TaskAssignmentDetailSerializer(task, context={'request': request})
        return Response({
            'message': 'Task started successfully',
            'task': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    @require_feature('allow_workflow')  # ← ADDED
    def pause(self, request, pk=None):
        """
        Pause a task
        POST /api/orders/workflow/tasks/{id}/pause/
        """
        task = self.get_object()
        
        if task.status != 'IN_PROGRESS':
            return Response({
                'error': 'Task is not in progress'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        task.status = 'ON_HOLD'
        task.save()
        
        # Log the action
        try:
            TaskTimeLog.objects.create(
                task=task,
                action='PAUSE',
                performed_by=request.user.employee_profile,
                timestamp=timezone.now(),
                notes=request.data.get('notes', '')
            )
        except:
            pass
        
        serializer = TaskAssignmentDetailSerializer(task, context={'request': request})
        return Response({
            'message': 'Task paused',
            'task': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    @require_feature('allow_workflow')  # ← ADDED
    def resume(self, request, pk=None):
        """
        Resume a paused task
        POST /api/orders/workflow/tasks/{id}/resume/
        """
        task = self.get_object()
        
        if task.status != 'ON_HOLD':
            return Response({
                'error': 'Task is not on hold'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        task.status = 'IN_PROGRESS'
        task.save()
        
        # Log the action
        try:
            TaskTimeLog.objects.create(
                task=task,
                action='RESUME',
                performed_by=request.user.employee_profile,
                timestamp=timezone.now()
            )
        except:
            pass
        
        serializer = TaskAssignmentDetailSerializer(task, context={'request': request})
        return Response({
            'message': 'Task resumed',
            'task': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    @require_feature('allow_workflow')  # ← ADDED
    def complete(self, request, pk=None):
        """
        Complete a task
        POST /api/orders/workflow/tasks/{id}/complete/
        """
        task = self.get_object()
        
        if task.status == 'COMPLETED':
            return Response({
                'error': 'Task already completed'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        task.status = 'COMPLETED'
        task.completed_at = timezone.now()
        task.save()
        
        # Log the action
        try:
            TaskTimeLog.objects.create(
                task=task,
                action='COMPLETE',
                performed_by=request.user.employee_profile,
                timestamp=timezone.now()
            )
        except:
            pass
        
        serializer = TaskAssignmentDetailSerializer(task, context={'request': request})
        return Response({
            'message': 'Task completed successfully',
            'task': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def my_tasks(self, request):
        """
        Get tasks assigned to current user
        GET /api/orders/workflow/tasks/my_tasks/
        """
        try:
            employee = request.user.employee_profile
            tasks = TaskAssignment.objects.filter(
                assigned_to=employee,
                status__in=['ASSIGNED', 'IN_PROGRESS', 'ON_HOLD']
            ).select_related('order', 'workflow_stage').order_by('due_date')
            
            serializer = TaskAssignmentListSerializer(tasks, many=True, context={'request': request})
            return Response({
                'count': tasks.count(),
                'tasks': serializer.data
            })
        except:
            return Response({
                'count': 0,
                'tasks': []
            })
    
    @action(detail=False, methods=['post'])
    @require_feature('allow_workflow')  # ← ADDED
    def scan_order(self, request):
        """
        Scan order QR to get/assign tasks
        POST /api/orders/workflow/tasks/scan_order/
        {
            "qr_data": "ORD:ORD-001:TENANT:1"
        }
        """
        qr_data = request.data.get('qr_data')
        if not qr_data:
            return Response({
                'error': 'QR data required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Parse QR: "ORD:ORD-001:TENANT:1"
            parts = qr_data.split(':')
            if len(parts) != 4 or parts[0] != 'ORD':
                return Response({
                    'error': 'Invalid QR code'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            order_number = parts[1]
            tenant_id = int(parts[3])
            
            # Verify tenant
            if tenant_id != request.user.tenant.id:
                return Response({
                    'error': 'Order not from this shop'
                }, status=status.HTTP_403_FORBIDDEN)
            
            # Get order
            order = Order.objects.get(
                order_number=order_number,
                tenant_id=tenant_id
            )
            
            # Get tasks for this order
            tasks = TaskAssignment.objects.filter(
                order=order
            ).select_related('workflow_stage', 'assigned_to')
            
            serializer = TaskAssignmentListSerializer(tasks, many=True, context={'request': request})
            
            return Response({
                'success': True,
                'order': {
                    'id': order.id,
                    'order_number': order.order_number,
                    'customer_name': order.customer.name,
                    'status': order.status
                },
                'tasks': serializer.data
            })
        
        except Order.DoesNotExist:
            return Response({
                'error': 'Order not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class QualityCheckViewSet(viewsets.ModelViewSet):
    """QA inspection results"""
    serializer_class = QualityCheckResultSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        if not self.request.user.tenant:
            return QualityCheckResult.objects.none()
        
        return QualityCheckResult.objects.filter(
            tenant=self.request.user.tenant
        ).select_related('order', 'workflow_stage', 'checked_by').order_by('-checked_at')
    
    @require_feature('allow_qa_system')  # ← ADDED
    @require_active_subscription  # ← ADDED
    def create(self, request):
        """Create QA check result"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'QA check recorded successfully',
                'qa_result': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TrialFeedbackViewSet(viewsets.ModelViewSet):
    """Customer trial feedback"""
    serializer_class = TrialFeedbackSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        if not self.request.user.tenant:
            return TrialFeedback.objects.none()
        
        return TrialFeedback.objects.filter(
            tenant=self.request.user.tenant
        ).select_related('order', 'conducted_by').order_by('-trial_date')
    
    @require_feature('allow_trial_feedback')  # ← ADDED
    @require_active_subscription  # ← ADDED
    def create(self, request):
        """Create trial feedback"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Trial feedback recorded successfully',
                'trial_feedback': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)