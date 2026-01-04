import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/orders/widgets/reference_photos_picker.dart';
import '../models/order.dart';

/// Order Service
///
/// Handles all order-related API calls
/// UPDATED: Now supports reference photos upload
class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  /// Get all orders with optional filters
  Future<OrderListResponse> getOrders({
    String? status,
    int? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (status != null) {
        queryParams['status'] = status;
      }
      if (customerId != null) {
        queryParams['customer'] = customerId;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        'orders/orders/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return OrderListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  /// Get single order
  Future<Order> getOrder(int id) async {
    try {
      final response = await _apiClient.get('orders/orders/$id/');
      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  /// Create order with optional reference photos
  ///
  /// [order] - The order to create
  /// [referencePhotos] - Optional list of reference photos to upload
  ///
  /// UPDATED: Added reference photos support
  Future<Order> createOrder(
    Order order, {
    List<ReferencePhotoData>? referencePhotos,
  }) async {
    try {
      // Convert order to JSON
      final orderData = order.toJson();

      // Add reference photos if provided
      if (referencePhotos != null && referencePhotos.isNotEmpty) {
        orderData['reference_photos'] = referencePhotos.map((photo) {
          return {
            'photo': photo.imageBase64, // Base64 encoded image
            'description': photo.description,
            'file_name': photo.fileName,
          };
        }).toList();

        print(
          '📸 Sending ${referencePhotos.length} reference photos with order',
        );
      }

      // Make API call
      final response = await _apiClient.post('orders/orders/', data: orderData);

      return Order.fromJson(response.data['order']);
    } on ApiException catch (e) {
      if (e.hasFieldErrors) {
        final firstError = e.fieldErrors!.entries.first;
        throw Exception('${firstError.key}: ${firstError.value}');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Update order
  Future<Order> updateOrder(int id, Order order) async {
    try {
      final response = await _apiClient.put(
        'orders/orders/$id/',
        data: order.toJson(),
      );
      return Order.fromJson(response.data);
    } on ApiException catch (e) {
      if (e.hasFieldErrors) {
        final firstError = e.fieldErrors!.entries.first;
        throw Exception('${firstError.key}: ${firstError.value}');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  /// Delete order
  Future<void> deleteOrder(int id) async {
    try {
      await _apiClient.delete('orders/orders/$id/');
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  /// Update order status
  Future<Order> updateStatus(int id, String status) async {
    try {
      final response = await _apiClient.patch(
        'orders/orders/$id/',
        data: {'status': status},
      );
      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
