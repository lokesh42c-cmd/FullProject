from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend

from .models import Appointment
from .serializers import (
    AppointmentListSerializer,
    AppointmentCreateSerializer
)


class AppointmentViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['status', 'date']
    search_fields = ['name', 'phone', 'service']

    def get_serializer_class(self):
        if self.action == 'list':
            return AppointmentListSerializer
        return AppointmentCreateSerializer

    def get_queryset(self):
        user = self.request.user
        if not hasattr(user, 'tenant') or not user.tenant:
            return Appointment.objects.none()

        return Appointment.objects.filter(
            tenant=user.tenant
        ).order_by('date', 'start_time')

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.user.tenant)
