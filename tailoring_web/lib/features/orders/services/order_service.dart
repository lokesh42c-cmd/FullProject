import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../models/order.dart';

/// Order Service
/// Handles all Order-related API calls
class OrderService {
  final ApiClient _apiClient;

  OrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch all orders with optional filters
  Future<List<Order>> fetchOrders({
    String? search,
    String? orderStatus,
    String? deliveryStatus,
    bool? isLocked,
    int? customerId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (orderStatus != null) {
        queryParams['order_status'] = orderStatus;
      }
      if (deliveryStatus != null) {
        queryParams['delivery_status'] = deliveryStatus;
      }
      if (isLocked != null) {
        queryParams['is_locked'] = isLocked;
      }
      if (customerId != null) {
        queryParams['customer'] = customerId;
      }

      final response = await _apiClient.get(
        'orders/orders/',
        queryParameters: queryParams,
      );

      // Handle both paginated and non-paginated responses
      final responseData = response.data;
      final List<dynamic> data;

      if (responseData is List) {
        // Direct list response
        data = responseData;
      } else if (responseData is Map && responseData.containsKey('results')) {
        // Paginated response {count, next, previous, results}
        data = responseData['results'] as List<dynamic>;
      } else {
        // Unexpected format
        throw Exception('Unexpected API response format');
      }

      return data
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch single order by ID
  Future<Order> fetchOrderById(int id) async {
    try {
      final response = await _apiClient.get('orders/orders/$id/');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new order
  Future<Order> createOrder(Order order) async {
    try {
      final response = await _apiClient.post(
        'orders/orders/',
        data: order.toJson(),
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing order
  Future<Order> updateOrder(int id, Order order) async {
    try {
      final response = await _apiClient.put(
        'orders/orders/$id/',
        data: order.toJson(),
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete order
  Future<void> deleteOrder(int id) async {
    try {
      await _apiClient.delete('orders/orders/$id/');
    } catch (e) {
      rethrow;
    }
  }

  /// Lock order
  Future<Order> lockOrder(int id) async {
    try {
      final response = await _apiClient.post('orders/orders/$id/lock/');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Unlock order
  Future<Order> unlockOrder(int id) async {
    try {
      final response = await _apiClient.post('orders/orders/$id/unlock/');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload reference photo (web compatible - uses bytes)
  Future<Map<String, dynamic>> uploadReferencePhoto(
    int orderId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(imageBytes, filename: fileName),
      });

      final response = await _apiClient.post(
        'orders/orders/$orderId/upload_photo/',
        data: formData,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete reference photo
  Future<void> deleteReferencePhoto(int orderId, int photoId) async {
    try {
      await _apiClient.delete('orders/orders/$orderId/delete_photo/$photoId/');
    } catch (e) {
      rethrow;
    }
  }
}
