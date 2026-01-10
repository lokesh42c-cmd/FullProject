import 'order_item.dart';

/// Order Model
/// Matches: orders.Order from backend
class Order {
  // Identity
  final int? id;
  final String orderNumber;

  // Customer
  final int customerId;
  final String? customerName; // From API response
  final String? customerPhone; // From API response

  // Dates
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? actualDeliveryDate;

  // Status
  final String
  orderStatus; // DRAFT, CONFIRMED, IN_PROGRESS, READY, COMPLETED, CANCELLED
  final String deliveryStatus; // NOT_STARTED, PARTIAL, DELIVERED

  // Work Assignment
  final int? assignedTo;

  // Pricing
  final double estimatedTotal;
  final String? paymentTerms;

  // Details
  final String? orderSummary;
  final String? customerInstructions;

  // Items
  final List<OrderItem> items;

  // QR & Lock
  final String? qrCode; // URL from backend
  final bool isLocked;

  // Future payment integration (read-only)
  final double? totalPaid;
  final double? remainingBalance;

  // Audit
  final int? createdBy;
  final int? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.actualDeliveryDate,
    this.orderStatus = 'DRAFT',
    this.deliveryStatus = 'NOT_STARTED',
    this.assignedTo,
    this.estimatedTotal = 0.0,
    this.paymentTerms,
    this.orderSummary,
    this.customerInstructions,
    this.items = const [],
    this.qrCode,
    this.isLocked = false,
    this.totalPaid,
    this.remainingBalance,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  // Computed properties
  bool get isOverdue {
    if (expectedDeliveryDate == null) return false;
    if (orderStatus == 'COMPLETED' || orderStatus == 'CANCELLED') return false;
    return DateTime.now().isAfter(expectedDeliveryDate!);
  }

  int? get daysUntilDelivery {
    if (expectedDeliveryDate == null) return null;
    return expectedDeliveryDate!.difference(DateTime.now()).inDays;
  }

  // Display helpers
  String get orderStatusDisplay {
    switch (orderStatus) {
      case 'DRAFT':
        return 'Draft';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'READY':
        return 'Ready';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return orderStatus;
    }
  }

  String get deliveryStatusDisplay {
    switch (deliveryStatus) {
      case 'NOT_STARTED':
        return 'Not Started';
      case 'PARTIAL':
        return 'Partial';
      case 'DELIVERED':
        return 'Delivered';
      default:
        return deliveryStatus;
    }
  }

  // Formatted dates
  String get formattedOrderDate {
    return '${orderDate.day.toString().padLeft(2, '0')}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.year}';
  }

  String get formattedExpectedDeliveryDate {
    if (expectedDeliveryDate == null) return '-';
    return '${expectedDeliveryDate!.day.toString().padLeft(2, '0')}-${expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${expectedDeliveryDate!.year}';
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      orderNumber: json['order_number'] as String,
      customerId: json['customer'] as int,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      orderDate: DateTime.parse(json['order_date'] as String),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      actualDeliveryDate: json['actual_delivery_date'] != null
          ? DateTime.parse(json['actual_delivery_date'] as String)
          : null,
      orderStatus: json['order_status'] as String? ?? 'DRAFT',
      deliveryStatus: json['delivery_status'] as String? ?? 'NOT_STARTED',
      assignedTo: json['assigned_to'] as int?,
      estimatedTotal: (json['estimated_total'] as num?)?.toDouble() ?? 0.0,
      paymentTerms: json['payment_terms'] as String?,
      orderSummary: json['order_summary'] as String?,
      customerInstructions: json['customer_instructions'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
                .toList()
          : [],
      qrCode: json['qr_code'] as String?,
      isLocked: json['is_locked'] as bool? ?? false,
      totalPaid: json['total_paid'] != null
          ? (json['total_paid'] as num).toDouble()
          : null,
      remainingBalance: json['remaining_balance'] != null
          ? (json['remaining_balance'] as num).toDouble()
          : null,
      createdBy: json['created_by'] as int?,
      updatedBy: json['updated_by'] as int?,
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
      'order_number': orderNumber,
      'customer': customerId,
      'order_date': orderDate.toIso8601String().split('T')[0],
      if (expectedDeliveryDate != null)
        'expected_delivery_date': expectedDeliveryDate!.toIso8601String().split(
          'T',
        )[0],
      if (actualDeliveryDate != null)
        'actual_delivery_date': actualDeliveryDate!.toIso8601String().split(
          'T',
        )[0],
      'order_status': orderStatus,
      'delivery_status': deliveryStatus,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'estimated_total': estimatedTotal,
      if (paymentTerms != null && paymentTerms!.isNotEmpty)
        'payment_terms': paymentTerms,
      if (orderSummary != null && orderSummary!.isNotEmpty)
        'order_summary': orderSummary,
      if (customerInstructions != null && customerInstructions!.isNotEmpty)
        'customer_instructions': customerInstructions,
      'items': items.map((item) => item.toJson()).toList(),
      'is_locked': isLocked,
    };
  }

  Order copyWith({
    int? id,
    String? orderNumber,
    int? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    DateTime? actualDeliveryDate,
    String? orderStatus,
    String? deliveryStatus,
    int? assignedTo,
    double? estimatedTotal,
    String? paymentTerms,
    String? orderSummary,
    String? customerInstructions,
    List<OrderItem>? items,
    String? qrCode,
    bool? isLocked,
    double? totalPaid,
    double? remainingBalance,
    int? createdBy,
    int? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      orderStatus: orderStatus ?? this.orderStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      assignedTo: assignedTo ?? this.assignedTo,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      orderSummary: orderSummary ?? this.orderSummary,
      customerInstructions: customerInstructions ?? this.customerInstructions,
      items: items ?? this.items,
      qrCode: qrCode ?? this.qrCode,
      isLocked: isLocked ?? this.isLocked,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
