from django.apps import AppConfig


class OrdersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'orders'
    verbose_name = 'Orders & Workflow Management'

    def ready(self):
        """Import signals when app is ready"""
 #       import orders.signals  # noqa