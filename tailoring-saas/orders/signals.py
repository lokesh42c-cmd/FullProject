"""
Orders App Signals - Stock Management & Auto-population
Date: 2026-01-09
"""

from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
from decimal import Decimal
from django.db import transaction
from .models import OrderItem, Item, StockTransaction
from core.models import Tenant
from masters.models import ItemUnit


# ==================== STOCK DEDUCTION ON ORDER ITEM CREATION ====================

@receiver(post_save, sender=OrderItem)
def deduct_stock_on_order_item_save(sender, instance, created, **kwargs):
    """
    Deduct stock when OrderItem is created
    Only if item has track_stock enabled
    """
    if not created:
        return  # Only handle new items, not updates
    
    item = instance.item
    if not item or not item.track_stock:
        return  # No stock tracking needed
    
    # Check stock availability
    if not item.allow_negative_stock and item.current_stock < instance.quantity:
        # This should be validated in serializer, but double-check here
        from django.core.exceptions import ValidationError
        raise ValidationError(
            f"Insufficient stock for {item.name}. Available: {item.current_stock}, Required: {instance.quantity}"
        )
    
    # Deduct stock
    with transaction.atomic():
        stock_before = item.current_stock
        item.current_stock -= instance.quantity
        
        # Mark item as used (lock critical fields)
        if not item.has_been_used:
            item.has_been_used = True
        
        item.save(update_fields=['current_stock', 'has_been_used'])
        
        # Create stock transaction record
        StockTransaction.objects.create(
            tenant=item.tenant,
            item=item,
            transaction_type='OUT',
            quantity=-instance.quantity,  # Negative for OUT
            stock_before=stock_before,
            stock_after=item.current_stock,
            reference_type='ORDER',
            reference_id=instance.order.order_number,
            notes=f"Stock deducted for Order {instance.order.order_number} - {instance.item_description}",
            created_by=instance.order.created_by
        )


# ==================== RESTORE STOCK ON ORDER ITEM DELETION ====================

@receiver(post_delete, sender=OrderItem)
def restore_stock_on_order_item_delete(sender, instance, **kwargs):
    """
    Restore stock when OrderItem is deleted
    Only if item has track_stock enabled
    """
    item = instance.item
    if not item or not item.track_stock:
        return
    
    # Restore stock
    with transaction.atomic():
        stock_before = item.current_stock
        item.current_stock += instance.quantity
        item.save(update_fields=['current_stock'])
        
        # Create stock transaction record
        StockTransaction.objects.create(
            tenant=item.tenant,
            item=item,
            transaction_type='IN',
            quantity=instance.quantity,  # Positive for IN
            stock_before=stock_before,
            stock_after=item.current_stock,
            reference_type='ADJUSTMENT',
            reference_id=instance.order.order_number,
            notes=f"Stock restored - Order Item deleted from Order {instance.order.order_number}",
            created_by=None  # Deletion may not have user context
        )


# ==================== AUTO-POPULATE ORDERITEM FROM ITEM MASTER ====================

@receiver(pre_save, sender=OrderItem)
def auto_populate_from_item_master(sender, instance, **kwargs):
    """
    Auto-populate OrderItem fields from Item master when item is selected
    Only for new OrderItems
    """
    if instance.pk:  # Skip if updating existing
        return
    
    if not instance.item:
        return
    
    item = instance.item
    
    # Auto-populate description if not provided
    if not instance.item_description:
        instance.item_description = item.name
    
    # Auto-populate unit_price from item's selling_price if not set
    if instance.unit_price == Decimal('0.00') and item.selling_price:
        instance.unit_price = item.selling_price
    
    # Auto-populate tax_percentage from item's tax_percent if not set
    if instance.tax_percentage == Decimal('0.00') and item.tax_percent:
        instance.tax_percentage = item.tax_percent
    
    # Auto-set item_type from item
    if not instance.item_type:
        instance.item_type = item.item_type


# ==================== CREATE DEFAULT ITEM UNITS FOR NEW TENANTS ====================

@receiver(post_save, sender=Tenant)
def create_default_item_units(sender, instance, created, **kwargs):
    """
    Create default ItemUnits when new tenant is created
    """
    if not created:
        return
    
    default_units = [
        ('Pieces', 'PCS', 1),
        ('Meters', 'MTR', 2),
        ('Sets', 'SET', 3),
        ('Hours', 'HRS', 4),
        ('Pairs', 'PAIR', 5),
        ('Units', 'UNIT', 6),
    ]
    
    for name, code, order in default_units:
        ItemUnit.objects.get_or_create(
            tenant=instance,
            code=code,
            defaults={
                'name': name,
                'display_order': order
            }
        )


# ==================== INITIALIZE CURRENT STOCK FROM OPENING STOCK ====================

@receiver(post_save, sender=Item)
def initialize_stock_on_item_creation(sender, instance, created, **kwargs):
    """
    Initialize current_stock from opening_stock when item is created
    Create opening stock transaction
    """
    if not created:
        return
    
    if not instance.track_stock:
        return
    
    # If opening_stock is set and current_stock is not initialized
    if instance.opening_stock > 0 and instance.current_stock == 0:
        with transaction.atomic():
            instance.current_stock = instance.opening_stock
            instance.save(update_fields=['current_stock'])
            
            # Create opening stock transaction
            StockTransaction.objects.create(
                tenant=instance.tenant,
                item=instance,
                transaction_type='IN',
                quantity=instance.opening_stock,
                stock_before=Decimal('0.00'),
                stock_after=instance.opening_stock,
                reference_type='ADJUSTMENT',
                reference_id=f'OPENING-{instance.id}',
                notes='Opening stock entry',
                created_by=None
            )