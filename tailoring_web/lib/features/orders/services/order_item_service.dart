import 'package:tailoring_web/core/api/api_client.dart';
import '../models/order_item.dart';

/// Order Item Service
///
/// Handles order item (line item) API calls
class OrderItemService {
  final ApiClient _apiClient;

  OrderItemService(this._apiClient);

  /// Get order items for an order
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      final response = await _apiClient.get(
        'orders/order-items/',
        queryParameters: {'order': orderId},
      );

      final List results = response.data['results'] ?? response.data;
      return results.map((item) => OrderItem.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load order items: $e');
    }
  }

  /// Create order item
  Future<OrderItem> createOrderItem(OrderItem orderItem) async {
    try {
      final response = await _apiClient.post(
        'orders/order-items/',
        data: orderItem.toJson(),
      );
      return OrderItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create order item: $e');
    }
  }

  /// Update order item
  Future<OrderItem> updateOrderItem(int id, OrderItem orderItem) async {
    try {
      final response = await _apiClient.put(
        'orders/order-items/$id/',
        data: orderItem.toJson(),
      );
      return OrderItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update order item: $e');
    }
  }

  /// Delete order item
  Future<void> deleteOrderItem(int id) async {
    try {
      await _apiClient.delete('orders/order-items/$id/');
    } catch (e) {
      throw Exception('Failed to delete order item: $e');
    }
  }
}
