/// OrderItem Model
/// Matches: orders.OrderItem from backend
class OrderItem {
  final int? id;
  final int? orderId;

  // Item Link
  final String itemType; // SERVICE or PRODUCT
  final int? itemId;
  final String itemDescription;
  final String? itemName; // From API response
  final String? itemBarcode; // From API response

  // Pricing
  final double quantity;
  final double unitPrice;
  final double discount; // Discount amount per item
  final double taxPercentage;

  // Status
  final String status; // PENDING, IN_PROGRESS, COMPLETED
  final String? notes;

  // Audit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderItem({
    this.id,
    this.orderId,
    required this.itemType,
    this.itemId,
    required this.itemDescription,
    this.itemName,
    this.itemBarcode,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.discount = 0.0,
    this.taxPercentage = 0.0,
    this.status = 'PENDING',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Computed properties (match backend @property methods)
  double get subtotal => (quantity * unitPrice) - discount;

  double get taxAmount => (subtotal * taxPercentage) / 100;

  double get totalPrice => subtotal + taxAmount;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      orderId: json['order'] as int?,
      itemType: json['item_type'] as String? ?? 'SERVICE',
      itemId: json['item'] as int?,
      itemDescription: json['item_description'] as String,
      itemName: json['item_name'] as String?,
      itemBarcode: json['item_barcode'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (orderId != null) 'order': orderId,
      'item_type': itemType,
      if (itemId != null) 'item': itemId,
      'item_description': itemDescription,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'tax_percentage': taxPercentage,
      'status': status,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  OrderItem copyWith({
    int? id,
    int? orderId,
    String? itemType,
    int? itemId,
    String? itemDescription,
    String? itemName,
    String? itemBarcode,
    double? quantity,
    double? unitPrice,
    double? discount,
    double? taxPercentage,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      itemDescription: itemDescription ?? this.itemDescription,
      itemName: itemName ?? this.itemName,
      itemBarcode: itemBarcode ?? this.itemBarcode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Recalculate prices when tax mode changes (inclusive/exclusive)
  OrderItem recalculateForTaxMode({required bool isTaxInclusive}) {
    if (isTaxInclusive) {
      // Convert to tax inclusive - reduce unit price
      final taxableAmount = unitPrice / (1 + taxPercentage / 100);
      return copyWith(unitPrice: taxableAmount);
    }
    // Tax exclusive - keep as is
    return this;
  }
}
