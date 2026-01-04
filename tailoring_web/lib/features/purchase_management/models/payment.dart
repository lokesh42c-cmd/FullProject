class Payment {
  final int? id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String paymentType;
  final String amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final int? purchaseBill;
  final int? expense;
  final String? vendorName;
  final String? purchaseBillNumber;
  final String? expenseDescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payment({
    this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.paymentType,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    this.purchaseBill,
    this.expense,
    this.vendorName,
    this.purchaseBillNumber,
    this.expenseDescription,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int?,
      paymentNumber: json['payment_number'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      paymentType: json['payment_type'] as String,
      amount: json['amount']?.toString() ?? '0.00',
      paymentMethod: json['payment_method'] as String,
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
      purchaseBill: json['purchase_bill'] as int?,
      expense: json['expense'] as int?,
      vendorName: json['vendor_name'] as String?,
      purchaseBillNumber: json['purchase_bill_number'] as String?,
      expenseDescription: json['expense_description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'payment_number': paymentNumber,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_type': paymentType,
      'amount': amount,
      'payment_method': paymentMethod,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
      if (purchaseBill != null) 'purchase_bill': purchaseBill,
      if (expense != null) 'expense': expense,
    };
  }

  // Helpers
  double get amountDouble => double.tryParse(amount) ?? 0.0;

  bool get isBillPayment => purchaseBill != null;

  bool get isExpensePayment => expense != null;

  String get typeDisplay {
    if (isBillPayment) return 'Bill Payment';
    if (isExpensePayment) return 'Expense Payment';
    return 'Payment';
  }

  String get displayReference {
    if (purchaseBillNumber != null) return purchaseBillNumber!;
    if (expenseDescription != null) return expenseDescription!;
    return referenceNumber ?? '-';
  }
}
