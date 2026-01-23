/// Receipt Voucher Model
/// Matches backend financials.ReceiptVoucher
class ReceiptVoucher {
  final int? id;
  final String voucherNumber;
  final DateTime receiptDate;
  final int customer;
  final String? customerName;
  final String? customerPhone;
  final int? order;
  final String? orderNumber;
  final double advanceAmount;
  final double gstRate;
  final String taxType; // CGST_SGST, IGST
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;
  final String paymentMode; // CASH, UPI, CARD, BANK_TRANSFER
  final String? paymentModeDisplay;
  final String? transactionReference;
  final bool depositedToBank;
  final DateTime? depositDate;
  final bool isAdjusted;
  final double adjustedAmount;
  final double remainingAmount;
  final String? notes;
  final bool isIssued;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReceiptVoucher({
    this.id,
    required this.voucherNumber,
    required this.receiptDate,
    required this.customer,
    this.customerName,
    this.customerPhone,
    this.order,
    this.orderNumber,
    required this.advanceAmount,
    this.gstRate = 0.0,
    this.taxType = 'CGST_SGST',
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    required this.totalAmount,
    required this.paymentMode,
    this.paymentModeDisplay,
    this.transactionReference,
    this.depositedToBank = false,
    this.depositDate,
    this.isAdjusted = false,
    this.adjustedAmount = 0.0,
    this.remainingAmount = 0.0,
    this.notes,
    this.isIssued = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ReceiptVoucher.fromJson(Map<String, dynamic> json) {
    return ReceiptVoucher(
      id: json['id'] as int?,
      voucherNumber: json['voucher_number'] as String,
      receiptDate: DateTime.parse(json['receipt_date'] as String),
      customer: json['customer'] as int,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      order: json['order'] as int?,
      orderNumber: json['order_number'] as String?,
      advanceAmount: (json['advance_amount'] as num).toDouble(),
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0.0,
      taxType: json['tax_type'] as String? ?? 'CGST_SGST',
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMode: json['payment_mode'] as String,
      paymentModeDisplay: json['payment_mode_display'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      depositedToBank: json['deposited_to_bank'] as bool? ?? false,
      depositDate: json['deposit_date'] != null
          ? DateTime.parse(json['deposit_date'] as String)
          : null,
      isAdjusted: json['is_adjusted'] as bool? ?? false,
      adjustedAmount: (json['adjusted_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      isIssued: json['is_issued'] as bool? ?? false,
      createdBy: json['created_by'] as int?,
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
      'customer': customer,
      if (order != null) 'order': order,
      'receipt_date': receiptDate.toIso8601String().split('T')[0],
      'advance_amount': advanceAmount,
      'gst_rate': gstRate,
      'payment_mode': paymentMode,
      if (transactionReference != null && transactionReference!.isNotEmpty)
        'transaction_reference': transactionReference,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  String get formattedReceiptDate {
    return '${receiptDate.day.toString().padLeft(2, '0')}-${receiptDate.month.toString().padLeft(2, '0')}-${receiptDate.year}';
  }

  String get formattedTotalAmount {
    return '₹${totalAmount.toStringAsFixed(2)}';
  }
}
