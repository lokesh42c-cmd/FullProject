# TailorPro Backend - Handover Document

**Date:** 2026-01-04  
**Status:** ✅ Backend Complete - Ready for Flutter Integration

---

## **What We Built**

### **3 Core Apps:**
1. **orders** - Customer, Order, OrderItem, Item (with inventory)
2. **invoicing** - Invoice, InvoiceItem (GST compliant)
3. **financials** - ReceiptVoucher, Payment, RefundVoucher

---

## **Key Models & Fields**

### **Customer Model**
- Basic: name, phone, whatsapp, email, gender, customer_type (B2C/B2B)
- Business: business_name, gstin, pan
- Address: address, city, state, pincode
- **Measurements:** All gender-specific fields (women/men) + custom fields 1-10
- Soft delete: is_active, deleted_at

### **Order Model**
- Order tracking: order_number (auto), order_date, expected_delivery_date
- Status: order_status, delivery_status
- Work: assigned_to (employee assignment)
- **QR Code:** Auto-generated for tracking
- **Reference Photos:** Unlimited via OrderReferencePhoto model
- Lock: is_locked (after invoice created)

### **Item Model (Unified Catalog)**
- Type: item_type (SERVICE/PRODUCT)
- **Inventory:** track_stock (yes/no), current_stock, min_stock_level, allow_negative_stock
- Stock: opening_stock, current_stock (auto-calculated)
- Pricing: purchase_price, selling_price (both optional)
- GST: hsn_sac_code, tax_percent
- Barcode: barcode field
- Safety: has_been_used (locks critical fields), is_active, deleted_at

### **Invoice Model**
- Numbers: invoice_number (INV-YYYYMM-00001)
- Customer: Links to Customer
- Order: Optional link to Order (null for walk-ins)
- **Addresses:** billing_address, shipping_address (snapshot at invoice time)
- **GST:** tax_type (INTRASTATE/INTERSTATE/ZERO based on tenant.gst_enabled + states)
- Amounts: subtotal, cgst, sgst, igst, grand_total
- **Advance:** total_advance_adjusted (from ReceiptVouchers)
- Payment: total_paid, remaining_balance, payment_status

### **ReceiptVoucher Model (Advance)**
- Numbers: voucher_number (RV-YYYYMM-00001)
- **GST on Advance:** advance_amount + cgst + sgst/igst = total_amount
- Link: customer, order (optional)
- **Adjustment:** adjusted_amount (property: is_adjusted)
- Cash tracking: deposited_to_bank, deposit_date

### **Payment Model**
- Links to Invoice only
- No GST (GST already in invoice)
- Tracks: amount, payment_mode, transaction_reference

### **RefundVoucher Model**
- Links to original ReceiptVoucher
- **GST Reversal:** Copies GST from original receipt and reverses

---

## **Critical Business Rules**

### **GST Logic (FIXED)**
✅ ZERO GST only when:
- `tenant.gst_enabled = False` OR
- `item.tax_percent = 0`

❌ NOT based on customer GSTIN

### **Inventory Logic**
- If `item.track_stock = True` → deduct stock on order/invoice
- If `allow_negative_stock = True` → allow orders even when stock low
- StockTransaction: Auto-created audit trail (IN/OUT/ADJUSTMENT)

### **Safety Features**
- **Soft Delete:** Never hard-delete Customer, Order, Item (use is_active=False)
- **Lock Fields:** After item used in order: lock item_type, track_stock, unit
- **Opening Stock:** Editable only once on creation
- **Immutability:** Issued receipts/invoices cannot be edited (set is_issued)

---

## **Auto-Generated Fields**
- order_number: ORD-YYYYMM-00001
- invoice_number: INV-YYYYMM-00001
- voucher_number: RV-YYYYMM-00001
- payment_number: PAY-YYYYMM-00001
- refund_number: RF-YYYYMM-00001
- QR codes: Auto-generated for orders and inventory items

---

## **Database Status**
✅ All models created  
✅ Migrations applied  
✅ Admin interfaces ready  
✅ GST compliance fixed  
✅ Inventory integrated into Item model

---

## **Files to Use**
1. `orders/models.py` - orders_models_final.py
2. `orders/admin.py` - orders_admin_final.py
3. `invoicing/models.py` - invoicing_models_fixed.py
4. `financials/models.py` - financials_models_fixed.py
5. `financials/admin.py` - financials_admin_fixed.py

---

## **API Endpoints Ready**
- `/api/orders/customers/`
- `/api/orders/orders/`
- `/api/orders/items/`
- `/api/invoicing/invoices/`
- `/api/financials/receipts/`
- `/api/financials/payments/`
- `/api/financials/refunds/`

---

## **Next Steps for Flutter**
1. Build Customer screens (with measurements UI)
2. Build Order screens (with QR scan + reference photos)
3. Build Item catalog (with stock tracking toggle)
4. Build Invoice screen (GST calculation)
5. Build Receipt/Payment screens
6. Integrate QR code scanner for order tracking

---

**Backend Team:** Complete ✅  
**Flutter Team:** Ready to start 🚀
