import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'package:tailoring_web/core/api/api_client.dart';

/// Order Provider
/// Manages Order state and business logic
class OrderProvider with ChangeNotifier {
  final OrderService _orderService;

  OrderProvider({OrderService? orderService})
    : _orderService = orderService ?? OrderService();

  // State
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String? _searchQuery;
  String? _filterOrderStatus;
  String? _filterDeliveryStatus;
  bool? _filterIsLocked;
  int? _filterCustomerId;

  // Getters
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  String? get filterOrderStatus => _filterOrderStatus;
  String? get filterDeliveryStatus => _filterDeliveryStatus;
  bool? get filterIsLocked => _filterIsLocked;
  int? get filterCustomerId => _filterCustomerId;

  // Filtered orders
  List<Order> get filteredOrders {
    return _orders.where((order) {
      // Search filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        final matchesOrderNumber = order.orderNumber.toLowerCase().contains(
          query,
        );
        final matchesCustomerName =
            order.customerName?.toLowerCase().contains(query) ?? false;
        final matchesCustomerPhone =
            order.customerPhone?.toLowerCase().contains(query) ?? false;
        if (!matchesOrderNumber &&
            !matchesCustomerName &&
            !matchesCustomerPhone) {
          return false;
        }
      }

      // Order status filter
      if (_filterOrderStatus != null &&
          order.orderStatus != _filterOrderStatus) {
        return false;
      }

      // Delivery status filter
      if (_filterDeliveryStatus != null &&
          order.deliveryStatus != _filterDeliveryStatus) {
        return false;
      }

      // Locked filter
      if (_filterIsLocked != null && order.isLocked != _filterIsLocked) {
        return false;
      }

      // Customer filter
      if (_filterCustomerId != null && order.customerId != _filterCustomerId) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Fetch all orders
  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.fetchOrders(
        search: _searchQuery,
        orderStatus: _filterOrderStatus,
        deliveryStatus: _filterDeliveryStatus,
        isLocked: _filterIsLocked,
        customerId: _filterCustomerId,
      );
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to fetch orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch order by ID
  Future<Order?> fetchOrderById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentOrder = await _orderService.fetchOrderById(id);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return _currentOrder;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to fetch order: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Create new order
  Future<Order?> createOrder(Order order) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdOrder = await _orderService.createOrder(order);
      _orders.insert(0, createdOrder);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return createdOrder;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to create order: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update existing order
  Future<Order?> updateOrder(int id, Order order) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _orderService.updateOrder(id, order);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }
      if (_currentOrder?.id == id) {
        _currentOrder = updatedOrder;
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return updatedOrder;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to update order: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Delete order
  Future<bool> deleteOrder(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.deleteOrder(id);
      _orders.removeWhere((order) => order.id == id);
      if (_currentOrder?.id == id) {
        _currentOrder = null;
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete order: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lock order
  Future<bool> lockOrder(int id) async {
    try {
      final lockedOrder = await _orderService.lockOrder(id);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = lockedOrder;
      }
      if (_currentOrder?.id == id) {
        _currentOrder = lockedOrder;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to lock order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Unlock order
  Future<bool> unlockOrder(int id) async {
    try {
      final unlockedOrder = await _orderService.unlockOrder(id);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = unlockedOrder;
      }
      if (_currentOrder?.id == id) {
        _currentOrder = unlockedOrder;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to unlock order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Upload reference photo
  Future<Map<String, dynamic>?> uploadReferencePhoto(
    int orderId,
    String filePath,
  ) async {
    try {
      return await _orderService.uploadReferencePhoto(orderId, filePath);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to upload photo: $e';
      notifyListeners();
      return null;
    }
  }

  /// Delete reference photo
  Future<bool> deleteReferencePhoto(int orderId, int photoId) async {
    try {
      await _orderService.deleteReferencePhoto(orderId, photoId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete photo: $e';
      notifyListeners();
      return false;
    }
  }

  /// Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set order status filter
  void setFilterOrderStatus(String? status) {
    _filterOrderStatus = status;
    notifyListeners();
  }

  /// Set delivery status filter
  void setFilterDeliveryStatus(String? status) {
    _filterDeliveryStatus = status;
    notifyListeners();
  }

  /// Set locked filter
  void setFilterIsLocked(bool? isLocked) {
    _filterIsLocked = isLocked;
    notifyListeners();
  }

  /// Set customer filter
  void setFilterCustomerId(int? customerId) {
    _filterCustomerId = customerId;
    notifyListeners();
  }

  /// Clear customer filter
  void clearCustomerFilter() {
    _filterCustomerId = null;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = null;
    _filterOrderStatus = null;
    _filterDeliveryStatus = null;
    _filterIsLocked = null;
    _filterCustomerId = null;
    notifyListeners();
  }

  /// Refresh orders
  Future<void> refresh() async {
    await fetchOrders();
  }

  /// Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
