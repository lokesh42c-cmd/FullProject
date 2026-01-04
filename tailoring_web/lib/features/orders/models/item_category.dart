import 'package:json_annotation/json_annotation.dart';

part 'item_category.g.dart';

/// ItemCategory model for services/garment categories
///
/// Used in dropdowns when adding service items
@JsonSerializable()
class ItemCategory {
  final int id;
  final String name;

  @JsonKey(name: 'category_type')
  final String? categoryType; // GARMENT, FABRIC, ACCESSORY

  final String? description;

  @JsonKey(name: 'default_price')
  final double? defaultPrice;

  @JsonKey(name: 'default_hsn_code')
  final String? defaultHsnCode;

  @JsonKey(name: 'gst_percentage')
  final double? gstPercentage;

  @JsonKey(name: 'is_active')
  final bool isActive;

  ItemCategory({
    required this.id,
    required this.name,
    this.categoryType,
    this.description,
    this.defaultPrice,
    this.defaultHsnCode,
    this.gstPercentage,
    this.isActive = true,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) =>
      _$ItemCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ItemCategoryToJson(this);

  /// Display name for dropdown
  String get displayName => name;

  /// Display with price if available
  String get displayWithPrice {
    if (defaultPrice != null) {
      return '$name - ₹${defaultPrice!.toStringAsFixed(0)}';
    }
    return name;
  }

  @override
  String toString() => 'ItemCategory(id: $id, name: $name)';
}

/// Response for category list
@JsonSerializable(explicitToJson: true)
class ItemCategoryListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ItemCategory> results;

  ItemCategoryListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ItemCategoryListResponse.fromJson(Map<String, dynamic> json) =>
      _$ItemCategoryListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ItemCategoryListResponseToJson(this);
}
