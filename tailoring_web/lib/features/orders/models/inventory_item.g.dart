// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    InventoryItem(
      id: (json['id'] as num).toInt(),
      sku: json['sku'] as String,
      itemType: json['item_type'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      currentStock: (json['current_stock'] as num).toDouble(),
      unit: json['unit'] as String,
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      category: (json['category'] as num?)?.toInt(),
      categoryName: json['category_name'] as String?,
      hsnCode: json['hsn_code'] as String?,
      gstPercentage: (json['gst_percentage'] as num?)?.toDouble(),
      isLowStock: json['is_low_stock'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InventoryItemToJson(InventoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'item_type': instance.itemType,
      'name': instance.name,
      'description': instance.description,
      'current_stock': instance.currentStock,
      'unit': instance.unit,
      'cost_price': instance.costPrice,
      'selling_price': instance.sellingPrice,
      'category': instance.category,
      'category_name': instance.categoryName,
      'hsn_code': instance.hsnCode,
      'gst_percentage': instance.gstPercentage,
      'is_low_stock': instance.isLowStock,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

InventoryItemListResponse _$InventoryItemListResponseFromJson(
  Map<String, dynamic> json,
) => InventoryItemListResponse(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$InventoryItemListResponseToJson(
  InventoryItemListResponse instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results.map((e) => e.toJson()).toList(),
};
