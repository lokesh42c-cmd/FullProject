import 'package:tailoring_web/core/api/api_client.dart';
import '../models/payment_transaction.dart';

class PaymentTransactionService {
  final ApiClient _apiClient;

  PaymentTransactionService(this._apiClient);

  Future<List<PaymentTransaction>> getTransactions() async {
    try {
      // Fetching from both registered backend endpoints
      final responses = await Future.wait([
        _apiClient.get('/financials/receipts/'),
        _apiClient.get('/financials/payments/'),
      ]);

      List<PaymentTransaction> allTransactions = [];

      // Parse Receipt Vouchers
      if (responses[0].statusCode == 200) {
        final List data = responses[0].data['results'] ?? [];
        allTransactions.addAll(
          data.map((json) => PaymentTransaction.fromReceiptVoucher(json)),
        );
      }

      // Parse Invoice Payments
      if (responses[1].statusCode == 200) {
        final List data = responses[1].data['results'] ?? [];
        allTransactions.addAll(
          data.map((json) => PaymentTransaction.fromInvoicePayment(json)),
        );
      }

      // Sort combined list by date descending
      allTransactions.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );
      return allTransactions;
    } catch (e) {
      throw Exception('Failed to load transaction data: $e');
    }
  }

  Future<void> updateDepositStatus(
    int id,
    String category,
    bool isDeposited,
  ) async {
    // category will be 'receipts' or 'payments' as per backend URLs
    final response = await _apiClient.patch(
      '/financials/$category/$id/',
      data: {'deposited_to_bank': isDeposited},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update deposit status');
    }
  }
}
