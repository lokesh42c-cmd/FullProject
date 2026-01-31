/// Unified Payment Transaction Model
/// Location: lib/features/financials/models/payment_transaction.dart
///
/// Combines ReceiptVoucher, Payment, and RefundVoucher into single model
/// for "All Payments Received" screen

class PaymentTransaction {
  final int id;
  final String transactionNumber;
  final DateTime transactionDate;
  final PaymentTransactionType transactionType;
  final String customerName;
  final String? customerPhone;
  final String? orderNumber;
  final String? invoiceNumber;
  final double amount;
  final String paymentMode;
  final String paymentModeDisplay;
  final String? transactionReference;
  final bool depositedToBank;
  final DateTime? depositDate;
  final String? depositBankName;
  final String? notes;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.transactionNumber,
    required this.transactionDate,
    required this.transactionType,
    required this.customerName,
    this.customerPhone,
    this.orderNumber,
    this.invoiceNumber,
    required this.amount,
    required this.paymentMode,
    required this.paymentModeDisplay,
    this.transactionReference,
    required this.depositedToBank,
    this.depositDate,
    this.depositBankName,
    this.notes,
    required this.createdAt,
  });

  /// Factory: Create from ReceiptVoucher JSON
  factory PaymentTransaction.fromReceiptVoucher(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int,
      transactionNumber: json['voucher_number'] as String,
      transactionDate: DateTime.parse(json['receipt_date'] as String),
      transactionType: PaymentTransactionType.receiptVoucher,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      orderNumber: json['order_number'] as String?,
      invoiceNumber: null, // Receipt vouchers don't have invoices
      amount: double.parse(json['total_amount'].toString()),
      paymentMode: json['payment_mode'] as String,
      paymentModeDisplay: json['payment_mode_display'] as String,
      transactionReference: json['transaction_reference'] as String?,
      depositedToBank: json['deposited_to_bank'] as bool? ?? false,
      depositDate: json['deposit_date'] != null
          ? DateTime.parse(json['deposit_date'] as String)
          : null,
      depositBankName: null, // Not available in receipt voucher
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Factory: Create from Invoice Payment JSON
  factory PaymentTransaction.fromInvoicePayment(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int,
      transactionNumber: json['payment_number'] as String,
      transactionDate: DateTime.parse(json['payment_date'] as String),
      transactionType: PaymentTransactionType.invoicePayment,
      customerName: json['customer_name'] as String,
      customerPhone: null, // Not available in payment serializer
      orderNumber: null, // Payments are linked to invoice, not order directly
      invoiceNumber: json['invoice_number'] as String?,
      amount: double.parse(json['amount'].toString()),
      paymentMode: json['payment_mode'] as String,
      paymentModeDisplay: json['payment_mode_display'] as String,
      transactionReference: json['transaction_reference'] as String?,
      depositedToBank: json['deposited_to_bank'] as bool? ?? false,
      depositDate: json['deposit_date'] != null
          ? DateTime.parse(json['deposit_date'] as String)
          : null,
      depositBankName: null, // Not available in payment serializer
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Factory: Create from RefundVoucher JSON
  factory PaymentTransaction.fromRefundVoucher(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int,
      transactionNumber: json['refund_number'] as String,
      transactionDate: DateTime.parse(json['refund_date'] as String),
      transactionType: PaymentTransactionType.refund,
      customerName: json['customer_name'] as String,
      customerPhone: null,
      orderNumber: null,
      invoiceNumber: null,
      amount: double.parse(json['total_refund'].toString()),
      paymentMode: json['refund_mode'] as String,
      paymentModeDisplay: json['refund_mode_display'] as String,
      transactionReference: json['transaction_reference'] as String?,
      depositedToBank: false, // Refunds are outgoing, not deposited
      depositDate: null,
      depositBankName: null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Helper getters
  String get formattedAmount {
    final sign = transactionType == PaymentTransactionType.refund ? '-' : '+';
    return '$sign₹${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    return '${transactionDate.day.toString().padLeft(2, '0')}/'
        '${transactionDate.month.toString().padLeft(2, '0')}/'
        '${transactionDate.year}';
  }

  String get transactionTypeDisplay {
    switch (transactionType) {
      case PaymentTransactionType.receiptVoucher:
        return 'Receipt Voucher';
      case PaymentTransactionType.invoicePayment:
        return 'Invoice Payment';
      case PaymentTransactionType.refund:
        return 'Refund';
    }
  }

  String get transactionTypeShort {
    switch (transactionType) {
      case PaymentTransactionType.receiptVoucher:
        return 'RV';
      case PaymentTransactionType.invoicePayment:
        return 'IP';
      case PaymentTransactionType.refund:
        return 'RF';
    }
  }

  // Payment method icon
  String get methodIcon {
    switch (paymentMode) {
      case 'CASH':
        return '💵';
      case 'UPI':
        return '📱';
      case 'CARD':
        return '💳';
      case 'BANK_TRANSFER':
        return '🏦';
      case 'CHEQUE':
        return '📝';
      default:
        return '💰';
    }
  }

  String get depositStatus {
    if (transactionType == PaymentTransactionType.refund) {
      return 'N/A';
    }
    if (paymentMode != 'CASH') {
      return 'N/A';
    }
    return depositedToBank ? 'Deposited' : 'Cash in Hand';
  }
}

/// Payment Transaction Type Enum
enum PaymentTransactionType { receiptVoucher, invoicePayment, refund }

/// Payment Summary for All Payments Screen
class PaymentTransactionSummary {
  final double totalReceived;
  final double totalRefunded;
  final double netReceived;
  final double cashInHand;
  final double cashDeposited;
  final int receiptVoucherCount;
  final int invoicePaymentCount;
  final int refundCount;

  PaymentTransactionSummary({
    required this.totalReceived,
    required this.totalRefunded,
    required this.netReceived,
    required this.cashInHand,
    required this.cashDeposited,
    required this.receiptVoucherCount,
    required this.invoicePaymentCount,
    required this.refundCount,
  });

  factory PaymentTransactionSummary.calculate(
    List<PaymentTransaction> transactions,
  ) {
    double totalReceived = 0;
    double totalRefunded = 0;
    double cashInHand = 0;
    double cashDeposited = 0;
    int receiptVoucherCount = 0;
    int invoicePaymentCount = 0;
    int refundCount = 0;

    for (var txn in transactions) {
      switch (txn.transactionType) {
        case PaymentTransactionType.receiptVoucher:
          totalReceived += txn.amount;
          receiptVoucherCount++;
          if (txn.paymentMode == 'CASH') {
            if (txn.depositedToBank) {
              cashDeposited += txn.amount;
            } else {
              cashInHand += txn.amount;
            }
          }
          break;

        case PaymentTransactionType.invoicePayment:
          totalReceived += txn.amount;
          invoicePaymentCount++;
          if (txn.paymentMode == 'CASH') {
            if (txn.depositedToBank) {
              cashDeposited += txn.amount;
            } else {
              cashInHand += txn.amount;
            }
          }
          break;

        case PaymentTransactionType.refund:
          totalRefunded += txn.amount;
          refundCount++;
          break;
      }
    }

    return PaymentTransactionSummary(
      totalReceived: totalReceived,
      totalRefunded: totalRefunded,
      netReceived: totalReceived - totalRefunded,
      cashInHand: cashInHand,
      cashDeposited: cashDeposited,
      receiptVoucherCount: receiptVoucherCount,
      invoicePaymentCount: invoicePaymentCount,
      refundCount: refundCount,
    );
  }
}
