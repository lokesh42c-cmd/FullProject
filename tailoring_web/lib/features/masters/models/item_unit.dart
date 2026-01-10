/// ItemUnit Model (Masters)
/// Matches: masters.ItemUnit from backend
class ItemUnit {
  final int? id;
  final String name;
  final String code;
  final bool isActive;
  final DateTime? createdAt;

  ItemUnit({
    this.id,
    required this.name,
    required this.code,
    this.isActive = true,
    this.createdAt,
  });

  factory ItemUnit.fromJson(Map<String, dynamic> json) {
    return ItemUnit(
      id: json['id'] as int?,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'code': code,
      'is_active': isActive,
    };
  }

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
