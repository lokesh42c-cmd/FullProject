from django.db import models
from core.managers import TenantManager
from django.core.exceptions import ValidationError


def validate_phone_number(value):
    if not value:
        return
    cleaned = value.strip()
    if not cleaned.isdigit() or len(cleaned) != 10:
        raise ValidationError("Phone number must be exactly 10 digits")


class Appointment(models.Model):
    tenant = models.ForeignKey(
        'core.Tenant',
        on_delete=models.CASCADE,
        related_name='appointments'
    )

    # Basic info (NO customer dependency)
    name = models.CharField(max_length=100)
    phone = models.CharField(
        max_length=15,
        validators=[validate_phone_number]
    )

    # Scheduling
    date = models.DateField()
    start_time = models.TimeField()
    duration_minutes = models.PositiveIntegerField(default=30)

    # Optional
    rescheduled_date = models.DateField(null=True, blank=True)
    service = models.CharField(max_length=200, blank=True)
    notes = models.TextField(blank=True)

    STATUS_CHOICES = [
        ('SCHEDULED', 'Scheduled'),
        ('RESCHEDULED', 'Rescheduled'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
        ('NO_SHOW', 'No Show'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='SCHEDULED'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = TenantManager()
    all_objects = models.Manager()

    class Meta:
        ordering = ['date', 'start_time']
        indexes = [
            models.Index(fields=['tenant', 'date']),
            models.Index(fields=['tenant', 'phone']),
            models.Index(fields=['tenant', 'status']),
        ]

    def __str__(self):
        return f"{self.name} - {self.date} {self.start_time}"
