"""
Debug script to check why Invoice 4 has ₹0 balance
"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from invoicing.models import Invoice, InvoiceItem
from orders.models import Order

# Get invoice and order
invoice = Invoice.objects.get(id=4)
order = Order.objects.get(id=47)

print(f"Invoice has {invoice.items.count()} items")
print(f"Order has {order.items.count()} items")

# Copy items from order to invoice
for order_item in order.items.all():
    InvoiceItem.objects.create(
        invoice=invoice,
        item=order_item.item,
        item_description=order_item.item_description,
        hsn_sac_code=order_item.item.hsn_sac_code if order_item.item else '',
        quantity=order_item.quantity,
        unit_price=order_item.unit_price,
        gst_rate=order_item.item.tax_percent if order_item.item else 0,
        item_type='SERVICE'
    )
    print(f"  Added: {order_item.item_description} - ₹{order_item.total_price}")

# Recalculate totals
invoice.calculate_totals()

print(f"\n✅ Invoice now has:")
print(f"  Grand Total: ₹{invoice.grand_total}")
print(f"  Advances: ₹{invoice.total_advance_adjusted}")
print(f"  Remaining Balance: ₹{invoice.remaining_balance}")

from invoicing.models import Invoice

invoice = Invoice.objects.get(id=4)

print(f"Tax Type: {invoice.tax_type}")
print(f"Billing State: {invoice.billing_state}")
print(f"Tenant State: {invoice.tenant.state if hasattr(invoice.tenant, 'state') else 'N/A'}")

# Check items
for item in invoice.items.all():
    print(f"\nItem: {item.item_description}")
    print(f"  Subtotal: ₹{item.subtotal}")
    print(f"  GST Rate: {item.gst_rate}%")
    print(f"  CGST: ₹{item.cgst_amount}")
    print(f"  SGST: ₹{item.sgst_amount}")
    print(f"  IGST: ₹{item.igst_amount}")
    print(f"  Total: ₹{item.total_amount}")

exit()

exit()