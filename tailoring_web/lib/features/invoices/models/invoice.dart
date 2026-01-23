/// Invoice Model
/// Matches backend invoicing.Invoice
class Invoice {
  final int? id;
  final String invoiceNumber;
  final String invoiceDate;
  final int customer;
  final String? customerName;
  final String? customerPhone;
  final int? order;
  final String? orderNumber;
  final String status; // DRAFT, ISSUED, PAID, CANCELLED
  final String? statusDisplay;

  // Billing Address
  final String billingName;
  final String billingAddress;
  final String? billingCity;
  final String billingState;
  final String? billingPincode;
  final String? billingGstin;

  // Shipping Address
  final String? shippingName;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPincode;

  // Tax Type
  final String taxType; // INTRASTATE, INTERSTATE, ZERO
  final String? taxTypeDisplay;

  // Amounts
  final double subtotal;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double grandTotal;

  // Advance & Payment
  final double totalAdvanceAdjusted;
  final double balanceDue;
  final double totalPaid;
  final double remainingBalance;

  // Payment Status
  final String paymentStatus; // UNPAID, PARTIAL, PAID
  final String? paymentStatusDisplay;

  // Items
  final List<InvoiceItem>? items;

  // Notes
  final String? notes;
  final String? termsAndConditions;

  // Audit
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customer,
    this.customerName,
    this.customerPhone,
    this.order,
    this.orderNumber,
    required this.status,
    this.statusDisplay,
    required this.billingName,
    required this.billingAddress,
    this.billingCity,
    required this.billingState,
    this.billingPincode,
    this.billingGstin,
    this.shippingName,
    this.shippingAddress,
    this.shippingCity,
    this.shippingState,
    this.shippingPincode,
    required this.taxType,
    this.taxTypeDisplay,
    this.subtotal = 0.0,
    this.totalCgst = 0.0,
    this.totalSgst = 0.0,
    this.totalIgst = 0.0,
    this.grandTotal = 0.0,
    this.totalAdvanceAdjusted = 0.0,
    this.balanceDue = 0.0,
    this.totalPaid = 0.0,
    this.remainingBalance = 0.0,
    this.paymentStatus = 'UNPAID',
    this.paymentStatusDisplay,
    this.items,
    this.notes,
    this.termsAndConditions,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      invoiceDate: json['invoice_date'] ?? '',
      customer: json['customer'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      order: json['order'],
      orderNumber: json['order_number'],
      status: json['status'] ?? 'DRAFT',
      statusDisplay: json['status_display'],
      billingName: json['billing_name'] ?? '',
      billingAddress: json['billing_address'] ?? '',
      billingCity: json['billing_city'],
      billingState: json['billing_state'] ?? '',
      billingPincode: json['billing_pincode'],
      billingGstin: json['billing_gstin'],
      shippingName: json['shipping_name'],
      shippingAddress: json['shipping_address'],
      shippingCity: json['shipping_city'],
      shippingState: json['shipping_state'],
      shippingPincode: json['shipping_pincode'],
      taxType: json['tax_type'] ?? 'INTRASTATE',
      taxTypeDisplay: json['tax_type_display'],
      subtotal: _parseDouble(json['subtotal']),
      totalCgst: _parseDouble(json['total_cgst']),
      totalSgst: _parseDouble(json['total_sgst']),
      totalIgst: _parseDouble(json['total_igst']),
      grandTotal: _parseDouble(json['grand_total']),
      totalAdvanceAdjusted: _parseDouble(json['total_advance_adjusted']),
      balanceDue: _parseDouble(json['balance_due']),
      totalPaid: _parseDouble(json['total_paid']),
      remainingBalance: _parseDouble(json['remaining_balance']),
      paymentStatus: json['payment_status'] ?? 'UNPAID',
      paymentStatusDisplay: json['payment_status_display'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => InvoiceItem.fromJson(item))
                .toList()
          : null,
      notes: json['notes'],
      termsAndConditions: json['terms_and_conditions'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer': customer,
      if (order != null) 'order': order,
      'invoice_date': invoiceDate,
      'status': status,
      'billing_name': billingName,
      'billing_address': billingAddress,
      if (billingCity != null) 'billing_city': billingCity,
      'billing_state': billingState,
      if (billingPincode != null) 'billing_pincode': billingPincode,
      if (billingGstin != null) 'billing_gstin': billingGstin,
      if (shippingName != null) 'shipping_name': shippingName,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (shippingCity != null) 'shipping_city': shippingCity,
      if (shippingState != null) 'shipping_state': shippingState,
      if (shippingPincode != null) 'shipping_pincode': shippingPincode,
      if (notes != null) 'notes': notes,
      if (termsAndConditions != null)
        'terms_and_conditions': termsAndConditions,
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Invoice Item Model
/// Matches backend invoicing.InvoiceItem
class InvoiceItem {
  final int? id;
  final int? item;
  final String? itemName;
  final String itemDescription;
  final String? hsnSacCode;
  final String itemType; // GOODS, SERVICE
  final double quantity;
  final double unitPrice;
  final double gstRate;

  // Calculated fields (read-only from backend)
  final double? subtotal;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? totalTax;
  final double? totalAmount;

  InvoiceItem({
    this.id,
    this.item,
    this.itemName,
    required this.itemDescription,
    this.hsnSacCode,
    this.itemType = 'SERVICE',
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.gstRate = 0.0,
    this.subtotal,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.totalTax,
    this.totalAmount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      item: json['item'],
      itemName: json['item_name'],
      itemDescription: json['item_description'] ?? '',
      hsnSacCode: json['hsn_sac_code'],
      itemType: json['item_type'] ?? 'SERVICE',
      quantity: _parseDouble(json['quantity']),
      unitPrice: _parseDouble(json['unit_price']),
      gstRate: _parseDouble(json['gst_rate']),
      subtotal: _parseDouble(json['subtotal']),
      cgstAmount: _parseDouble(json['cgst_amount']),
      sgstAmount: _parseDouble(json['sgst_amount']),
      igstAmount: _parseDouble(json['igst_amount']),
      totalTax: _parseDouble(json['total_tax']),
      totalAmount: _parseDouble(json['total_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (item != null) 'item': item,
      'item_description': itemDescription,
      if (hsnSacCode != null) 'hsn_sac_code': hsnSacCode,
      'item_type': itemType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'gst_rate': gstRate,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Client-side calculation helpers
  double calculateSubtotal() {
    return quantity * unitPrice;
  }

  double calculateCgst(String taxType) {
    if (taxType == 'INTRASTATE' && gstRate > 0) {
      return (calculateSubtotal() * gstRate / 2) / 100;
    }
    return 0.0;
  }

  double calculateSgst(String taxType) {
    if (taxType == 'INTRASTATE' && gstRate > 0) {
      return (calculateSubtotal() * gstRate / 2) / 100;
    }
    return 0.0;
  }

  double calculateIgst(String taxType) {
    if (taxType == 'INTERSTATE' && gstRate > 0) {
      return (calculateSubtotal() * gstRate) / 100;
    }
    return 0.0;
  }

  double calculateTotalAmount(String taxType) {
    return calculateSubtotal() +
        calculateCgst(taxType) +
        calculateSgst(taxType) +
        calculateIgst(taxType);
  }
}
