import 'purchase_bill.dart';

class Vendor {
  final int? id;
  final String name;
  final String? businessName;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstin;
  final String? pan;
  final int? paymentTermsDays;
  final String totalPurchases;
  final String totalPaid;
  final String outstandingBalance;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<PurchaseBill>? recentBills;
  final int? totalBills;
  final bool? hasOutstanding;

  Vendor({
    this.id,
    required this.name,
    this.businessName,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    this.gstin,
    this.pan,
    this.paymentTermsDays,
    this.totalPurchases = '0.00',
    this.totalPaid = '0.00',
    this.outstandingBalance = '0.00',
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.recentBills,
    this.totalBills,
    this.hasOutstanding,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as int?,
      name: json['name'] as String,
      businessName: json['business_name'] as String?,
      phone: json['phone'] as String,
      alternatePhone: json['alternate_phone'] as String?,
      email: json['email'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      paymentTermsDays: json['payment_terms_days'] as int?,
      totalPurchases: json['total_purchases']?.toString() ?? '0.00',
      totalPaid: json['total_paid']?.toString() ?? '0.00',
      outstandingBalance: json['outstanding_balance']?.toString() ?? '0.00',
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      recentBills: json['recent_bills'] != null
          ? (json['recent_bills'] as List)
                .map((bill) => PurchaseBill.fromJson(bill))
                .toList()
          : null,
      totalBills: json['total_bills'] as int?,
      hasOutstanding: json['has_outstanding'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (businessName != null) 'business_name': businessName,
      'phone': phone,
      if (alternatePhone != null) 'alternate_phone': alternatePhone,
      if (email != null) 'email': email,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (gstin != null) 'gstin': gstin,
      if (pan != null) 'pan': pan,
      if (paymentTermsDays != null) 'payment_terms_days': paymentTermsDays,
      if (notes != null) 'notes': notes,
    };
  }

  String get displayName => businessName ?? name;

  bool get hasBalance =>
      double.tryParse(outstandingBalance) != null &&
      double.parse(outstandingBalance) > 0;
}
