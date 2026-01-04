// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemCategory _$ItemCategoryFromJson(Map<String, dynamic> json) => ItemCategory(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  categoryType: json['category_type'] as String?,
  description: json['description'] as String?,
  defaultPrice: (json['default_price'] as num?)?.toDouble(),
  defaultHsnCode: json['default_hsn_code'] as String?,
  gstPercentage: (json['gst_percentage'] as num?)?.toDouble(),
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$ItemCategoryToJson(ItemCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category_type': instance.categoryType,
      'description': instance.description,
      'default_price': instance.defaultPrice,
      'default_hsn_code': instance.defaultHsnCode,
      'gst_percentage': instance.gstPercentage,
      'is_active': instance.isActive,
    };

ItemCategoryListResponse _$ItemCategoryListResponseFromJson(
  Map<String, dynamic> json,
) => ItemCategoryListResponse(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => ItemCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ItemCategoryListResponseToJson(
  ItemCategoryListResponse instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results.map((e) => e.toJson()).toList(),
};
