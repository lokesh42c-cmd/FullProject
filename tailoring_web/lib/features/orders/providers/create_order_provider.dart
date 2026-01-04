import 'package:flutter/material.dart';
import '../models/order_item.dart';

/// Create Order Provider - Manages order creation form state
///
/// Handles:
/// - Order items list (before saving)
/// - Total calculations
/// - Form validation
class CreateOrderProvider extends ChangeNotifier {
  // ==================== STATE ====================

  // Selected customer
  int? _selectedCustomerId;
  String? _selectedCustomerName;

  // Order dates
  DateTime _orderDate = DateTime.now();
  DateTime _plannedDeliveryDate = DateTime.now().add(const Duration(days: 7));

  // Priority
  String _priority = 'NORMAL';

  // Order items (before saving to backend)
  final List<OrderItem> _items = [];

  // Payment
  double _advancePayment = 0.0;

  // Notes
  String? _orderSummary;
  String? _customerInstructions;

  // ==================== GETTERS ====================

  int? get selectedCustomerId => _selectedCustomerId;
  String? get selectedCustomerName => _selectedCustomerName;
  DateTime get orderDate => _orderDate;
  DateTime get plannedDeliveryDate => _plannedDeliveryDate;
  String get priority => _priority;
  List<OrderItem> get items => _items;
  double get advancePayment => _advancePayment;
  String? get orderSummary => _orderSummary;
  String? get customerInstructions => _customerInstructions;

  // Calculated totals
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => sum + item.itemDiscountAmount);
  }

  double get totalTax {
    return _items.fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  double get grandTotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get balanceDue {
    return grandTotal - _advancePayment;
  }

  bool get hasItems => _items.isNotEmpty;

  bool get isValid {
    return _selectedCustomerId != null && _items.isNotEmpty;
  }

  // ==================== SETTERS ====================

  void setCustomer(int customerId, String customerName) {
    _selectedCustomerId = customerId;
    _selectedCustomerName = customerName;
    notifyListeners();
  }

  void setOrderDate(DateTime date) {
    _orderDate = date;
    notifyListeners();
  }

  void setPlannedDeliveryDate(DateTime date) {
    _plannedDeliveryDate = date;
    notifyListeners();
  }

  void setPriority(String priority) {
    _priority = priority;
    notifyListeners();
  }

  void setAdvancePayment(double amount) {
    _advancePayment = amount;
    notifyListeners();
  }

  void setOrderSummary(String? summary) {
    _orderSummary = summary;
    notifyListeners();
  }

  void setCustomerInstructions(String? instructions) {
    _customerInstructions = instructions;
    notifyListeners();
  }

  // ==================== ITEM OPERATIONS ====================

  /// Add item to order
  void addItem(OrderItem item) {
    // Calculate totals before adding
    final calculatedItem = item.calculateTotals();
    _items.add(calculatedItem);
    notifyListeners();
  }

  /// Update item at index
  void updateItem(int index, OrderItem item) {
    if (index >= 0 && index < _items.length) {
      final calculatedItem = item.calculateTotals();
      _items[index] = calculatedItem;
      notifyListeners();
    }
  }

  /// Remove item at index
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all items
  void clearItems() {
    _items.clear();
    notifyListeners();
  }

  // ==================== ORDER DATA PREPARATION ====================

  /// Prepare order data for API submission
  Map<String, dynamic> prepareOrderData() {
    if (!isValid) {
      throw Exception('Order is not valid. Customer and items are required.');
    }

    // Prepare items data
    final itemsData = _items.map((item) {
      return {
        if (item.familyMember != null) 'family_member': item.familyMember,
        'category': item.category,
        'item_type': item.itemType,
        'item_description': item.itemDescription,
        if (item.description != null) 'description': item.description,
        if (item.inventoryItem != null) 'inventory_item': item.inventoryItem,
        'quantity': item.quantity,
        if (item.unit != null) 'unit': item.unit,
        'unit_price': item.unitPrice,
        'item_discount_percentage': item.itemDiscountPercentage,
        'tax_percentage': item.taxPercentage,
        if (item.hsnCode != null) 'hsn_code': item.hsnCode,
        if (item.measurementsSnapshot != null)
          'measurements_snapshot': item.measurementsSnapshot,
        if (item.notes != null) 'notes': item.notes,
        'fabric_provided_by_customer': item.fabricProvidedByCustomer,
        if (item.fabricDetails != null) 'fabric_details': item.fabricDetails,
      };
    }).toList();

    return {
      'customer': _selectedCustomerId,
      'order_date': _orderDate.toIso8601String(),
      'planned_delivery_date': _plannedDeliveryDate.toIso8601String().split(
        'T',
      )[0],
      'priority': _priority,
      'items': itemsData,
      if (_orderSummary != null) 'order_summary': _orderSummary,
      if (_customerInstructions != null)
        'customer_instructions': _customerInstructions,
      // Note: advance_paid will be handled separately via payment API
    };
  }

  // ==================== RESET ====================

  /// Reset form to initial state
  void reset() {
    _selectedCustomerId = null;
    _selectedCustomerName = null;
    _orderDate = DateTime.now();
    _plannedDeliveryDate = DateTime.now().add(const Duration(days: 7));
    _priority = 'NORMAL';
    _items.clear();
    _advancePayment = 0.0;
    _orderSummary = null;
    _customerInstructions = null;
    notifyListeners();
  }

  // ==================== VALIDATION ====================

  /// Validate order before submission
  String? validate() {
    if (_selectedCustomerId == null) {
      return 'Please select a customer';
    }

    if (_items.isEmpty) {
      return 'Please add at least one item';
    }

    if (_plannedDeliveryDate.isBefore(_orderDate)) {
      return 'Delivery date cannot be before order date';
    }

    if (_advancePayment < 0) {
      return 'Advance payment cannot be negative';
    }

    if (_advancePayment > grandTotal) {
      return 'Advance payment cannot exceed grand total';
    }

    return null; // Valid
  }
}
