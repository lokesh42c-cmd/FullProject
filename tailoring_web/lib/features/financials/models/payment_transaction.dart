import 'package:intl/intl.dart';

enum PaymentTransactionType { receiptVoucher, invoicePayment, refund }

class PaymentTransaction {
  final int id;
  final String transactionNumber;
  final DateTime transactionDate;
  final PaymentTransactionType transactionType;
  final String customerName;
  final String? orderNumber;
  final String? invoiceNumber;
  final double amount;
  final String paymentMode;
  final String paymentModeDisplay;
  final bool depositedToBank;

  PaymentTransaction({
    required this.id,
    required this.transactionNumber,
    required this.transactionDate,
    required this.transactionType,
    required this.customerName,
    this.orderNumber,
    this.invoiceNumber,
    required this.amount,
    required this.paymentMode,
    required this.paymentModeDisplay,
    required this.depositedToBank,
  });

  String get formattedDate => DateFormat('dd MMM yyyy').format(transactionDate);
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? 0,
      // Check both unified name and specific backend model names
      transactionNumber:
          json['transaction_number'] ?? json['voucher_number'] ?? 'N/A',
      transactionDate: DateTime.parse(
        json['transaction_date'] ??
            json['receipt_date'] ??
            json['date'] ??
            DateTime.now().toIso8601String(),
      ),
      transactionType: _parseType(json['transaction_type']),
      customerName: json['customer_name'] ?? 'Unknown Customer',
      orderNumber: json['order_number']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      amount: double.parse((json['amount'] ?? 0).toString()),
      paymentMode: json['payment_mode'] ?? 'CASH',
      paymentModeDisplay: json['payment_mode_display'] ?? 'Cash',
      depositedToBank: json['deposited_to_bank'] ?? false,
    );
  }

  static PaymentTransactionType _parseType(String? type) {
    if (type == 'INVOICE_PAYMENT') return PaymentTransactionType.invoicePayment;
    if (type == 'REFUND') return PaymentTransactionType.refund;
    return PaymentTransactionType.receiptVoucher;
  }
}

class PaymentTransactionSummary {
  final double totalReceived;
  final double netReceived;
  final double cashInHand;

  PaymentTransactionSummary({
    required this.totalReceived,
    required this.netReceived,
    required this.cashInHand,
  });

  factory PaymentTransactionSummary.calculate(List<PaymentTransaction> txns) {
    double total = 0;
    double refunds = 0;
    double cash = 0;

    for (var t in txns) {
      if (t.transactionType == PaymentTransactionType.refund) {
        refunds += t.amount;
      } else {
        total += t.amount;
        if (t.paymentMode == 'CASH' && !t.depositedToBank) {
          cash += t.amount;
        }
      }
    }
    return PaymentTransactionSummary(
      totalReceived: total,
      netReceived: total - refunds,
      cashInHand: cash,
    );
  }
}
