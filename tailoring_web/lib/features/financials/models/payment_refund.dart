// lib/features/financials/models/payment_refund.dart

class PaymentRefund {
  final int? id;
  final String refundNumber;
  final String refundDate;
  final int payment;
  final String? paymentNumber;
  final int invoice;
  final String? invoiceNumber;
  final int customer;
  final String? customerName;
  final double refundAmount;
  final String refundMode;
  final String? refundModeDisplay;
  final String? transactionReference;
  final String reason;
  final String? notes;
  final int? createdBy;
  final String? createdByName;
  final String? createdAt;
  final String? updatedAt;

  PaymentRefund({
    this.id,
    required this.refundNumber,
    required this.refundDate,
    required this.payment,
    this.paymentNumber,
    required this.invoice,
    this.invoiceNumber,
    required this.customer,
    this.customerName,
    required this.refundAmount,
    required this.refundMode,
    this.refundModeDisplay,
    this.transactionReference,
    required this.reason,
    this.notes,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentRefund.fromJson(Map<String, dynamic> json) {
    return PaymentRefund(
      id: json['id'],
      refundNumber: json['refund_number'] ?? '',
      refundDate: json['refund_date'] ?? '',
      payment: json['payment'],
      paymentNumber: json['payment_number'],
      invoice: json['invoice'],
      invoiceNumber: json['invoice_number'],
      customer: json['customer'],
      customerName: json['customer_name'],
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0.0,
      refundMode: json['refund_mode'] ?? '',
      refundModeDisplay: json['refund_mode_display'],
      transactionReference: json['transaction_reference'],
      reason: json['reason'] ?? '',
      notes: json['notes'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'refund_date': refundDate,
      'payment': payment,
      'refund_amount': refundAmount,
      'refund_mode': refundMode,
      if (transactionReference != null)
        'transaction_reference': transactionReference,
      'reason': reason,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  PaymentRefund copyWith({
    int? id,
    String? refundNumber,
    String? refundDate,
    int? payment,
    String? paymentNumber,
    int? invoice,
    String? invoiceNumber,
    int? customer,
    String? customerName,
    double? refundAmount,
    String? refundMode,
    String? refundModeDisplay,
    String? transactionReference,
    String? reason,
    String? notes,
    int? createdBy,
    String? createdByName,
    String? createdAt,
    String? updatedAt,
  }) {
    return PaymentRefund(
      id: id ?? this.id,
      refundNumber: refundNumber ?? this.refundNumber,
      refundDate: refundDate ?? this.refundDate,
      payment: payment ?? this.payment,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      invoice: invoice ?? this.invoice,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customer: customer ?? this.customer,
      customerName: customerName ?? this.customerName,
      refundAmount: refundAmount ?? this.refundAmount,
      refundMode: refundMode ?? this.refundMode,
      refundModeDisplay: refundModeDisplay ?? this.refundModeDisplay,
      transactionReference: transactionReference ?? this.transactionReference,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PaymentRefund(id: $id, refundNumber: $refundNumber, amount: ₹$refundAmount)';
  }
}
