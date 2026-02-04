import 'package:tailoring_web/core/api/api_client.dart';
import '../models/receipt_voucher.dart';
import '../models/refund_voucher.dart';
import '../models/invoice_payment.dart';
import '../models/payment_refund.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  // ==================== RECEIPT VOUCHERS (Advances) ====================

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

  Future<List<ReceiptVoucher>> getReceiptVouchersByOrder(int orderId) async {
    try {
      final response = await _apiClient.get(
        'financials/receipts/',
        queryParameters: {'order': orderId},
      );
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => ReceiptVoucher.fromJson(json))
            .toList();
      }
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

  Future<ReceiptVoucher> getReceiptVoucherById(int id) async {
    try {
      final response = await _apiClient.get('financials/receipts/$id/');
      return ReceiptVoucher.fromJson(response.data);
    } catch (e) {
      print('Error fetching receipt voucher: $e');
      rethrow;
    }
  }

  Future<void> deleteReceiptVoucher(int id) async {
    try {
      await _apiClient.delete('financials/receipts/$id/');
    } catch (e) {
      print('Error deleting receipt voucher: $e');
      rethrow;
    }
  }

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

  Future<List<InvoicePayment>> getInvoicePaymentsByInvoice(
    int invoiceId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/payments/',
        queryParameters: {'invoice': invoiceId},
      );
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => InvoicePayment.fromJson(json))
            .toList();
      }
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

  Future<List<InvoicePayment>> getInvoicePaymentsByOrder(int orderId) async {
    try {
      final response = await _apiClient.get(
        'financials/payments/',
        queryParameters: {'invoice__order': orderId},
      );
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => InvoicePayment.fromJson(json))
            .toList();
      }
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

  Future<InvoicePayment> getInvoicePaymentById(int id) async {
    try {
      final response = await _apiClient.get('financials/payments/$id/');
      return InvoicePayment.fromJson(response.data);
    } catch (e) {
      print('Error fetching invoice payment: $e');
      rethrow;
    }
  }

  Future<void> deleteInvoicePayment(int id) async {
    try {
      await _apiClient.delete('financials/payments/$id/');
    } catch (e) {
      print('Error deleting invoice payment: $e');
      rethrow;
    }
  }

  // ==================== REFUND VOUCHERS ====================

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

  Future<List<RefundVoucher>> getRefundVouchersByReceipt(
    int receiptVoucherId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/refunds/',
        queryParameters: {'receipt_voucher': receiptVoucherId},
      );
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => RefundVoucher.fromJson(json))
            .toList();
      }
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

  Future<List<RefundVoucher>> getRefundVouchersByCustomer(
    int customerId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/refunds/',
        queryParameters: {'customer': customerId},
      );
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => RefundVoucher.fromJson(json))
            .toList();
      }
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

  Future<RefundVoucher> getRefundVoucherById(int id) async {
    try {
      final response = await _apiClient.get('financials/refunds/$id/');
      return RefundVoucher.fromJson(response.data);
    } catch (e) {
      print('Error fetching refund voucher: $e');
      rethrow;
    }
  }

  // ==================== PAYMENT REFUNDS (Invoice Payment Refunds) ====================

  Future<PaymentRefund> createPaymentRefund(PaymentRefund refund) async {
    try {
      final response = await _apiClient.post(
        'financials/payment-refunds/',
        data: refund.toJson(),
      );
      return PaymentRefund.fromJson(response.data);
    } catch (e) {
      print('Error creating payment refund: $e');
      rethrow;
    }
  }

  Future<List<PaymentRefund>> getPaymentRefundsByInvoice(int invoiceId) async {
    try {
      final response = await _apiClient.get(
        'financials/payment-refunds/',
        queryParameters: {'invoice_id': invoiceId},
      );
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => PaymentRefund.fromJson(json))
            .toList();
      }
      if (response.data is List) {
        return (response.data as List)
            .map((json) => PaymentRefund.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching payment refunds by invoice: $e');
      rethrow;
    }
  }

  Future<List<PaymentRefund>> getPaymentRefundsByPayment(int paymentId) async {
    try {
      final response = await _apiClient.get(
        'financials/payment-refunds/',
        queryParameters: {'payment_id': paymentId},
      );
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => PaymentRefund.fromJson(json))
            .toList();
      }
      if (response.data is List) {
        return (response.data as List)
            .map((json) => PaymentRefund.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching payment refunds by payment: $e');
      rethrow;
    }
  }

  Future<PaymentRefund> getPaymentRefundById(int id) async {
    try {
      final response = await _apiClient.get('financials/payment-refunds/$id/');
      return PaymentRefund.fromJson(response.data);
    } catch (e) {
      print('Error fetching payment refund: $e');
      rethrow;
    }
  }

  Future<void> deletePaymentRefund(int id) async {
    try {
      await _apiClient.delete('financials/payment-refunds/$id/');
    } catch (e) {
      print('Error deleting payment refund: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPaymentRefundSummaryByInvoice(
    int invoiceId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/payment-refunds/by_invoice/',
        queryParameters: {'invoice_id': invoiceId},
      );
      if (response.data is Map) {
        return {
          'refunds':
              (response.data['refunds'] as List?)
                  ?.map((json) => PaymentRefund.fromJson(json))
                  .toList() ??
              [],
          'total_refunded': response.data['total_refunded'] ?? 0.0,
          'count': response.data['count'] ?? 0,
        };
      }
      return {'refunds': [], 'total_refunded': 0.0, 'count': 0};
    } catch (e) {
      print('Error fetching payment refund summary: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPaymentRefundSummaryByPayment(
    int paymentId,
  ) async {
    try {
      final response = await _apiClient.get(
        'financials/payment-refunds/by_payment/',
        queryParameters: {'payment_id': paymentId},
      );
      if (response.data is Map) {
        return {
          'refunds':
              (response.data['refunds'] as List?)
                  ?.map((json) => PaymentRefund.fromJson(json))
                  .toList() ??
              [],
          'total_refunded': response.data['total_refunded'] ?? 0.0,
          'count': response.data['count'] ?? 0,
        };
      }
      return {'refunds': [], 'total_refunded': 0.0, 'count': 0};
    } catch (e) {
      print('Error fetching payment refund summary: $e');
      rethrow;
    }
  }
}
