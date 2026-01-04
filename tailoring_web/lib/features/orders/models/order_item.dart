import 'package:tailoring_web/features/items/models/item.dart';

/// Order Item Model - COMPLETE with all methods for both detail and create screens
class OrderItem {
  final int? id;
  final int orderId;
  final int itemId;
  final Item? item;

  // ✅ Backend sends: item_description, item_type
  final String? itemDescription;
  final String? itemType;

  final double quantity;
  final double unitPrice;

  // Discounts
  final double itemDiscountPercentage;
  final double itemDiscountAmount;

  // Tax - Backend sends: tax_percentage
  final double taxPercentage;
  final double taxAmount;

  // Totals - CALCULATED from backend data
  final double subtotal;
  final double total;

  // Additional fields from backend
  final String? hsnCode;
  final String? unit;

  OrderItem({
    this.id,
    required this.orderId,
    required this.itemId,
    this.item,
    this.itemDescription,
    this.itemType,
    required this.quantity,
    required this.unitPrice,
    this.itemDiscountPercentage = 0.0,
    this.itemDiscountAmount = 0.0,
    required this.taxPercentage,
    required this.taxAmount,
    required this.subtotal,
    required this.total,
    this.hsnCode,
    this.unit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Parse quantities and prices
    final quantity = _parseDouble(json['quantity']) ?? 1.0;
    final unitPrice = _parseDouble(json['unit_price']) ?? 0.0;
    final discountPct = _parseDouble(json['item_discount_percentage']) ?? 0.0;
    final taxPct = _parseDouble(json['tax_percentage']) ?? 0.0;

    // Calculate values (backend doesn't send these)
    final baseAmount = quantity * unitPrice;
    final discountAmount = baseAmount * (discountPct / 100);
    final subtotalCalc = baseAmount - discountAmount;
    final taxAmount = subtotalCalc * (taxPct / 100);
    final totalCalc = subtotalCalc + taxAmount;

    return OrderItem(
      id: json['id'] as int?,
      orderId: json['order'] as int? ?? 0,
      itemId: json['item'] as int? ?? 0,
      item: null,
      itemDescription: json['item_description'] as String?,
      itemType: json['item_type'] as String?,
      quantity: quantity,
      unitPrice: unitPrice,
      itemDiscountPercentage: discountPct,
      itemDiscountAmount: discountAmount,
      taxPercentage: taxPct,
      taxAmount: taxAmount,
      subtotal: subtotalCalc,
      total: totalCalc,
      hsnCode: json['hsn_code'] as String?,
      unit: json['unit'] as String?,
    );
  }

  /// ✅ Factory for creating OrderItem from Item (for create order screen)
  factory OrderItem.fromItem({
    required Item item,
    required int orderId,
    double quantity = 1.0,
    double? customPrice,
    double itemDiscountPercentage = 0.0,
    bool isTaxInclusive = false,
  }) {
    final unitPrice = customPrice ?? item.price;
    final baseAmount = quantity * unitPrice;
    final discountAmount = baseAmount * (itemDiscountPercentage / 100);
    final subtotalCalc = baseAmount - discountAmount;

    // Handle tax inclusive/exclusive
    double taxAmount;
    double totalCalc;

    if (isTaxInclusive) {
      // Reverse calculate tax from inclusive price
      totalCalc = subtotalCalc;
      taxAmount = subtotalCalc - (subtotalCalc / (1 + (item.taxPercent / 100)));
    } else {
      // Add tax on top
      taxAmount = subtotalCalc * (item.taxPercent / 100);
      totalCalc = subtotalCalc + taxAmount;
    }

    return OrderItem(
      orderId: orderId,
      itemId: item.id!,
      item: item,
      itemDescription: item.name,
      itemType: item.itemType,
      quantity: quantity,
      unitPrice: unitPrice,
      itemDiscountPercentage: itemDiscountPercentage,
      itemDiscountAmount: discountAmount,
      taxPercentage: item.taxPercent,
      taxAmount: taxAmount,
      subtotal: subtotalCalc,
      total: totalCalc,
      hsnCode: item.hsnSacCode,
      unit: item.unit?.code,
    );
  }

  /// ✅ Recalculate method (for create order screen when values change)
  OrderItem recalculate({
    double? quantity,
    double? unitPrice,
    double? itemDiscountPercentage,
    bool? isTaxInclusive,
  }) {
    final newQuantity = quantity ?? this.quantity;
    final newUnitPrice = unitPrice ?? this.unitPrice;
    final newDiscountPct =
        itemDiscountPercentage ?? this.itemDiscountPercentage;
    final taxInclusive = isTaxInclusive ?? false;

    final baseAmount = newQuantity * newUnitPrice;
    final discountAmount = baseAmount * (newDiscountPct / 100);
    final subtotalCalc = baseAmount - discountAmount;

    double taxAmount;
    double totalCalc;

    if (taxInclusive) {
      totalCalc = subtotalCalc;
      taxAmount = subtotalCalc - (subtotalCalc / (1 + (taxPercentage / 100)));
    } else {
      taxAmount = subtotalCalc * (taxPercentage / 100);
      totalCalc = subtotalCalc + taxAmount;
    }

    return OrderItem(
      id: id,
      orderId: orderId,
      itemId: itemId,
      item: item,
      itemDescription: itemDescription,
      itemType: itemType,
      quantity: newQuantity,
      unitPrice: newUnitPrice,
      itemDiscountPercentage: newDiscountPct,
      itemDiscountAmount: discountAmount,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      subtotal: subtotalCalc,
      total: totalCalc,
      hsnCode: hsnCode,
      unit: unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'item': itemId,
      'item_description': itemDescription ?? '',
      'item_type': itemType ?? 'SERVICE',
      'quantity': quantity.toInt(),
      'unit': unit?.toUpperCase() ?? 'PIECE',
      'unit_price': unitPrice,
      'item_discount_percentage': itemDiscountPercentage,
      'tax_percentage': taxPercentage,
      if (hsnCode != null) 'hsn_code': hsnCode,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Computed properties
  double get baseAmount => quantity * unitPrice;

  // ✅ USE itemDescription (this is what backend sends!)
  String get itemName => itemDescription ?? item?.name ?? 'Unknown Item';

  // ✅ Alias for compatibility with create order screen
  double get taxPercent => taxPercentage;

  String get formattedUnitPrice => '₹${unitPrice.toStringAsFixed(2)}';
  String get formattedTotal => '₹${total.toStringAsFixed(2)}';
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';

  /// Copy with method for immutable updates
  OrderItem copyWith({
    int? id,
    int? orderId,
    int? itemId,
    Item? item,
    String? itemDescription,
    String? itemType,
    double? quantity,
    double? unitPrice,
    double? itemDiscountPercentage,
    double? itemDiscountAmount,
    double? taxPercentage,
    double? taxAmount,
    double? subtotal,
    double? total,
    String? hsnCode,
    String? unit,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      item: item ?? this.item,
      itemDescription: itemDescription ?? this.itemDescription,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      itemDiscountPercentage:
          itemDiscountPercentage ?? this.itemDiscountPercentage,
      itemDiscountAmount: itemDiscountAmount ?? this.itemDiscountAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
    );
  }
}
