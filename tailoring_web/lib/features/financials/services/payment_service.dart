import 'package:tailoring_web/core/api/api_client.dart';
import '../models/receipt_voucher.dart';
import '../models/refund_voucher.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  // ==================== RECEIPT VOUCHERS ====================

  /// Create a new receipt voucher (advance payment)
  Future<ReceiptVoucher> createReceiptVoucher(ReceiptVoucher voucher) async {
    try {
      final response = await _apiClient.post(
        'financials/receipts/',
        data: voucher.toJson(),
      );
      return ReceiptVoucher.fromJson(response.data);
    } catch (e) {
      print('Error creating receipt voucher: $e');
      rethrow;
    }
  }

  /// Get all receipt vouchers for an order
  Future<List<ReceiptVoucher>> getReceiptVouchersByOrder(int orderId) async {
    try {
      final response = await _apiClient.get(
        'financials/receipts/',
        queryParameters: {'order': orderId},
      );

      // Handle paginated response
      if (response.data is Map && response.data['results'] != null) {
        final results = response.data['results'] as List;
        return results.map((json) => ReceiptVoucher.fromJson(json)).toList();
      }

      // Handle direct list response (non-paginated)
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ReceiptVoucher.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error fetching receipt vouchers: $e');
      rethrow;
    }
  }

  /// Get a single receipt voucher by ID
  Future<ReceiptVoucher> getReceiptVoucherById(int id) async {
    try {
      final response = await _apiClient.get('financials/receipts/$id/');
      return ReceiptVoucher.fromJson(response.data);
    } catch (e) {
      print('Error fetching receipt voucher: $e');
      rethrow;
    }
  }

  /// Delete a receipt voucher
  Future<void> deleteReceiptVoucher(int id) async {
    try {
      await _apiClient.delete('financials/receipts/$id/');
    } catch (e) {
      print('Error deleting receipt voucher: $e');
      rethrow;
    }
  }

  /// Get unadjusted receipt vouchers (not yet applied to invoices)
  Future<List<ReceiptVoucher>> getUnadjustedReceiptVouchers() async {
    try {
      final response = await _apiClient.get('financials/receipts/unadjusted/');

      // Handle paginated response
      if (response.data is Map && response.data['results'] != null) {
        final results = response.data['results'] as List;
        return results.map((json) => ReceiptVoucher.fromJson(json)).toList();
      }

      // Handle direct list response
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ReceiptVoucher.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching unadjusted receipts: $e');
      rethrow;
    }
  }

  // ==================== REFUND VOUCHERS ====================

  /// Create a new refund voucher
  Future<RefundVoucher> createRefundVoucher(RefundVoucher refund) async {
    try {
      final response = await _apiClient.post(
        'financials/refunds/',
        data: refund.toJson(),
      );
      return RefundVoucher.fromJson(response.data);
    } catch (e) {
      print('Error creating refund voucher: $e');
      rethrow;
    }
  }

  /// Get all refund vouchers for a receipt voucher
  Future<List<RefundVoucher>> getRefundVouchersByReceipt(
    int receiptVoucherId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/refunds/',
        queryParameters: {'receipt_voucher': receiptVoucherId},
      );

      // Handle paginated response
      if (response.data is Map && response.data['results'] != null) {
        final results = response.data['results'] as List;
        return results.map((json) => RefundVoucher.fromJson(json)).toList();
      }

      // Handle direct list response
      if (response.data is List) {
        return (response.data as List)
            .map((json) => RefundVoucher.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching refund vouchers: $e');
      rethrow;
    }
  }

  /// Get all refund vouchers for a customer
  Future<List<RefundVoucher>> getRefundVouchersByCustomer(
    int customerId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/refunds/',
        queryParameters: {'customer': customerId},
      );

      // Handle paginated response
      if (response.data is Map && response.data['results'] != null) {
        final results = response.data['results'] as List;
        return results.map((json) => RefundVoucher.fromJson(json)).toList();
      }

      // Handle direct list response
      if (response.data is List) {
        return (response.data as List)
            .map((json) => RefundVoucher.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching refund vouchers: $e');
      rethrow;
    }
  }

  /// Get a single refund voucher by ID
  Future<RefundVoucher> getRefundVoucherById(int id) async {
    try {
      final response = await _apiClient.get('financials/refunds/$id/');
      return RefundVoucher.fromJson(response.data);
    } catch (e) {
      print('Error fetching refund voucher: $e');
      rethrow;
    }
  }
}
