"""
Workshop Workflow Management Models
Tracks order progress through workshop departments
"""

from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from decimal import Decimal
from core.managers import TenantManager
from core.subscription_utils import (
    require_active_subscription,
    require_feature
)


class WorkflowStage(models.Model):
    """
    Define workflow stages for the workshop
    Can be customized per tenant
    """
    
    STAGE_TYPE_CHOICES = [
        ('ORDER_RECEIVED', 'Order Received'),
        ('DESIGN', 'Design & Approval'),
        ('PATTERN_MAKING', 'Pattern Making'),
        ('EMBROIDERY_DESIGN', 'Embroidery Design'),
        ('EMBROIDERY_WORK', 'Embroidery Execution'),
        ('EMBROIDERY_QA', 'Embroidery QA'),
        ('CUTTING', 'Fabric Cutting'),
        ('TAILORING', 'Stitching'),
        ('FINISHING', 'Finishing Work'),
        ('QA_CHECK', 'Quality Check'),
        ('TRIAL', 'Customer Trial'),
        ('ALTERATIONS', 'Alterations'),
        ('FINAL_QA', 'Final QA'),
        ('READY_FOR_DELIVERY', 'Ready for Delivery'),
    ]
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='workflow_stages'
    )
    
    stage_type = models.CharField(
        max_length=30,
        choices=STAGE_TYPE_CHOICES,
        verbose_name='Stage Type'
    )
    
    name = models.CharField(
        max_length=100,
        verbose_name='Stage Name',
        help_text='Custom name for this stage'
    )
    
    department = models.ForeignKey(
        'employees.Department',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='workflow_stages',
        verbose_name='Department'
    )
    
    sequence_order = models.IntegerField(
        default=0,
        verbose_name='Sequence Order',
        help_text='Order in workflow (1, 2, 3...)'
    )
    
    is_optional = models.BooleanField(
        default=False,
        verbose_name='Optional Stage',
        help_text='Can be skipped (e.g., Embroidery)'
    )
    
    requires_approval = models.BooleanField(
        default=False,
        verbose_name='Requires Approval',
        help_text='Needs master/customer approval'
    )
    
    estimated_hours = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Estimated Hours',
        help_text='Expected time to complete'
    )
    
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Workflow Stage'
        verbose_name_plural = 'Workflow Stages'
        ordering = ['sequence_order']
        unique_together = ['tenant', 'stage_type']
        indexes = [
            models.Index(fields=['tenant', 'sequence_order']),
        ]
    
    def __str__(self):
        return f"{self.sequence_order}. {self.name}"


class OrderWorkflowStatus(models.Model):
    """
    Current workflow status for an order
    Tracks which stage the order is in
    """
    
    STATUS_CHOICES = [
        ('NOT_STARTED', 'Not Started'),
        ('IN_PROGRESS', 'In Progress'),
        ('ON_HOLD', 'On Hold'),
        ('WAITING_APPROVAL', 'Waiting Approval'),
        ('REWORK', 'Rework Required'),
        ('COMPLETED', 'Completed'),
        ('SKIPPED', 'Skipped'),
    ]
    
    order = models.OneToOneField(
        'orders.Order',
        on_delete=models.CASCADE,
        related_name='workflow_status',
        verbose_name='Order'
    )
    
    current_stage = models.ForeignKey(
        WorkflowStage,
        on_delete=models.PROTECT,
        related_name='current_orders',
        verbose_name='Current Stage'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='NOT_STARTED',
        verbose_name='Status'
    )
    
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Started At'
    )
    
    expected_completion = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Expected Completion'
    )
    
    actual_completion = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Actual Completion'
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    updated_at = models.DateTimeField(auto_now=True)

    # MANAGERS
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Order Workflow Status'
        verbose_name_plural = 'Order Workflow Statuses'
        indexes = [
            models.Index(fields=['current_stage', 'status']),
        ]
    
    def __str__(self):
        return f"{self.order.order_number} - {self.current_stage.name}"


class TaskAssignment(models.Model):
    """
    Assign specific tasks to workers
    Master assigns work to team members
    """
    
    PRIORITY_CHOICES = [
        ('LOW', 'Low'),
        ('NORMAL', 'Normal'),
        ('HIGH', 'High'),
        ('URGENT', 'Urgent'),
    ]
    
    STATUS_CHOICES = [
        ('ASSIGNED', 'Assigned'),
        ('IN_PROGRESS', 'In Progress'),
        ('ON_HOLD', 'On Hold'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='task_assignments'
    )
    
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.CASCADE,
        related_name='task_assignments',
        verbose_name='Order'
    )
    
    workflow_stage = models.ForeignKey(
        WorkflowStage,
        on_delete=models.PROTECT,
        related_name='task_assignments',
        verbose_name='Workflow Stage'
    )
    
    assigned_to = models.ForeignKey(
        'employees.Employee',
        on_delete=models.PROTECT,
        related_name='assigned_tasks',
        verbose_name='Assigned To'
    )
    
    assigned_by = models.ForeignKey(
        'employees.Employee',
        on_delete=models.SET_NULL,
        null=True,
        related_name='tasks_assigned_by_me',
        verbose_name='Assigned By'
    )
    
    priority = models.CharField(
        max_length=10,
        choices=PRIORITY_CHOICES,
        default='NORMAL',
        verbose_name='Priority'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='ASSIGNED',
        verbose_name='Status'
    )
    
    task_description = models.TextField(
        blank=True,
        verbose_name='Task Description',
        help_text='Specific instructions for this task'
    )
    
    estimated_hours = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Estimated Hours'
    )
    
    # Timestamps
    assigned_at = models.DateTimeField(auto_now_add=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    due_date = models.DateTimeField(null=True, blank=True)
    
    # Rework tracking
    is_rework = models.BooleanField(
        default=False,
        verbose_name='Is Rework',
        help_text='Task sent back for corrections'
    )
    
    rework_reason = models.TextField(
        blank=True,
        verbose_name='Rework Reason'
    )
    
    rework_count = models.IntegerField(
        default=0,
        verbose_name='Rework Count'
    )
    
    notes = models.TextField(blank=True)
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Task Assignment'
        verbose_name_plural = 'Task Assignments'
        ordering = ['-assigned_at']
        indexes = [
            models.Index(fields=['tenant', 'status']),
            models.Index(fields=['assigned_to', 'status']),
            models.Index(fields=['order', 'workflow_stage']),
        ]
    
    def __str__(self):
        return f"{self.order.order_number} - {self.workflow_stage.name} → {self.assigned_to.user.name}"
    
    @property
    def is_overdue(self):
        """Check if task is overdue"""
        if self.due_date and self.status not in ['COMPLETED', 'CANCELLED']:
            return timezone.now() > self.due_date
        return False
    
    @property
    def time_spent(self):
        """Calculate time spent on task"""
        if self.started_at:
            end_time = self.completed_at or timezone.now()
            duration = end_time - self.started_at
            return duration.total_seconds() / 3600  # Convert to hours
        return 0

class TaskTimeLog(models.Model):
    """
    Detailed time tracking for each task
    Tracks start/pause/resume/complete with timestamps
    """
    
    ACTION_CHOICES = [
        ('START', 'Started'),
        ('PAUSE', 'Paused'),
        ('RESUME', 'Resumed'),
        ('COMPLETE', 'Completed'),
    ]
    
    task = models.ForeignKey(
        TaskAssignment,
        on_delete=models.CASCADE,
        related_name='time_logs',
        verbose_name='Task'
    )
    
    action = models.CharField(
        max_length=10,
        choices=ACTION_CHOICES,
        verbose_name='Action'
    )
    
    timestamp = models.DateTimeField(
        default=timezone.now,
        verbose_name='Timestamp'
    )
    
    performed_by = models.ForeignKey(
        'employees.Employee',
        on_delete=models.SET_NULL,
        null=True,
        related_name='task_time_logs',
        verbose_name='Performed By'
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    class Meta:
        verbose_name = 'Task Time Log'
        verbose_name_plural = 'Task Time Logs'
        ordering = ['timestamp']
        indexes = [
            models.Index(fields=['task', 'timestamp']),
        ]
    
    def __str__(self):
        return f"{self.task.order.order_number} - {self.action} at {self.timestamp}"


class TaskComment(models.Model):
    """
    Comments/notes on tasks
    For communication between masters and workers
    """
    
    task = models.ForeignKey(
        TaskAssignment,
        on_delete=models.CASCADE,
        related_name='comments',
        verbose_name='Task'
    )
    
    commented_by = models.ForeignKey(
        'employees.Employee',
        on_delete=models.SET_NULL,
        null=True,
        related_name='task_comments',
        verbose_name='Commented By'
    )
    
    comment = models.TextField(
        verbose_name='Comment'
    )
    
    photo = models.ImageField(
        upload_to='tasks/comments/',
        null=True,
        blank=True,
        verbose_name='Photo',
        help_text='Optional photo attachment'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Task Comment'
        verbose_name_plural = 'Task Comments'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Comment on {self.task} by {self.commented_by}"


class WorkflowStageHistory(models.Model):
    """
    Track order movement through workflow stages
    Complete audit trail of stage changes
    """
    
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.CASCADE,
        related_name='workflow_history',
        verbose_name='Order'
    )
    
    from_stage = models.ForeignKey(
        WorkflowStage,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='history_from',
        verbose_name='From Stage'
    )
    
    to_stage = models.ForeignKey(
        WorkflowStage,
        on_delete=models.PROTECT,
        related_name='history_to',
        verbose_name='To Stage'
    )
    
    changed_by = models.ForeignKey(
        'employees.Employee',
        on_delete=models.SET_NULL,
        null=True,
        related_name='workflow_changes',
        verbose_name='Changed By'
    )
    
    time_spent_hours = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name='Time Spent (Hours)',
        help_text='Time spent in previous stage'
    )
    
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    
    changed_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Workflow Stage History'
        verbose_name_plural = 'Workflow Stage History'
        ordering = ['order', 'changed_at']
        indexes = [
            models.Index(fields=['order', 'changed_at']),
        ]
    
    def __str__(self):
        from_stage_name = self.from_stage.name if self.from_stage else 'START'
        return f"{self.order.order_number}: {from_stage_name} → {self.to_stage.name}"


class QualityCheckResult(models.Model):
    """
    QA inspection results
    Track quality checks and issues found
    """
    
    RESULT_CHOICES = [
        ('PASS', 'Passed'),
        ('FAIL', 'Failed - Needs Rework'),
        ('PARTIAL', 'Partial - Minor Issues'),
    ]
    
    ISSUE_TYPE_CHOICES = [
        ('MEASUREMENT', 'Measurement Issue'),
        ('STITCHING', 'Stitching Issue'),
        ('EMBROIDERY', 'Embroidery Issue'),
        ('FABRIC', 'Fabric Issue'),
        ('FINISHING', 'Finishing Issue'),
        ('OTHER', 'Other'),
    ]
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='qa_results'
    )
    
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.CASCADE,
        related_name='qa_results',
        verbose_name='Order'
    )
    
    workflow_stage = models.ForeignKey(
        WorkflowStage,
        on_delete=models.PROTECT,
        related_name='qa_results',
        verbose_name='Checked Stage'
    )
    
    checked_by = models.ForeignKey(
        'employees.Employee',
        on_delete=models.SET_NULL,
        null=True,
        related_name='qa_checks_performed',
        verbose_name='Checked By'
    )
    
    result = models.CharField(
        max_length=10,
        choices=RESULT_CHOICES,
        verbose_name='Result'
    )
    
    issue_type = models.CharField(
        max_length=20,
        choices=ISSUE_TYPE_CHOICES,
        blank=True,
        verbose_name='Issue Type'
    )
    
    issues_found = models.TextField(
        blank=True,
        verbose_name='Issues Found',
        help_text='Detailed description of issues'
    )
    
    photos = models.JSONField(
        default=list,
        blank=True,
        verbose_name='Issue Photos',
        help_text='URLs of photos showing issues'
    )
    
    send_back_to = models.ForeignKey(
        WorkflowStage,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='rework_orders',
        verbose_name='Send Back To',
        help_text='Stage to send back for rework'
    )
    
    checked_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    objects = TenantManager()
    all_objects = models.Manager()  
    
    class Meta:
        verbose_name = 'Quality Check Result'
        verbose_name_plural = 'Quality Check Results'
        ordering = ['-checked_at']
        indexes = [
            models.Index(fields=['tenant', 'result']),
            models.Index(fields=['order', 'checked_at']),
        ]
    
    def __str__(self):
        return f"QA: {self.order.order_number} - {self.result}"


class TrialFeedback(models.Model):
    """
    Customer trial feedback
    Track trial results and alterations needed
    """
    
    TRIAL_RESULT_CHOICES = [
        ('APPROVED', 'Approved - No changes'),
        ('MINOR_ALTERATIONS', 'Minor Alterations Needed'),
        ('MAJOR_ALTERATIONS', 'Major Alterations Needed'),
        ('REJECTED', 'Rejected - Remake'),
    ]
    
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='trial_feedbacks'
    )
    
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.CASCADE,
        related_name='trial_feedbacks',
        verbose_name='Order'
    )
    
    trial_date = models.DateTimeField(
        default=timezone.now,
        verbose_name='Trial Date'
    )
    
    trial_result = models.CharField(
        max_length=20,
        choices=TRIAL_RESULT_CHOICES,
        verbose_name='Trial Result'
    )
    
    customer_feedback = models.TextField(
        blank=True,
        verbose_name='Customer Feedback'
    )
    
    alterations_needed = models.TextField(
        blank=True,
        verbose_name='Alterations Needed',
        help_text='Detailed list of changes required'
    )
    
    photos = models.JSONField(
        default=list,
        blank=True,
        verbose_name='Trial Photos'
    )
    
    conducted_by = models.ForeignKey(
        'employees.Employee',
        on_delete=models.SET_NULL,
        null=True,
        related_name='trials_conducted',
        verbose_name='Conducted By'
    )
    
    next_trial_date = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Next Trial Date'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    objects = TenantManager()
    all_objects = models.Manager()
    
    class Meta:
        verbose_name = 'Trial Feedback'
        verbose_name_plural = 'Trial Feedbacks'
        ordering = ['-trial_date']
        indexes = [
            models.Index(fields=['tenant', 'trial_date']),
            models.Index(fields=['order', 'trial_date']),
        ]
    
    def __str__(self):
        return f"Trial: {self.order.order_number} - {self.trial_result}"