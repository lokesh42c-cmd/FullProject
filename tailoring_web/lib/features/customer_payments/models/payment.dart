/// Simple Payment Model
/// Location: lib/features/payments/models/payment.dart

class Payment {
  final int id;
  final String paymentNumber;
  final int orderId;
  final String orderNumber;
  final String customerName;
  final String? customerPhone;
  final double amount;
  final String paymentMethod;
  final String paymentMethodDisplay;
  final DateTime paymentDate;
  final String? referenceNumber;
  final String? notes;
  final String? bankName;
  final bool depositedToBank;
  final DateTime? depositDate;
  final String? depositBankName;
  final bool isRefund;
  final int? createdById;
  final String? createdByName;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.paymentNumber,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    this.customerPhone,
    required this.amount,
    required this.paymentMethod,
    required this.paymentMethodDisplay,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    this.bankName,
    required this.depositedToBank,
    this.depositDate,
    this.depositBankName,
    required this.isRefund,
    this.createdById,
    this.createdByName,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      paymentNumber: json['payment_number'] as String,
      orderId: json['order'] as int,
      orderNumber: json['order_number'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'] as String,
      paymentMethodDisplay: json['payment_method_display'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
      bankName: json['bank_name'] as String?,
      depositedToBank: json['deposited_to_bank'] as bool,
      depositDate: json['deposit_date'] != null
          ? DateTime.parse(json['deposit_date'] as String)
          : null, 
      depositBankName: json['deposit_bank_name'] as String?,
      isRefund: json['is_refund'] as bool,
      createdById: json['created_by'] as int?,
      createdByName: json['created_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'reference_number': referenceNumber,
      'notes': notes,
      'bank_name': bankName,
      'deposited_to_bank': depositedToBank,
      'deposit_date': depositDate?.toIso8601String(),
      'deposit_bank_name': depositBankName,
    };
  }

  // Helper getters
  String get formattedAmount {
    final sign = isRefund ? '-' : '';
    return '$sign₹${amount.abs().toStringAsFixed(2)}';
  }

  String get formattedDate {
    return '${paymentDate.day.toString().padLeft(2, '0')}/'
        '${paymentDate.month.toString().padLeft(2, '0')}/'
        '${paymentDate.year}';
  }

  String get formattedDateTime {
    return '$formattedDate ${paymentDate.hour.toString().padLeft(2, '0')}:'
        '${paymentDate.minute.toString().padLeft(2, '0')}';
  }

  // Payment method icon
  String get methodIcon {
    switch (paymentMethod) {
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

  Payment copyWith({
    int? id,
    String? paymentNumber,
    int? orderId,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    double? amount,
    String? paymentMethod,
    String? paymentMethodDisplay,
    DateTime? paymentDate,
    String? referenceNumber,
    String? notes,
    String? bankName,
    bool? depositedToBank,
    DateTime? depositDate,
    String? depositBankName,
    bool? isRefund,
    int? createdById,
    String? createdByName,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodDisplay: paymentMethodDisplay ?? this.paymentMethodDisplay,
      paymentDate: paymentDate ?? this.paymentDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      bankName: bankName ?? this.bankName,
      depositedToBank: depositedToBank ?? this.depositedToBank,
      depositDate: depositDate ?? this.depositDate,
      depositBankName: depositBankName ?? this.depositBankName,
      isRefund: isRefund ?? this.isRefund,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Payment Summary Model (for order detail screen)
class PaymentSummary {
  final double totalAmount;
  final double totalPaid;
  final double totalRefunded;
  final double balance;
  final int paymentCount;
  final int refundCount;
  final bool isFullyPaid;
  final double cashInHand;
  final double cashDeposited;

  PaymentSummary({
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRefunded,
    required this.balance,
    required this.paymentCount,
    required this.refundCount,
    required this.isFullyPaid,
    required this.cashInHand,
    required this.cashDeposited,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalAmount: double.parse((json['total_amount'] ?? 0).toString()),
      totalPaid: double.parse((json['total_paid'] ?? 0).toString()),
      totalRefunded: double.parse((json['total_refunded'] ?? 0).toString()),
      balance: double.parse((json['balance'] ?? 0).toString()),
      paymentCount: json['payment_count'] as int,
      refundCount: json['refund_count'] as int,
      isFullyPaid: json['is_fully_paid'] as bool? ?? false,
      cashInHand: double.parse((json['cash_in_hand'] ?? 0).toString()),
      cashDeposited: double.parse((json['cash_deposited'] ?? 0).toString()),
    );
  }
}
