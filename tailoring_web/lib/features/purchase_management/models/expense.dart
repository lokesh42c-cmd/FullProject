import 'payment.dart';

class Expense {
  final int? id;
  final DateTime expenseDate;
  final String category;
  final String? categoryDisplay;
  final String expenseAmount;
  final String paidAmount;
  final String balanceAmount;
  final String paymentStatus;
  final String? paymentStatusDisplay;
  final String? description;
  final String? receiptImageUrl;
  final String? notes;
  final DateTime? createdAt;

  final List<Payment>? payments;
  final double? paymentPercentage;

  Expense({
    this.id,
    required this.expenseDate,
    required this.category,
    this.categoryDisplay,
    required this.expenseAmount,
    this.paidAmount = '0.00',
    this.balanceAmount = '0.00',
    this.paymentStatus = 'UNPAID',
    this.paymentStatusDisplay,
    this.description,
    this.receiptImageUrl,
    this.notes,
    this.createdAt,
    this.payments,
    this.paymentPercentage,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      category: json['category'] as String,
      categoryDisplay: json['category_display'] as String?,
      expenseAmount: json['expense_amount']?.toString() ?? '0.00',
      paidAmount: json['paid_amount']?.toString() ?? '0.00',
      balanceAmount: json['balance_amount']?.toString() ?? '0.00',
      paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
      paymentStatusDisplay: json['payment_status_display'] as String?,
      description: json['description'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      payments: json['payments'] != null
          ? (json['payments'] as List)
                .map((payment) => Payment.fromJson(payment))
                .toList()
          : null,
      paymentPercentage: json['payment_percentage'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'category': category,
      'expense_amount': expenseAmount,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
    };
  }

  double get expenseAmountDouble => double.tryParse(expenseAmount) ?? 0.0;
  double get paidAmountDouble => double.tryParse(paidAmount) ?? 0.0;
  double get balanceAmountDouble => double.tryParse(balanceAmount) ?? 0.0;
}
