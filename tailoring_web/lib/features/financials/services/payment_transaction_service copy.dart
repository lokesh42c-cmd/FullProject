import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/financials/models/payment_transaction.dart';

class PaymentTransactionService {
  final ApiClient _apiClient;

  PaymentTransactionService(this._apiClient);

  /// Fetches all 3 types and merges them into one list in RAM
  Future<List<PaymentTransaction>> getAllTransactions({
    String? paymentMode,
    String? dateFrom,
    String? dateTo,
    bool? cashInHandOnly,
    String? search,
  }) async {
    try {
      final allTransactions = <PaymentTransaction>[];
      final queryParams = <String, dynamic>{};

      if (paymentMode != null) queryParams['payment_mode'] = paymentMode;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      // 1. Fetch Receipts (Advance Payments) - Path fixed to 'receipts/'
      final receiptsRes = await _apiClient.get(
        'financials/receipts/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> receiptData = receiptsRes.data['results'] ?? [];
      for (var json in receiptData) {
        allTransactions.add(PaymentTransaction.fromReceiptVoucher(json));
      }

      // 2. Fetch Invoice Payments - Path 'payments/'
      final paymentsRes = await _apiClient.get(
        'financials/payments/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> paymentData = paymentsRes.data['results'] ?? [];
      for (var json in paymentData) {
        allTransactions.add(PaymentTransaction.fromInvoicePayment(json));
      }

      // 3. Fetch Refunds - Path fixed to 'refunds/'
      final refundsRes = await _apiClient.get(
        'financials/refunds/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> refundData = refundsRes.data['results'] ?? [];
      for (var json in refundData) {
        allTransactions.add(PaymentTransaction.fromRefundVoucher(json));
      }

      // Sort combined list by date descending
      allTransactions.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );

      return allTransactions;
    } catch (e) {
      throw Exception('Failed to load all transactions: $e');
    }
  }

  /// Required for the Cash-in-hand feature
  Future<List<PaymentTransaction>> getCashNotDeposited() async {
    try {
      final allTransactions = <PaymentTransaction>[];

      final rRes = await _apiClient.get(
        'financials/receipts/cash_not_deposited/',
      );
      final List<dynamic> rData = rRes.data ?? [];
      for (var json in rData) {
        allTransactions.add(PaymentTransaction.fromReceiptVoucher(json));
      }

      final pRes = await _apiClient.get(
        'financials/payments/cash_not_deposited/',
      );
      final List<dynamic> pData = pRes.data ?? [];
      for (var json in pData) {
        allTransactions.add(PaymentTransaction.fromInvoicePayment(json));
      }

      return allTransactions;
    } catch (e) {
      throw Exception('Failed to load undeposited cash: $e');
    }
  }
}
