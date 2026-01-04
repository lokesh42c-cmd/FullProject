import 'item_unit.dart';

/// Item Model
///
/// Represents items (services and products) used in daily operations
/// This is different from full Inventory - just quick items for orders
class Item {
  final int? id;
  final String itemType; // 'PRODUCT' or 'SERVICE'
  final String name;
  final String? description;
  final ItemUnit? unit;
  final int? unitId; // For creating/updating
  final String? hsnSacCode;
  final double price;
  final double taxPercent;
  final bool isActive;
  final DateTime createdAt;

  Item({
    this.id,
    required this.itemType,
    required this.name,
    this.description,
    this.unit,
    this.unitId,
    this.hsnSacCode,
    required this.price,
    this.taxPercent = 0.0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int?,
      itemType: json['item_type'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] != null ? ItemUnit.fromJson(json['unit']) : null,
      unitId: json['unit_id'] as int?,
      hsnSacCode: json['hsn_sac_code'] as String?,
      price: _parseDouble(json['price']),
      taxPercent: _parseDouble(json['tax_percent'] ?? 0),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Helper to parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'item_type': itemType,
      'name': name,
      'description': description ?? '', // ← Empty string instead of null
      'unit': unitId,
      'hsn_sac_code': hsnSacCode ?? '', // ← Same for HSN/SAC
      'price': price,
      'tax_percent': taxPercent,
      'is_active': isActive,
    };
  }

  /// Helper getters
  String get typeDisplay {
    return itemType == 'SERVICE' ? 'Service' : 'Product';
  }

  String get priceDisplay {
    return '₹${price.toStringAsFixed(2)}';
  }

  // Alias for backward compatibility
  String get formattedPrice => priceDisplay;

  String get priceWithUnit {
    if (unit != null) {
      return '₹${price.toStringAsFixed(2)}/${unit!.code}';
    }
    return priceDisplay;
  }

  String get statusText {
    return isActive ? 'Active' : 'Inactive';
  }

  /// Copy with
  Item copyWith({
    int? id,
    String? itemType,
    String? name,
    String? description,
    ItemUnit? unit,
    int? unitId,
    String? hsnSacCode,
    double? price,
    double? taxPercent,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      unitId: unitId ?? this.unitId,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      price: price ?? this.price,
      taxPercent: taxPercent ?? this.taxPercent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Response for list of items
class ItemListResponse {
  final int count;
  final List<Item> items;

  ItemListResponse({required this.count, required this.items});

  factory ItemListResponse.fromJson(Map<String, dynamic> json) {
    return ItemListResponse(
      count: json['count'] as int,
      items: (json['results'] as List)
          .map((item) => Item.fromJson(item))
          .toList(),
    );
  }
}

/// Item Types
class ItemType {
  static const String product = 'PRODUCT';
  static const String service = 'SERVICE';

  static List<Map<String, String>> get all => [
    {'value': product, 'label': 'Product'},
    {'value': service, 'label': 'Service'},
  ];
}
