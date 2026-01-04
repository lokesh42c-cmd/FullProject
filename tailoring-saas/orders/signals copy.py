from django.db.models.signals import pre_save
from django.db.models.signals import post_save

from django.dispatch import receiver
from decimal import Decimal
from core.models import Tenant
//from .models import ItemUnit


@receiver(pre_save, sender='orders.OrderItem')
def auto_populate_from_inventory(sender, instance, **kwargs):
    """
    Automatically populate OrderItem fields from linked inventory
    Triggers when inventory_item is set
    """
    if instance.inventory_item and not instance.pk:  # New item with inventory link
        # Call the populate method we created earlier
        instance.populate_from_inventory()

@receiver(post_save, sender=Tenant)
def create_default_item_units(sender, instance, created, **kwargs):
    if not created:
        return

    default_units = [
        ('Pieces', 'PCS'),
        ('Meters', 'MTR'),
        ('Sets', 'SET'),
        ('Hours', 'HRS'),
    ]

    for order, (name, code) in enumerate(default_units):
        ItemUnit.objects.get_or_create(
            tenant=instance,
            code=code,
            defaults={
                'name': name,
                'display_order': order
            }
        )
