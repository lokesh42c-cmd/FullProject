import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/financials/models/payment_transaction.dart';

class PaymentTransactionService {
  final ApiClient _apiClient;

  PaymentTransactionService(this._apiClient);

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

      final receiptsRes = await _apiClient.get(
        'financials/receipts/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> receiptData = receiptsRes.data['results'] ?? [];
      for (var json in receiptData) {
        allTransactions.add(PaymentTransaction.fromReceiptVoucher(json));
      }

      final paymentsRes = await _apiClient.get(
        'financials/payments/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> paymentData = paymentsRes.data['results'] ?? [];
      for (var json in paymentData) {
        allTransactions.add(PaymentTransaction.fromInvoicePayment(json));
      }

      final refundsRes = await _apiClient.get(
        'financials/refunds/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> refundData = refundsRes.data['results'] ?? [];
      for (var json in refundData) {
        allTransactions.add(PaymentTransaction.fromRefundVoucher(json));
      }

      allTransactions.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );
      return allTransactions;
    } catch (e) {
      throw Exception('Failed to load all transactions: $e');
    }
  }

  /// NEW: Update deposit status on the backend
  Future<void> updateDepositStatus(
    int id,
    String category,
    bool isDeposited,
  ) async {
    await _apiClient.patch(
      'financials/$category/$id/',
      data: {'deposited_to_bank': isDeposited},
    );
  }

  Future<List<PaymentTransaction>> getCashNotDeposited() async {
    try {
      final allTransactions = <PaymentTransaction>[];
      final rRes = await _apiClient.get(
        'financials/receipts/cash_not_deposited/',
      );
      for (var json in (rRes.data ?? [])) {
        allTransactions.add(PaymentTransaction.fromReceiptVoucher(json));
      }
      final pRes = await _apiClient.get(
        'financials/payments/cash_not_deposited/',
      );
      for (var json in (pRes.data ?? [])) {
        allTransactions.add(PaymentTransaction.fromInvoicePayment(json));
      }
      return allTransactions;
    } catch (e) {
      throw Exception('Failed to load undeposited cash: $e');
    }
  }
}
