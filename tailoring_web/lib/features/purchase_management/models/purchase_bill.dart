class PurchaseBill {
  final int? id;
  final int vendor;
  final String? vendorName;
  final String billNumber;
  final DateTime billDate;
  final DateTime? dueDate;
  final String billAmount;
  final String paidAmount;
  final String balanceAmount;
  final String paymentStatus;
  final String? paymentStatusDisplay;
  final String? description;
  final String? billImageUrl;
  final String? notes;
  final DateTime? createdAt;

  PurchaseBill({
    this.id,
    required this.vendor,
    this.vendorName,
    required this.billNumber,
    required this.billDate,
    this.dueDate,
    required this.billAmount,
    this.paidAmount = '0.00',
    this.balanceAmount = '0.00',
    this.paymentStatus = 'UNPAID',
    this.paymentStatusDisplay,
    this.description,
    this.billImageUrl,
    this.notes,
    this.createdAt,
  });

  factory PurchaseBill.fromJson(Map<String, dynamic> json) {
    return PurchaseBill(
      id: json['id'] as int?,
      vendor: json['vendor'] as int,
      vendorName: json['vendor_name'] as String?,
      billNumber: json['bill_number'] as String,
      billDate: DateTime.parse(json['bill_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      billAmount: json['bill_amount']?.toString() ?? '0.00',
      paidAmount: json['paid_amount']?.toString() ?? '0.00',
      balanceAmount: json['balance_amount']?.toString() ?? '0.00',
      paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
      paymentStatusDisplay: json['payment_status_display'] as String?,
      description: json['description'] as String?,
      billImageUrl: json['bill_image_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vendor': vendor,
      'bill_number': billNumber,
      'bill_date': billDate.toIso8601String().split('T')[0],
      if (dueDate != null)
        'due_date': dueDate!.toIso8601String().split('T')[0],
      'bill_amount': billAmount,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
    };
  }

  PurchaseBill copyWith({
    int? id,
    int? vendor,
    String? vendorName,
    String? billNumber,
    DateTime? billDate,
    DateTime? dueDate,
    String? billAmount,
    String? paidAmount,
    String? balanceAmount,
    String? paymentStatus,
    String? paymentStatusDisplay,
    String? description,
    String? billImageUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return PurchaseBill(
      id: id ?? this.id,
      vendor: vendor ?? this.vendor,
      vendorName: vendorName ?? this.vendorName,
      billNumber: billNumber ?? this.billNumber,
      billDate: billDate ?? this.billDate,
      dueDate: dueDate ?? this.dueDate,
      billAmount: billAmount ?? this.billAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentStatusDisplay: paymentStatusDisplay ?? this.paymentStatusDisplay,
      description: description ?? this.description,
      billImageUrl: billImageUrl ?? this.billImageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get billAmountDouble => double.tryParse(billAmount) ?? 0.0;
  double get paidAmountDouble => double.tryParse(paidAmount) ?? 0.0;
  double get balanceAmountDouble => double.tryParse(balanceAmount) ?? 0.0;

  bool get isUnpaid => paymentStatus == 'UNPAID';
  bool get isPartiallyPaid => paymentStatus == 'PARTIALLY_PAID';
  bool get isFullyPaid => paymentStatus == 'FULLY_PAID';
  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isFullyPaid;
}
