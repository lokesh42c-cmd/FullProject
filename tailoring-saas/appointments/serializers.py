from rest_framework import serializers
from .models import Appointment


class AppointmentListSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(
        source='get_status_display',
        read_only=True
    )

    class Meta:
        model = Appointment
        fields = [
            'id',
            'name',
            'phone',
            'date',
            'start_time',
            'duration_minutes',
            'service',
            'notes',  
            'status',
            'status_display'
        ]


class AppointmentCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Appointment
        fields = [
            'id',
            'name',
            'phone',
            'date',
            'start_time',
            'duration_minutes',
            'rescheduled_date',
            'service',
            'notes',
            'status'
        ]
        read_only_fields = ['id']
