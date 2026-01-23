/// InvoicePayment Model (for payments against invoices)
/// Matches backend financials.Payment
/// Different from ReceiptVoucher (which is for advances)
class InvoicePayment {
  final int? id;
  final String paymentNumber;
  final String paymentDate;
  final int invoice;
  final String? invoiceNumber;
  final double amount;
  final String paymentMode; // CASH, UPI, CARD, BANK_TRANSFER, CHEQUE
  final String? paymentModeDisplay;
  final bool depositedToBank;
  final String? depositDate;
  final String? transactionReference;
  final String? notes;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  InvoicePayment({
    this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.invoice,
    this.invoiceNumber,
    required this.amount,
    required this.paymentMode,
    this.paymentModeDisplay,
    this.depositedToBank = false,
    this.depositDate,
    this.transactionReference,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      id: json['id'],
      paymentNumber: json['payment_number'] ?? '',
      paymentDate: json['payment_date'] ?? '',
      invoice: json['invoice'],
      invoiceNumber: json['invoice_number'],
      amount: _parseDouble(json['amount']),
      paymentMode: json['payment_mode'] ?? 'CASH',
      paymentModeDisplay: json['payment_mode_display'],
      depositedToBank: json['deposited_to_bank'] ?? false,
      depositDate: json['deposit_date'],
      transactionReference: json['transaction_reference'],
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice': invoice,
      'payment_date': paymentDate,
      'amount': amount,
      'payment_mode': paymentMode,
      'deposited_to_bank': depositedToBank,
      if (depositDate != null) 'deposit_date': depositDate,
      if (transactionReference != null && transactionReference!.isNotEmpty)
        'transaction_reference': transactionReference,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
