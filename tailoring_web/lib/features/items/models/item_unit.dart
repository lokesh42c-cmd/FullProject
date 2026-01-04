/// Item Unit Model
///
/// Represents measurement units for items (Meter, Piece, Kilogram, etc.)
/// Used by Item model to specify pricing unit
class ItemUnit {
  final int? id;
  final String name;
  final String code;
  final bool isActive;
  final DateTime createdAt;

  ItemUnit({
    this.id,
    required this.name,
    required this.code,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from JSON
  factory ItemUnit.fromJson(Map<String, dynamic> json) {
    return ItemUnit(
      id: json['id'] as int?,
      name: json['name'] as String,
      code:
          json['code'] as String? ?? json['name'] as String, // Fallback to name
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'code': code,
      'is_active': isActive,
    };
  }

  /// Display format
  String get displayName => '$name ($code)';

  /// Copy with
  ItemUnit copyWith({
    int? id,
    String? name,
    String? code,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ItemUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Response for list of units
class ItemUnitListResponse {
  final int count;
  final List<ItemUnit> units;

  ItemUnitListResponse({required this.count, required this.units});

  factory ItemUnitListResponse.fromJson(Map<String, dynamic> json) {
    return ItemUnitListResponse(
      count: json['count'] as int,
      units: (json['results'] as List)
          .map((unit) => ItemUnit.fromJson(unit))
          .toList(),
    );
  }
}
