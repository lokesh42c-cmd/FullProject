import 'item_unit.dart';

/// Item Model
/// Matches: orders.Item from backend
/// Unified catalog for both SERVICE and PRODUCT types with optional inventory tracking
class Item {
  final int? id;
  final String itemType; // SERVICE or PRODUCT
  final String name;
  final String? description;

  // Unit
  final int? unitId;
  final String? unitName; // From API response

  // Stock Control
  final bool trackStock;
  final bool allowNegativeStock;

  // Stock Fields
  final double openingStock;
  final double currentStock;
  final double minStockLevel;

  // Pricing
  final double? purchasePrice;
  final double? sellingPrice;

  // GST
  final String? hsnSacCode;
  final double taxPercent;

  // Barcode
  final String? barcode;

  // Status
  final bool hasBeenUsed;
  final bool isActive;
  final DateTime? deletedAt;

  // Audit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    this.id,
    required this.itemType,
    required this.name,
    this.description,
    this.unitId,
    this.unitName,
    this.trackStock = false,
    this.allowNegativeStock = true,
    this.openingStock = 0.0,
    this.currentStock = 0.0,
    this.minStockLevel = 0.0,
    this.purchasePrice,
    this.sellingPrice,
    this.hsnSacCode,
    this.taxPercent = 0.0,
    this.barcode,
    this.hasBeenUsed = false,
    this.isActive = true,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  // Computed properties
  bool get isLowStock {
    if (!trackStock) return false;
    return currentStock <= minStockLevel;
  }

  double get stockValue {
    if (purchasePrice != null) {
      return currentStock * purchasePrice!;
    }
    return 0.0;
  }

  String get typeDisplay => itemType == 'SERVICE' ? 'Service' : 'Product';

  String get priceWithUnit {
    if (sellingPrice == null) return 'N/A';
    return '₹${sellingPrice!.toStringAsFixed(2)}';
  }

  String get statusText => isActive ? 'Active' : 'Inactive';

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int?,
      itemType: json['item_type'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unitId: json['unit'] as int?,
      unitName: json['unit_name'] as String?,
      trackStock: json['track_stock'] as bool? ?? false,
      allowNegativeStock: json['allow_negative_stock'] as bool? ?? true,
      openingStock: _parseDouble(json['opening_stock']),
      currentStock: _parseDouble(json['current_stock']),
      minStockLevel: _parseDouble(json['min_stock_level']),
      purchasePrice: json['purchase_price'] != null
          ? _parseDouble(json['purchase_price'])
          : null,
      sellingPrice: json['selling_price'] != null
          ? _parseDouble(json['selling_price'])
          : null,
      hsnSacCode: json['hsn_sac_code'] as String?,
      taxPercent: _parseDouble(json['tax_percent']),
      barcode: json['barcode'] as String?,
      hasBeenUsed: json['has_been_used'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Helper method to parse double from string or num
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'item_type': itemType,
      'name': name,
      if (description != null) 'description': description,
      if (unitId != null) 'unit': unitId,
      'track_stock': trackStock,
      'allow_negative_stock': allowNegativeStock,
      'opening_stock': openingStock,
      'current_stock': currentStock,
      'min_stock_level': minStockLevel,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (hsnSacCode != null) 'hsn_sac_code': hsnSacCode,
      'tax_percent': taxPercent,
      if (barcode != null) 'barcode': barcode,
      'has_been_used': hasBeenUsed,
      'is_active': isActive,
    };
  }

  Item copyWith({
    int? id,
    String? itemType,
    String? name,
    String? description,
    int? unitId,
    String? unitName,
    bool? trackStock,
    bool? allowNegativeStock,
    double? openingStock,
    double? currentStock,
    double? minStockLevel,
    double? purchasePrice,
    double? sellingPrice,
    String? hsnSacCode,
    double? taxPercent,
    String? barcode,
    bool? hasBeenUsed,
    bool? isActive,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      description: description ?? this.description,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      trackStock: trackStock ?? this.trackStock,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      taxPercent: taxPercent ?? this.taxPercent,
      barcode: barcode ?? this.barcode,
      hasBeenUsed: hasBeenUsed ?? this.hasBeenUsed,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}