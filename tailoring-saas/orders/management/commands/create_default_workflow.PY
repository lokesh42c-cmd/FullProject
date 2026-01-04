"""
Management command to create default workflow stages for a tenant
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from core.models import Tenant
from employees.models import Department
from orders.workflow_models import WorkflowStage


class Command(BaseCommand):
    help = 'Create default workflow stages for a tenant'
    
    def add_arguments(self, parser):
        parser.add_argument(
            'tenant_id',
            type=int,
            help='Tenant ID to create workflow for'
        )
    
    def handle(self, *args, **options):
        tenant_id = options['tenant_id']
        
        try:
            tenant = Tenant.objects.get(id=tenant_id)
        except Tenant.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'Tenant with ID {tenant_id} not found'))
            return
        
        self.stdout.write(f'Creating default workflow for: {tenant.name}')
        
        # Get or create departments
        departments = {}
        dept_names = {
            'DESIGN': 'Design Department',
            'CUTTING': 'Cutting Department',
            'EMBROIDERY': 'Embroidery Department',
            'TAILORING': 'Tailoring Department',
            'QA': 'Quality Assurance',
            'TRIAL': 'Trial & Alterations'
        }
        
        for key, name in dept_names.items():
            dept, created = Department.objects.get_or_create(
                tenant=tenant,
                name=name,
                defaults={'is_active': True}
            )
            departments[key] = dept
            if created:
                self.stdout.write(self.style.SUCCESS(f'  Created department: {name}'))
        
        # Define default workflow stages
        stages = [
            {
                'stage_type': 'ORDER_RECEIVED',
                'name': 'Order Received',
                'department': None,
                'sequence_order': 1,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 0.5
            },
            {
                'stage_type': 'DESIGN',
                'name': 'Design & Approval',
                'department': departments['DESIGN'],
                'sequence_order': 2,
                'is_optional': False,
                'requires_approval': True,
                'estimated_hours': 2.0
            },
            {
                'stage_type': 'PATTERN_MAKING',
                'name': 'Pattern Making',
                'department': departments['CUTTING'],
                'sequence_order': 3,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 1.5
            },
            {
                'stage_type': 'EMBROIDERY_DESIGN',
                'name': 'Embroidery Design',
                'department': departments['EMBROIDERY'],
                'sequence_order': 4,
                'is_optional': True,
                'requires_approval': True,
                'estimated_hours': 1.0
            },
            {
                'stage_type': 'EMBROIDERY_WORK',
                'name': 'Embroidery Execution',
                'department': departments['EMBROIDERY'],
                'sequence_order': 5,
                'is_optional': True,
                'requires_approval': False,
                'estimated_hours': 4.0
            },
            {
                'stage_type': 'EMBROIDERY_QA',
                'name': 'Embroidery Quality Check',
                'department': departments['QA'],
                'sequence_order': 6,
                'is_optional': True,
                'requires_approval': False,
                'estimated_hours': 0.5
            },
            {
                'stage_type': 'CUTTING',
                'name': 'Fabric Cutting',
                'department': departments['CUTTING'],
                'sequence_order': 7,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 1.0
            },
            {
                'stage_type': 'TAILORING',
                'name': 'Stitching Work',
                'department': departments['TAILORING'],
                'sequence_order': 8,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 6.0
            },
            {
                'stage_type': 'FINISHING',
                'name': 'Finishing & Ironing',
                'department': departments['TAILORING'],
                'sequence_order': 9,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 1.0
            },
            {
                'stage_type': 'QA_CHECK',
                'name': 'Quality Inspection',
                'department': departments['QA'],
                'sequence_order': 10,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 0.5
            },
            {
                'stage_type': 'TRIAL',
                'name': 'Customer Trial',
                'department': departments['TRIAL'],
                'sequence_order': 11,
                'is_optional': False,
                'requires_approval': True,
                'estimated_hours': 0.5
            },
            {
                'stage_type': 'ALTERATIONS',
                'name': 'Alterations',
                'department': departments['TAILORING'],
                'sequence_order': 12,
                'is_optional': True,
                'requires_approval': False,
                'estimated_hours': 2.0
            },
            {
                'stage_type': 'FINAL_QA',
                'name': 'Final Quality Check',
                'department': departments['QA'],
                'sequence_order': 13,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 0.3
            },
            {
                'stage_type': 'READY_FOR_DELIVERY',
                'name': 'Ready for Delivery',
                'department': None,
                'sequence_order': 14,
                'is_optional': False,
                'requires_approval': False,
                'estimated_hours': 0.0
            },
        ]
        
        # Create stages
        with transaction.atomic():
            created_count = 0
            for stage_data in stages:
                stage, created = WorkflowStage.objects.get_or_create(
                    tenant=tenant,
                    stage_type=stage_data['stage_type'],
                    defaults=stage_data
                )
                if created:
                    created_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'  ✓ Created: {stage.sequence_order}. {stage.name}'
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(
                            f'  - Exists: {stage.sequence_order}. {stage.name}'
                        )
                    )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'\n✓ Created {created_count} workflow stages for {tenant.name}'
            )
        )