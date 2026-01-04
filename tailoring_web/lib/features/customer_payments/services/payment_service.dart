/// Payment Service - API calls
/// Location: lib/features/payments/services/payment_service.dart

import 'package:tailoring_web/core/api/api_client.dart';

import 'package:tailoring_web/features/customer_payments/models/payment.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService(this._apiClient);

  /// Get all payments with optional filters
  Future<List<Payment>> getPayments({
    int? orderId,
    int? customerId,
    String? paymentMethod,
    String? dateFrom,
    String? dateTo,
    bool? cashInHand,
    String? refunds, // 'only', 'exclude', or null for all
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (orderId != null) queryParams['order_id'] = orderId;
      if (customerId != null) queryParams['customer_id'] = customerId;
      if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (cashInHand != null) queryParams['cash_in_hand'] = cashInHand;
      if (refunds != null) queryParams['refunds'] = refunds;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get(
        'orders/payments/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> results = response.data['results'];
      return results.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }

  /// Get single payment by ID
  Future<Payment> getPayment(int id) async {
    try {
      final response = await _apiClient.get('orders/payments/$id/');
      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load payment: $e');
    }
  }

  /// Create new payment
  Future<Payment> createPayment({
    required int orderId,
    required double amount,
    required String paymentMethod,
    DateTime? paymentDate,
    String? referenceNumber,
    String? notes,
    String? bankName,
  }) async {
    try {
      final data = {
        'order': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_date': (paymentDate ?? DateTime.now()).toIso8601String(),
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'reference_number': referenceNumber,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (bankName != null && bankName.isNotEmpty) 'bank_name': bankName,
      };

      final response = await _apiClient.post('orders/payments/', data: data);
      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  /// Update payment
  Future<Payment> updatePayment(
    int id, {
    double? amount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? referenceNumber,
    String? notes,
    String? bankName,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (amount != null) data['amount'] = amount;
      if (paymentMethod != null) data['payment_method'] = paymentMethod;
      if (paymentDate != null)
        data['payment_date'] = paymentDate.toIso8601String();
      if (referenceNumber != null) data['reference_number'] = referenceNumber;
      if (notes != null) data['notes'] = notes;
      if (bankName != null) data['bank_name'] = bankName;

      final response = await _apiClient.patch(
        'orders/payments/$id/',
        data: data,
      );

      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  /// Void payment (creates negative entry)
  Future<Payment> voidPayment(int id, String reason) async {
    try {
      final response = await _apiClient.delete(
        'orders/payments/$id/',
        data: {'reason': reason},
      );

      return Payment.fromJson(response.data['void_payment']);
    } catch (e) {
      throw Exception('Failed to void payment: $e');
    }
  }

  /// Mark cash payment as deposited
  Future<Payment> markDeposited({
    required int id,
    required DateTime depositDate,
    required String depositBankName,
  }) async {
    try {
      final data = {
        'deposit_date': depositDate.toIso8601String().split('T')[0],
        'deposit_bank_name': depositBankName,
      };

      final response = await _apiClient.post(
        'orders/payments/$id/mark_deposited/',
        data: data,
      );

      return Payment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to mark payment as deposited: $e');
    }
  }

  /// Get payment summary
  Future<PaymentSummary> getPaymentSummary({int? orderId}) async {
    try {
      final queryParams = orderId != null ? {'order_id': orderId} : null;

      final response = await _apiClient.get(
        'orders/payments/summary/',
        queryParameters: queryParams,
      );

      return PaymentSummary.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load payment summary: $e');
    }
  }
}
