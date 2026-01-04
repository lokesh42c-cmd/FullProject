"""
Purchase Management Signals
Auto-update payment status and vendor balances
"""

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db.models import Sum
from decimal import Decimal

from .models import Payment, PurchaseBill, Expense, Vendor


@receiver(post_save, sender=Payment)
@receiver(post_delete, sender=Payment)
def update_bill_payment_status(sender, instance, **kwargs):
    """
    Update PurchaseBill when payment is added/deleted
    Recalculates: paid_amount, balance_amount, payment_status
    """
    if instance.payment_type == Payment.PaymentType.PURCHASE_BILL and instance.purchase_bill:
        bill = instance.purchase_bill
        
        # Calculate total paid from all payments
        total_paid = bill.payments.aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0.00')
        
        # Update bill amounts
        bill.paid_amount = total_paid
        bill.balance_amount = bill.bill_amount - total_paid
        
        # Update payment status based on balance
        if bill.balance_amount <= 0:
            bill.payment_status = PurchaseBill.PaymentStatus.FULLY_PAID
        elif bill.paid_amount > 0:
            bill.payment_status = PurchaseBill.PaymentStatus.PARTIALLY_PAID
        else:
            bill.payment_status = PurchaseBill.PaymentStatus.UNPAID
        
        # Save without triggering signals again
        bill.save(update_fields=['paid_amount', 'balance_amount', 'payment_status', 'updated_at'])
        
        # Update vendor balance
        update_vendor_balance(bill.vendor)


@receiver(post_save, sender=Payment)
@receiver(post_delete, sender=Payment)
def update_expense_payment_status(sender, instance, **kwargs):
    """
    Update Expense when payment is added/deleted
    Recalculates: paid_amount, balance_amount, payment_status
    """
    if instance.payment_type == Payment.PaymentType.EXPENSE and instance.expense:
        expense = instance.expense
        
        # Calculate total paid from all payments
        total_paid = expense.payments.aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0.00')
        
        # Update expense amounts
        expense.paid_amount = total_paid
        expense.balance_amount = expense.expense_amount - total_paid
        
        # Update payment status based on balance
        if expense.balance_amount <= 0:
            expense.payment_status = Expense.PaymentStatus.FULLY_PAID
        elif expense.paid_amount > 0:
            expense.payment_status = Expense.PaymentStatus.PARTIALLY_PAID
        else:
            expense.payment_status = Expense.PaymentStatus.UNPAID
        
        # Save without triggering signals again
        expense.save(update_fields=['paid_amount', 'balance_amount', 'payment_status', 'updated_at'])


@receiver(post_save, sender=PurchaseBill)
@receiver(post_delete, sender=PurchaseBill)
def update_vendor_on_bill_change(sender, instance, **kwargs):
    """Update vendor balance when bill is created/updated/deleted"""
    update_vendor_balance(instance.vendor)


def update_vendor_balance(vendor):
    """
    Recalculate vendor outstanding balance
    Called from multiple signals to keep vendor totals accurate
    """
    # Total purchases (sum of all bill amounts)
    total_purchases = vendor.bills.aggregate(
        total=Sum('bill_amount')
    )['total'] or Decimal('0.00')
    
    # Total paid (sum of all paid amounts)
    total_paid = vendor.bills.aggregate(
        total=Sum('paid_amount')
    )['total'] or Decimal('0.00')
    
    # Calculate outstanding
    outstanding = total_purchases - total_paid
    
    # Update vendor
    vendor.total_purchases = total_purchases
    vendor.total_paid = total_paid
    vendor.outstanding_balance = outstanding
    
    # Save without triggering signals
    vendor.save(update_fields=['total_purchases', 'total_paid', 'outstanding_balance', 'updated_at'])