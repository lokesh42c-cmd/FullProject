import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/orders/models/order_item.dart';
import 'package:tailoring_web/features/orders/models/order_reference_photo.dart';

/// Order Model - Complete with items, measurements, and reference photos
class Order {
  final int? id;
  final int customerId;
  final Customer? customer;
  final String orderNumber;
  final String? qrCode;

  final DateTime orderDate;
  final DateTime? plannedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final DateTime? trialDate;

  final String status;
  final String priority;

  final double subtotal;
  final double orderDiscountPercentage;
  final double orderDiscountAmount;
  final double totalDiscount;
  final double totalTax;
  final double grandTotal;

  final double advancePaid;
  final double balance;

  final String? orderSummary;
  final String? customerInstructions;

  final List<OrderItem>? items;
  //final OrderMeasurement? measurements;
  final Map<String, dynamic>? customerMeasurements;
  final List<OrderReferencePhoto>? referencePhotos;

  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    required this.customerId,
    this.customer,
    required this.orderNumber,
    this.qrCode,
    required this.orderDate,
    this.plannedDeliveryDate,
    this.actualDeliveryDate,
    this.trialDate,
    required this.status,
    this.priority = 'NORMAL',
    required this.subtotal,
    this.orderDiscountPercentage = 0.0,
    this.orderDiscountAmount = 0.0,
    this.totalDiscount = 0.0,
    required this.totalTax,
    required this.grandTotal,
    this.advancePaid = 0.0,
    this.balance = 0.0,
    this.orderSummary,
    this.customerInstructions,
    this.items,
    //this.measurements,
    this.customerMeasurements,
    this.referencePhotos,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Order.fromJson(Map<String, dynamic> json) {
    final customerId = json['customer'] is int
        ? json['customer'] as int
        : (json['customer'] as Map<String, dynamic>?)?['id'] as int?;

    String? customerNameFromBackend = json['customer_name'] as String?;

    // Parse items if present
    List<OrderItem>? itemsList;
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    // ✅ PARSE REFERENCE PHOTOS
    List<OrderReferencePhoto>? referencePhotos;
    if (json['reference_photos'] != null && json['reference_photos'] is List) {
      try {
        referencePhotos = (json['reference_photos'] as List)
            .map(
              (photo) =>
                  OrderReferencePhoto.fromJson(photo as Map<String, dynamic>),
            )
            .toList();
      } catch (e) {
        print('Error parsing reference photos: $e');
      }
    }

    return Order(
      id: json['id'] as int?,
      customerId: customerId ?? 0,
      customer: customerNameFromBackend != null
          ? Customer(
              id: customerId,
              name: customerNameFromBackend,
              phone: '',
              customerType: 'INDIVIDUAL',
            )
          : null,
      orderNumber: json['order_number'] as String? ?? '',
      qrCode: json['qr_code'] as String?,
      orderDate: DateTime.parse(json['order_date'] as String),
      plannedDeliveryDate: json['planned_delivery_date'] != null
          ? DateTime.parse(json['planned_delivery_date'] as String)
          : null,
      actualDeliveryDate: json['actual_delivery_date'] != null
          ? DateTime.parse(json['actual_delivery_date'] as String)
          : null,
      trialDate: json['trial_date'] != null
          ? DateTime.parse(json['trial_date'] as String)
          : null,
      status: json['status'] as String? ?? 'PENDING',
      priority: json['priority'] as String? ?? 'NORMAL',
      subtotal: _parseDouble(json['subtotal']),
      orderDiscountPercentage: _parseDouble(json['order_discount_percentage']),
      orderDiscountAmount: _parseDouble(json['order_discount_amount']),
      totalDiscount: _parseDouble(json['total_discount']),
      totalTax: _parseDouble(json['total_tax']),
      grandTotal: _parseDouble(json['grand_total']),
      advancePaid: _parseDouble(json['advance_paid']),
      balance: _parseDouble(json['balance']),
      orderSummary: json['order_summary'] as String?,
      customerInstructions: json['customer_instructions'] as String?,
      items: itemsList,
      //measurements: measurements, // ✅ ADD THIS
      customerMeasurements:
          json['customer_measurements'] as Map<String, dynamic>?,
      referencePhotos: referencePhotos, // ✅ ADD THIS
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      if (id != null) 'id': id,
      'customer': customerId,
      'order_date': orderDate.toIso8601String().split('T')[0],
      if (plannedDeliveryDate != null)
        'planned_delivery_date': plannedDeliveryDate!.toIso8601String().split(
          'T',
        )[0],
      if (actualDeliveryDate != null)
        'actual_delivery_date': actualDeliveryDate!.toIso8601String().split(
          'T',
        )[0],
      if (trialDate != null)
        'trial_date': trialDate!.toIso8601String().split('T')[0],
      'status': status,
      'priority': priority,
      'subtotal': subtotal,
      'order_discount_percentage': orderDiscountPercentage,
      'order_discount_amount': orderDiscountAmount,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'grand_total': grandTotal,
      'advance_paid': advancePaid,
      'balance': balance,
      'order_summary': orderSummary ?? '',
      'customer_instructions': customerInstructions ?? '',
      'is_active': isActive,
    };

    if (items != null && items!.isNotEmpty) {
      json['items'] = items!.map((item) => item.toJson()).toList();
    }

    return json;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'READY':
        return 'Ready for Pickup';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get priorityDisplay {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return 'Low';
      case 'NORMAL':
        return 'Normal';
      case 'HIGH':
        return 'High';
      case 'URGENT':
        return 'Urgent';
      default:
        return priority;
    }
  }

  String get customerName => customer?.name ?? 'Unknown';
  String get formattedGrandTotal => '₹${grandTotal.toStringAsFixed(2)}';
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';
  String get formattedBalance => '₹${balance.toStringAsFixed(2)}';
  String get formattedTotal => '₹${grandTotal.toStringAsFixed(2)}';
  String get formattedOrderDate =>
      '${orderDate.day}/${orderDate.month}/${orderDate.year}';
  String get formattedDeliveryDate => plannedDeliveryDate != null
      ? '${plannedDeliveryDate!.day}/${plannedDeliveryDate!.month}/${plannedDeliveryDate!.year}'
      : '-';
}

class OrderListResponse {
  final List<Order> orders;
  final int count;

  OrderListResponse({required this.orders, required this.count});

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      orders:
          (json['results'] as List?)
              ?.map((order) => Order.fromJson(order))
              .toList() ??
          [],
      count: json['count'] as int? ?? 0,
    );
  }
}

class OrderStatus {
  static const String pending = 'PENDING';
  static const String inProgress = 'IN_PROGRESS';
  static const String ready = 'READY';
  static const String delivered = 'DELIVERED';
  static const String completed = 'DELIVERED';
  static const String cancelled = 'CANCELLED';

  static List<Map<String, String>> get all => [
    {'value': pending, 'label': 'Pending'},
    {'value': inProgress, 'label': 'In Progress'},
    {'value': ready, 'label': 'Ready'},
    {'value': delivered, 'label': 'Delivered'},
    {'value': cancelled, 'label': 'Cancelled'},
  ];
}

class OrderPriority {
  static const String low = 'LOW';
  static const String normal = 'NORMAL';
  static const String high = 'HIGH';
  static const String urgent = 'URGENT';

  static List<Map<String, String>> get all => [
    {'value': low, 'label': 'Low'},
    {'value': normal, 'label': 'Normal'},
    {'value': high, 'label': 'High'},
    {'value': urgent, 'label': 'Urgent'},
  ];
}
