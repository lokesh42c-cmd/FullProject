import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

/// Customer model matching Django backend CustomerDetailSerializer
///
/// Measurements are now directly on the Customer model (no family members)
/// Maps to Django Customer model with all measurement fields
@JsonSerializable(explicitToJson: true)
class Customer {
  final int? id;

  // Basic Info
  final String name;
  final String phone;

  @JsonKey(name: 'whatsapp_number')
  final String? whatsappNumber;

  final String? email;

  final String? gender; // MALE, FEMALE, OTHER

  // Customer Type
  @JsonKey(name: 'customer_type')
  final String customerType; // B2C or B2B

  // Business Fields
  @JsonKey(name: 'business_name')
  final String? businessName;

  final String? gstin;
  final String? pan;

  // Address
  @JsonKey(name: 'address_line1')
  final String? addressLine1;

  @JsonKey(name: 'address_line2')
  final String? addressLine2;

  final String? city;
  final String? state;
  final String? country;
  final String? pincode;

  // ==================== MEASUREMENTS ====================
  // Basic & Common Measurements
  final double? height;
  final double? weight;

  @JsonKey(name: 'shoulder_width')
  final double? shoulderWidth;

  @JsonKey(name: 'bust_chest')
  final double? bustChest;

  final double? waist;
  final double? hip;
  final double? shoulder;

  @JsonKey(name: 'sleeve_length')
  final double? sleeveLength;

  final double? armhole;

  @JsonKey(name: 'garment_length')
  final double? garmentLength;

  // Women-Specific Measurements
  @JsonKey(name: 'front_neck_depth')
  final double? frontNeckDepth;

  @JsonKey(name: 'back_neck_depth')
  final double? backNeckDepth;

  @JsonKey(name: 'upper_chest')
  final double? upperChest;

  @JsonKey(name: 'under_bust')
  final double? underBust;

  @JsonKey(name: 'shoulder_to_apex')
  final double? shoulderToApex;

  @JsonKey(name: 'bust_point_distance')
  final double? bustPointDistance;

  @JsonKey(name: 'front_cross')
  final double? frontCross;

  @JsonKey(name: 'back_cross')
  final double? backCross;

  @JsonKey(name: 'lehenga_length')
  final double? lehengaLength;

  @JsonKey(name: 'pant_waist')
  final double? pantWaist;

  @JsonKey(name: 'ankle_opening')
  final double? ankleOpening;

  // Men-Specific Measurements
  @JsonKey(name: 'neck_round')
  final double? neckRound;

  @JsonKey(name: 'stomach_round')
  final double? stomachRound;

  @JsonKey(name: 'yoke_width')
  final double? yokeWidth;

  @JsonKey(name: 'front_width')
  final double? frontWidth;

  @JsonKey(name: 'back_width')
  final double? backWidth;

  @JsonKey(name: 'trouser_waist')
  final double? trouserWaist;

  @JsonKey(name: 'front_rise')
  final double? frontRise;

  @JsonKey(name: 'back_rise')
  final double? backRise;

  @JsonKey(name: 'bottom_opening')
  final double? bottomOpening;

  // Sleeves & Legs Measurements
  @JsonKey(name: 'upper_arm_bicep')
  final double? upperArmBicep;

  @JsonKey(name: 'sleeve_loose')
  final double? sleeveLoose;

  @JsonKey(name: 'wrist_round')
  final double? wristRound;

  final double? thigh;
  final double? knee;
  final double? ankle;
  final double? rise;
  final double? inseam;
  final double? outseam;

  // Custom Fields
  @JsonKey(name: 'custom_field_1')
  final double? customField1;

  @JsonKey(name: 'custom_field_2')
  final double? customField2;

  @JsonKey(name: 'custom_field_3')
  final double? customField3;

  @JsonKey(name: 'custom_field_4')
  final double? customField4;

  @JsonKey(name: 'custom_field_5')
  final double? customField5;

  @JsonKey(name: 'custom_field_6')
  final double? customField6;

  @JsonKey(name: 'custom_field_7')
  final double? customField7;

  @JsonKey(name: 'custom_field_8')
  final double? customField8;

  @JsonKey(name: 'custom_field_9')
  final double? customField9;

  @JsonKey(name: 'custom_field_10')
  final double? customField10;

  @JsonKey(name: 'measurement_notes')
  final String? measurementNotes;

  // ==================== END MEASUREMENTS ====================

  final String? notes;

  @JsonKey(name: 'is_active')
  final bool isActive;

  // Read-only fields
  @JsonKey(name: 'total_orders')
  final int? totalOrders;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.whatsappNumber,
    this.email,
    this.gender,
    required this.customerType,
    this.businessName,
    this.gstin,
    this.pan,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.pincode,
    // Measurements
    this.height,
    this.weight,
    this.shoulderWidth,
    this.bustChest,
    this.waist,
    this.hip,
    this.shoulder,
    this.sleeveLength,
    this.armhole,
    this.garmentLength,
    this.frontNeckDepth,
    this.backNeckDepth,
    this.upperChest,
    this.underBust,
    this.shoulderToApex,
    this.bustPointDistance,
    this.frontCross,
    this.backCross,
    this.lehengaLength,
    this.pantWaist,
    this.ankleOpening,
    this.neckRound,
    this.stomachRound,
    this.yokeWidth,
    this.frontWidth,
    this.backWidth,
    this.trouserWaist,
    this.frontRise,
    this.backRise,
    this.bottomOpening,
    this.upperArmBicep,
    this.sleeveLoose,
    this.wristRound,
    this.thigh,
    this.knee,
    this.ankle,
    this.rise,
    this.inseam,
    this.outseam,
    this.customField1,
    this.customField2,
    this.customField3,
    this.customField4,
    this.customField5,
    this.customField6,
    this.customField7,
    this.customField8,
    this.customField9,
    this.customField10,
    this.measurementNotes,
    this.notes,
    this.isActive = true,
    this.totalOrders,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Customer from JSON (API response)
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  /// Convert Customer to JSON (API request)
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  /// Copy with method for immutable updates
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? whatsappNumber,
    String? email,
    String? gender,
    String? customerType,
    String? businessName,
    String? gstin,
    String? pan,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? pincode,
    double? height,
    double? weight,
    double? shoulderWidth,
    double? bustChest,
    double? waist,
    double? hip,
    double? shoulder,
    double? sleeveLength,
    double? armhole,
    double? garmentLength,
    double? frontNeckDepth,
    double? backNeckDepth,
    double? upperChest,
    double? underBust,
    double? shoulderToApex,
    double? bustPointDistance,
    double? frontCross,
    double? backCross,
    double? lehengaLength,
    double? pantWaist,
    double? ankleOpening,
    double? neckRound,
    double? stomachRound,
    double? yokeWidth,
    double? frontWidth,
    double? backWidth,
    double? trouserWaist,
    double? frontRise,
    double? backRise,
    double? bottomOpening,
    double? upperArmBicep,
    double? sleeveLoose,
    double? wristRound,
    double? thigh,
    double? knee,
    double? ankle,
    double? rise,
    double? inseam,
    double? outseam,
    double? customField1,
    double? customField2,
    double? customField3,
    double? customField4,
    double? customField5,
    double? customField6,
    double? customField7,
    double? customField8,
    double? customField9,
    double? customField10,
    String? measurementNotes,
    String? notes,
    bool? isActive,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      customerType: customerType ?? this.customerType,
      businessName: businessName ?? this.businessName,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      bustChest: bustChest ?? this.bustChest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      shoulder: shoulder ?? this.shoulder,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      armhole: armhole ?? this.armhole,
      garmentLength: garmentLength ?? this.garmentLength,
      frontNeckDepth: frontNeckDepth ?? this.frontNeckDepth,
      backNeckDepth: backNeckDepth ?? this.backNeckDepth,
      upperChest: upperChest ?? this.upperChest,
      underBust: underBust ?? this.underBust,
      shoulderToApex: shoulderToApex ?? this.shoulderToApex,
      bustPointDistance: bustPointDistance ?? this.bustPointDistance,
      frontCross: frontCross ?? this.frontCross,
      backCross: backCross ?? this.backCross,
      lehengaLength: lehengaLength ?? this.lehengaLength,
      pantWaist: pantWaist ?? this.pantWaist,
      ankleOpening: ankleOpening ?? this.ankleOpening,
      neckRound: neckRound ?? this.neckRound,
      stomachRound: stomachRound ?? this.stomachRound,
      yokeWidth: yokeWidth ?? this.yokeWidth,
      frontWidth: frontWidth ?? this.frontWidth,
      backWidth: backWidth ?? this.backWidth,
      trouserWaist: trouserWaist ?? this.trouserWaist,
      frontRise: frontRise ?? this.frontRise,
      backRise: backRise ?? this.backRise,
      bottomOpening: bottomOpening ?? this.bottomOpening,
      upperArmBicep: upperArmBicep ?? this.upperArmBicep,
      sleeveLoose: sleeveLoose ?? this.sleeveLoose,
      wristRound: wristRound ?? this.wristRound,
      thigh: thigh ?? this.thigh,
      knee: knee ?? this.knee,
      ankle: ankle ?? this.ankle,
      rise: rise ?? this.rise,
      inseam: inseam ?? this.inseam,
      outseam: outseam ?? this.outseam,
      customField1: customField1 ?? this.customField1,
      customField2: customField2 ?? this.customField2,
      customField3: customField3 ?? this.customField3,
      customField4: customField4 ?? this.customField4,
      customField5: customField5 ?? this.customField5,
      customField6: customField6 ?? this.customField6,
      customField7: customField7 ?? this.customField7,
      customField8: customField8 ?? this.customField8,
      customField9: customField9 ?? this.customField9,
      customField10: customField10 ?? this.customField10,
      measurementNotes: measurementNotes ?? this.measurementNotes,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if customer is a business
  bool get isBusiness => customerType == 'B2B';

  /// Check if customer is an individual
  bool get isIndividual => customerType == 'B2C';

  /// Check if customer has measurements
  bool get hasMeasurements {
    return height != null ||
        weight != null ||
        shoulderWidth != null ||
        bustChest != null ||
        waist != null ||
        hip != null ||
        shoulder != null ||
        sleeveLength != null ||
        armhole != null ||
        garmentLength != null ||
        frontNeckDepth != null ||
        backNeckDepth != null ||
        upperChest != null ||
        underBust != null ||
        shoulderToApex != null ||
        bustPointDistance != null ||
        frontCross != null ||
        backCross != null ||
        lehengaLength != null ||
        pantWaist != null ||
        ankleOpening != null ||
        neckRound != null ||
        stomachRound != null ||
        yokeWidth != null ||
        frontWidth != null ||
        backWidth != null ||
        trouserWaist != null ||
        frontRise != null ||
        backRise != null ||
        bottomOpening != null ||
        upperArmBicep != null ||
        sleeveLoose != null ||
        wristRound != null ||
        thigh != null ||
        knee != null ||
        ankle != null ||
        rise != null ||
        inseam != null ||
        outseam != null ||
        customField1 != null ||
        customField2 != null ||
        customField3 != null ||
        customField4 != null ||
        customField5 != null ||
        customField6 != null ||
        customField7 != null ||
        customField8 != null ||
        customField9 != null ||
        customField10 != null;
  }

  /// Get full address as single string
  String get fullAddress {
    final parts = <String>[];
    if (addressLine1?.isNotEmpty ?? false) parts.add(addressLine1!);
    if (addressLine2?.isNotEmpty ?? false) parts.add(addressLine2!);
    if (city?.isNotEmpty ?? false) parts.add(city!);
    if (state?.isNotEmpty ?? false) parts.add(state!);
    if (pincode?.isNotEmpty ?? false) parts.add(pincode!);
    return parts.join(', ');
  }

  /// Create empty customer for form initialization
  factory Customer.empty() {
    return Customer(
      customerType: 'B2C',
      name: '',
      phone: '',
      country: 'India',
      isActive: true,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, type: $customerType)';
  }
}

/// Paginated response for customer list
@JsonSerializable(explicitToJson: true)
class CustomerListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Customer> results;

  CustomerListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerListResponseToJson(this);
}
