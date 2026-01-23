import 'package:tailoring_web/core/api/api_client.dart';
import '../models/receipt_voucher.dart';
import '../models/refund_voucher.dart';
import '../models/invoice_payment.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  // ==================== RECEIPT VOUCHERS (Advances) ====================

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

  // ==================== INVOICE PAYMENTS ====================

  /// Create a new payment against invoice
  Future<InvoicePayment> createInvoicePayment(InvoicePayment payment) async {
    try {
      final response = await _apiClient.post(
        'financials/payments/',
        data: payment.toJson(),
      );
      return InvoicePayment.fromJson(response.data);
    } catch (e) {
      print('Error creating invoice payment: $e');
      rethrow;
    }
  }

  /// Get all payments for an invoice
  Future<List<InvoicePayment>> getInvoicePaymentsByInvoice(
    int invoiceId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/payments/',
        queryParameters: {'invoice': invoiceId},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => InvoicePayment.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching invoice payments: $e');
      rethrow;
    }
  }

  /// Get all payments for an order (via invoices)
  Future<List<InvoicePayment>> getInvoicePaymentsByOrder(int orderId) async {
    try {
      final response = await _apiClient.get(
        'financials/payments/',
        queryParameters: {'invoice__order': orderId},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => InvoicePayment.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching invoice payments by order: $e');
      rethrow;
    }
  }

  /// Get a single payment by ID
  Future<InvoicePayment> getInvoicePaymentById(int id) async {
    try {
      final response = await _apiClient.get('financials/payments/$id/');
      return InvoicePayment.fromJson(response.data);
    } catch (e) {
      print('Error fetching invoice payment: $e');
      rethrow;
    }
  }

  /// Delete a payment
  Future<void> deleteInvoicePayment(int id) async {
    try {
      await _apiClient.delete('financials/payments/$id/');
    } catch (e) {
      print('Error deleting invoice payment: $e');
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
