/// Tenant Model
/// Matches backend core.Tenant and TenantSerializer
/// Used for company information in invoices and settings
class Tenant {
  final int id;
  final String name;
  final String slug;
  final String email;
  final String phoneNumber;

  // Address
  final String? address;
  final String city;
  final String state;
  final String? pincode;

  // Business Details (for invoices)
  final String? gstin;
  final String? panNumber;
  final String? logo;

  // Status
  final bool isActive;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tenant({
    required this.id,
    required this.name,
    required this.slug,
    required this.email,
    required this.phoneNumber,
    this.address,
    required this.city,
    required this.state,
    this.pincode,
    this.gstin,
    this.panNumber,
    this.logo,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Tenant from JSON (from API response)
  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      address: json['address'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String?,
      gstin: json['gstin'] as String?,
      panNumber: json['pan_number'] as String?,
      logo: json['logo'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON (for API requests - rarely needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'email': email,
      'phone_number': phoneNumber,
      if (address != null) 'address': address,
      'city': city,
      'state': state,
      if (pincode != null) 'pincode': pincode,
      if (gstin != null) 'gstin': gstin,
      if (panNumber != null) 'pan_number': panNumber,
      if (logo != null) 'logo': logo,
      'is_active': isActive,
    };
  }

  /// Helper: Get formatted address
  String get formattedAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    parts.add(city);
    parts.add(state);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    return parts.join(', ');
  }

  /// Helper: Get single-line address (for invoice header)
  String get singleLineAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    parts.add('$city, $state${pincode != null ? " - $pincode" : ""}');
    return parts.join(', ');
  }

  /// Helper: Has GSTIN (used for tax calculation)
  bool get hasGstin {
    return gstin != null && gstin!.isNotEmpty;
  }

  /// Helper: Display GSTIN or "Not Registered"
  String get gstinDisplay {
    return gstin ?? 'GSTIN: Not Registered';
  }

  /// CopyWith method for updates
  Tenant copyWith({
    int? id,
    String? name,
    String? slug,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? panNumber,
    String? logo,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gstin: gstin ?? this.gstin,
      panNumber: panNumber ?? this.panNumber,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Tenant(id: $id, name: $name, state: $state, gstin: ${gstin ?? "N/A"})';
  }
}
