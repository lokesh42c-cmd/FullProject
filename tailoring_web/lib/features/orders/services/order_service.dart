import 'package:dio/dio.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../models/order.dart';

/// Order Service
///
/// BACKWARD COMPATIBLE
/// - Keeps existing method names used by OrderProvider
/// - Fixes `/api/api` issue
/// - Does NOT break old code
class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  // =========================================================
  // ORDERS LIST (USED BY OrderProvider.fetchOrders)
  // =========================================================
  Future<Map<String, dynamic>> fetchOrders({
    int page = 1,
    String? search,
    String? status,
    int? customerId,
  }) async {
    final response = await _apiClient.get(
      '/orders/orders/',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (customerId != null) 'customer_id': customerId,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // =========================================================
  // SINGLE ORDER (USED BY OrderProvider.fetchOrder)
  // =========================================================
  Future<Order> fetchOrder(int orderId) async {
    final response = await _apiClient.get('/orders/orders/$orderId/');

    return Order.fromJson(response.data);
  }

  // =========================================================
  // CREATE ORDER
  // =========================================================
  Future<Order> createOrder(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/orders/orders/', data: payload);

    return Order.fromJson(response.data);
  }

  // =========================================================
  // UPDATE ORDER (EDIT ORDER)
  // =========================================================
  Future<Order> updateOrder(int orderId, Map<String, dynamic> payload) async {
    final response = await _apiClient.put(
      '/orders/orders/$orderId/',
      data: payload,
    );

    return Order.fromJson(response.data);
  }

  // =========================================================
  // REFERENCE PHOTOS UPLOAD (OPTIONAL / POST-CREATE)
  // =========================================================
  Future<void> uploadReferencePhotos(
    int orderId,
    List<MultipartFile> files,
  ) async {
    if (files.isEmpty) return;

    final formData = FormData.fromMap({'photos': files});

    await _apiClient.post(
      '/orders/orders/$orderId/reference-photos/',
      data: formData,
    );
  }
}
