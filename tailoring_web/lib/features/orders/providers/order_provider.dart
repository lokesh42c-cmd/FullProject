import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService orderService;

  OrderProvider(this.orderService);

  // =============================
  // STATE
  // =============================
  List<Order> _orders = [];
  Order? _currentOrder;

  bool isLoading = false;

  int _page = 1;
  int _totalCount = 0;

  String? _searchQuery;
  String? _filterStatus;
  int? _customerId;

  // =============================
  // GETTERS (USED BY UI)
  // =============================
  List<Order> get orders => _orders;
  List<Order> get filteredOrders => _orders;
  Order? get currentOrder => _currentOrder;
  String? get filterStatus => _filterStatus;
  bool get hasOrders => _orders.isNotEmpty;
  bool get canLoadMore => _orders.length < _totalCount;

  // =============================
  // FETCH ORDERS LIST
  // =============================
  Future<void> fetchOrders({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _orders.clear();
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await orderService.fetchOrders(
        page: _page,
        search: _searchQuery,
        status: _filterStatus,
      );

      final List results = response['results'] ?? [];
      _totalCount = response['count'] ?? 0;

      final fetchedOrders = results.map((e) => Order.fromJson(e)).toList();

      if (reset) {
        _orders = fetchedOrders;
      } else {
        _orders.addAll(fetchedOrders);
      }

      _page++;
    } catch (e) {
      debugPrint('Order fetch error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // =============================
  // LEGACY UI METHODS
  // =============================
  void refresh() {
    fetchOrders(reset: true);
  }

  void setSearchQuery(String? value) {
    _searchQuery = value;
    fetchOrders(reset: true);
  }

  void setFilterStatus(String? value) {
    _filterStatus = value;
    fetchOrders(reset: true);
  }

  void setCustomerFilter(int? customerId) {
    _customerId = customerId;
    fetchOrders(reset: true);
  }

  void clearCustomerFilter() {
    _customerId = null;
    fetchOrders(reset: true);
  }

  // =============================
  // SINGLE ORDER
  // =============================
  Future<Order?> getOrderDetail(int orderId) async {
    isLoading = true;
    notifyListeners();

    try {
      _currentOrder = await orderService.fetchOrder(orderId);
      return _currentOrder;
    } catch (e) {
      debugPrint('Get order detail error: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // CREATE ORDER (UI CONTRACT – FINAL)
  // =============================
  Future<Order?> createOrder(
    Order order, {
    dynamic referencePhotos, // handled elsewhere
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // IMPORTANT:
      // Payload creation + reference photo handling
      // already happens in CreateOrderProvider / OrderService.
      // OrderProvider should NOT duplicate that logic.

      await orderService.createOrder(order.toJson());

      refresh();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
