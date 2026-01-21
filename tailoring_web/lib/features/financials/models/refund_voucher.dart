import 'package:intl/intl.dart';

/// RefundVoucher Model
/// Matches backend financials.RefundVoucher
class RefundVoucher {
  final int? id;
  final String refundNumber;
  final DateTime refundDate;
  final int receiptVoucher;
  final String? receiptVoucherNumber;
  final int customer;
  final String? customerName;
  final double refundAmount;
  final double gstRate;
  final String taxType; // CGST_SGST, IGST
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalRefund;
  final String refundMode; // CASH, BANK_TRANSFER, UPI
  final String? refundModeDisplay;
  final String? transactionReference;
  final String reason;
  final String? notes;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RefundVoucher({
    this.id,
    required this.refundNumber,
    required this.refundDate,
    required this.receiptVoucher,
    this.receiptVoucherNumber,
    required this.customer,
    this.customerName,
    required this.refundAmount,
    required this.gstRate,
    required this.taxType,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalRefund,
    required this.refundMode,
    this.refundModeDisplay,
    this.transactionReference,
    required this.reason,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RefundVoucher.fromJson(Map<String, dynamic> json) {
    return RefundVoucher(
      id: json['id'] as int?,
      refundNumber: json['refund_number'] as String? ?? '',
      refundDate: json['refund_date'] != null
          ? DateTime.parse(json['refund_date'] as String)
          : DateTime.now(),
      receiptVoucher: json['receipt_voucher'] as int? ?? 0,
      receiptVoucherNumber: json['receipt_voucher_number'] as String?,
      customer: json['customer'] as int? ?? 0,
      customerName: json['customer_name'] as String?,
      refundAmount: (json['refund_amount'] is num)
          ? (json['refund_amount'] as num).toDouble()
          : double.tryParse(json['refund_amount']?.toString() ?? '0') ?? 0.0,
      gstRate: (json['gst_rate'] is num)
          ? (json['gst_rate'] as num).toDouble()
          : double.tryParse(json['gst_rate']?.toString() ?? '0') ?? 0.0,
      taxType: json['tax_type'] as String? ?? 'CGST_SGST',
      cgstAmount: (json['cgst_amount'] is num)
          ? (json['cgst_amount'] as num).toDouble()
          : double.tryParse(json['cgst_amount']?.toString() ?? '0') ?? 0.0,
      sgstAmount: (json['sgst_amount'] is num)
          ? (json['sgst_amount'] as num).toDouble()
          : double.tryParse(json['sgst_amount']?.toString() ?? '0') ?? 0.0,
      igstAmount: (json['igst_amount'] is num)
          ? (json['igst_amount'] as num).toDouble()
          : double.tryParse(json['igst_amount']?.toString() ?? '0') ?? 0.0,
      totalRefund: (json['total_refund'] is num)
          ? (json['total_refund'] as num).toDouble()
          : double.tryParse(json['total_refund']?.toString() ?? '0') ?? 0.0,
      refundMode: json['refund_mode'] as String? ?? 'CASH',
      refundModeDisplay: json['refund_mode_display'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      reason: json['reason'] as String? ?? '',
      notes: json['notes'] as String?,
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
      'refund_number': refundNumber,
      'refund_date': refundDate.toIso8601String().split('T')[0],
      'receipt_voucher': receiptVoucher,
      'customer': customer,
      'refund_amount': refundAmount,
      'gst_rate': gstRate,
      'tax_type': taxType,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'total_refund': totalRefund,
      'refund_mode': refundMode,
      if (transactionReference != null && transactionReference!.isNotEmpty)
        'transaction_reference': transactionReference,
      'reason': reason,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  // Formatted getters for display
  String get formattedRefundDate {
    return DateFormat('dd MMM yyyy').format(refundDate);
  }

  String get formattedTotalRefund {
    return '₹${totalRefund.toStringAsFixed(2)}';
  }

  String get formattedRefundAmount {
    return '₹${refundAmount.toStringAsFixed(2)}';
  }

  RefundVoucher copyWith({
    int? id,
    String? refundNumber,
    DateTime? refundDate,
    int? receiptVoucher,
    String? receiptVoucherNumber,
    int? customer,
    String? customerName,
    double? refundAmount,
    double? gstRate,
    String? taxType,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? totalRefund,
    String? refundMode,
    String? refundModeDisplay,
    String? transactionReference,
    String? reason,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefundVoucher(
      id: id ?? this.id,
      refundNumber: refundNumber ?? this.refundNumber,
      refundDate: refundDate ?? this.refundDate,
      receiptVoucher: receiptVoucher ?? this.receiptVoucher,
      receiptVoucherNumber: receiptVoucherNumber ?? this.receiptVoucherNumber,
      customer: customer ?? this.customer,
      customerName: customerName ?? this.customerName,
      refundAmount: refundAmount ?? this.refundAmount,
      gstRate: gstRate ?? this.gstRate,
      taxType: taxType ?? this.taxType,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      totalRefund: totalRefund ?? this.totalRefund,
      refundMode: refundMode ?? this.refundMode,
      refundModeDisplay: refundModeDisplay ?? this.refundModeDisplay,
      transactionReference: transactionReference ?? this.transactionReference,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
