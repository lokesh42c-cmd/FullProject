import 'package:json_annotation/json_annotation.dart';

part 'inventory_item.g.dart';

/// InventoryItem model for products and fabrics
///
/// Used in dropdowns when adding product items
@JsonSerializable()
class InventoryItem {
  final int id;

  final String sku;

  @JsonKey(name: 'item_type')
  final String itemType; // FABRIC, PRODUCT, MATERIAL

  final String name;
  final String? description;

  // Stock
  @JsonKey(name: 'current_stock')
  final double currentStock;

  final String unit; // METER, PIECE, KG, GRAM, YARD, SET

  // Pricing
  @JsonKey(name: 'cost_price')
  final double? costPrice;

  @JsonKey(name: 'selling_price')
  final double sellingPrice;

  // Category (optional link)
  final int? category;

  @JsonKey(name: 'category_name')
  final String? categoryName;

  // HSN code for GST
  @JsonKey(name: 'hsn_code')
  final String? hsnCode;

  @JsonKey(name: 'gst_percentage')
  final double? gstPercentage;

  // Stock status
  @JsonKey(name: 'is_low_stock')
  final bool isLowStock;

  @JsonKey(name: 'is_active')
  final bool isActive;

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  InventoryItem({
    required this.id,
    required this.sku,
    required this.itemType,
    required this.name,
    this.description,
    required this.currentStock,
    required this.unit,
    this.costPrice,
    required this.sellingPrice,
    this.category,
    this.categoryName,
    this.hsnCode,
    this.gstPercentage,
    this.isLowStock = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);

  /// Display name for dropdown
  String get displayName => name;

  /// Display with price and stock
  String get displayWithDetails {
    return '$name - ₹${sellingPrice.toStringAsFixed(0)}/$unit (Stock: ${currentStock.toStringAsFixed(0)}$unit)';
  }

  /// Display unit text
  String get unitDisplay {
    switch (unit) {
      case 'METER':
        return 'm';
      case 'PIECE':
        return 'pc';
      case 'KG':
        return 'kg';
      case 'GRAM':
        return 'g';
      case 'YARD':
        return 'yd';
      case 'SET':
        return 'set';
      default:
        return unit.toLowerCase();
    }
  }

  /// Check if item has sufficient stock
  bool hasStock(double quantity) => currentStock >= quantity;

  /// Get stock status text
  String get stockStatus {
    if (currentStock <= 0) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  @override
  String toString() =>
      'InventoryItem(id: $id, name: $name, stock: $currentStock$unit)';
}

/// Response for inventory list
@JsonSerializable(explicitToJson: true)
class InventoryItemListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<InventoryItem> results;

  InventoryItemListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory InventoryItemListResponse.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemListResponseToJson(this);
}
