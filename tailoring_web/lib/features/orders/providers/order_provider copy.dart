import 'package:flutter/foundation.dart';
import 'package:tailoring_web/features/orders/models/order.dart';
import 'package:tailoring_web/features/orders/services/order_service.dart';
import 'package:tailoring_web/features/orders/widgets/reference_photos_picker.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service;

  List<Order> _orders = [];
  Order? _selectedOrder;
  String? _errorMessage;
  bool _isLoading = false;

  // Filter and search state
  String? _filterStatus;
  int? _filterCustomerId;
  String _searchQuery = '';

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get filterStatus => _filterStatus;

  // Filtered orders based on search and filters
  List<Order> get filteredOrders {
    var filtered = _orders;

    // Apply status filter
    if (_filterStatus != null && _filterStatus != 'ALL') {
      filtered = filtered.where((o) => o.status == _filterStatus).toList();
    }

    // Apply customer filter
    if (_filterCustomerId != null) {
      filtered = filtered
          .where((o) => o.customerId == _filterCustomerId)
          .toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((o) {
        final query = _searchQuery.toLowerCase();
        return o.orderNumber.toLowerCase().contains(query) ||
            o.customerName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  OrderProvider(this._service);

  /// Fetch all orders
  Future<void> fetchOrders({
    String? status,
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getOrders(
        status: status,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
        search: search,
      );
      _orders = response.orders;
      _errorMessage = null;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh orders (alias for fetchOrders)
  Future<void> refresh() async {
    await fetchOrders(
      status: _filterStatus,
      customerId: _filterCustomerId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  /// Get order detail by ID
  Future<Order?> getOrderDetail(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final order = await _service.getOrder(id);
      _selectedOrder = order;
      _errorMessage = null;

      return order;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create order with optional reference photos
  ///
  /// [order] - The order to create
  /// [referencePhotos] - Optional list of reference photos to upload
  Future<Order?> createOrder(
    Order order, {
    List<ReferencePhotoData>? referencePhotos,
  }) async {
    try {
      final created = await _service.createOrder(
        order,
        referencePhotos: referencePhotos,
      );
      _orders.insert(0, created); // Add to beginning
      _errorMessage = null;
      notifyListeners();
      return created;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
      notifyListeners();
      return null;
    }
  }

  /// Update existing order
  Future<Order?> updateOrder(int id, Order order) async {
    try {
      final updated = await _service.updateOrder(id, order);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = updated;
      }
      _errorMessage = null;
      notifyListeners();
      return updated;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
      notifyListeners();
      return null;
    }
  }

  /// Delete order
  Future<bool> deleteOrder(int id) async {
    try {
      await _service.deleteOrder(id);
      _orders.removeWhere((o) => o.id == id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }

  /// Update order status
  Future<Order?> updateOrderStatus(int id, String status) async {
    try {
      final updated = await _service.updateStatus(id, status);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = updated;
      }
      _errorMessage = null;
      notifyListeners();
      return updated;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
      notifyListeners();
      return null;
    }
  }

  /// Set status filter
  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  /// Set customer filter
  void setCustomerFilter(int? customerId) {
    _filterCustomerId = customerId;
    fetchOrders(customerId: customerId);
  }

  /// Clear customer filter
  void clearCustomerFilter() {
    _filterCustomerId = null;
    fetchOrders();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }
}
