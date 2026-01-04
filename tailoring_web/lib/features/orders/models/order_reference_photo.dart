class OrderReferencePhoto {
  final int? id;
  final String? photo;
  final String? photoUrl;
  final String? description;
  final int? uploadedBy;
  final String? uploadedByName;
  final DateTime? uploadedAt;

  OrderReferencePhoto({
    this.id,
    this.photo,
    this.photoUrl,
    this.description,
    this.uploadedBy,
    this.uploadedByName,
    this.uploadedAt,
  });

  factory OrderReferencePhoto.fromJson(Map<String, dynamic> json) {
    return OrderReferencePhoto(
      id: json['id'] as int?,
      photo: json['photo'] as String?,
      photoUrl: json['photo_url'] as String?,
      description: json['description'] as String?,
      uploadedBy: json['uploaded_by'] as int?,
      uploadedByName: json['uploaded_by_name'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : null,
    );
  }
}
