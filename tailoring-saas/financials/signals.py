"""
Financials app signals - Auto-recalculate invoice when payments change
Date: 2026-01-27
"""

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import ReceiptVoucher, Payment, RefundVoucher


@receiver(post_save, sender=ReceiptVoucher)
def recalculate_invoice_on_receipt_save(sender, instance, created, **kwargs):
    """Recalculate invoice when receipt voucher is created"""
    if instance.order and hasattr(instance.order, 'invoice') and instance.order.invoice:
        instance.order.invoice.calculate_totals()


@receiver(post_delete, sender=ReceiptVoucher)
def recalculate_invoice_on_receipt_delete(sender, instance, **kwargs):
    """Recalculate invoice when receipt voucher is deleted"""
    if instance.order and hasattr(instance.order, 'invoice') and instance.order.invoice:
        instance.order.invoice.calculate_totals()


@receiver(post_save, sender=Payment)
def recalculate_invoice_on_payment_save(sender, instance, created, **kwargs):
    """Recalculate invoice when payment is created"""
    if instance.invoice:
        instance.invoice.calculate_totals()


@receiver(post_delete, sender=Payment)
def recalculate_invoice_on_payment_delete(sender, instance, **kwargs):
    """Recalculate invoice when payment is deleted"""
    if instance.invoice:
        instance.invoice.calculate_totals()


@receiver(post_save, sender=RefundVoucher)
def recalculate_invoice_on_refund_save(sender, instance, created, **kwargs):
    """Recalculate invoice when refund is created"""
    if instance.receipt_voucher.order and hasattr(instance.receipt_voucher.order, 'invoice') and instance.receipt_voucher.order.invoice:
        instance.receipt_voucher.order.invoice.calculate_totals()


@receiver(post_delete, sender=RefundVoucher)
def recalculate_invoice_on_refund_delete(sender, instance, **kwargs):
    """Recalculate invoice when refund is deleted"""
    if instance.receipt_voucher.order and hasattr(instance.receipt_voucher.order, 'invoice') and instance.receipt_voucher.order.invoice:
        instance.receipt_voucher.order.invoice.calculate_totals()