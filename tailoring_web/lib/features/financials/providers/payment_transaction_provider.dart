import 'package:flutter/foundation.dart';
import 'package:tailoring_web/features/financials/models/payment_transaction.dart';
import 'package:tailoring_web/features/financials/services/payment_transaction_service.dart';

class PaymentTransactionProvider with ChangeNotifier {
  final PaymentTransactionService _service;
  PaymentTransactionProvider(this._service);

  List<PaymentTransaction> _transactions = [];
  PaymentTransactionSummary? _summary;
  bool _isLoading = false;
  String? _error;

  String? _selectedPaymentMode;
  String? _selectedTransactionType;
  String? _dateFrom;
  String? _dateTo;
  bool _showCashInHandOnly = false;
  String _searchQuery = '';

  List<PaymentTransaction> get transactions => _transactions;
  PaymentTransactionSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showCashInHandOnly => _showCashInHandOnly;

  Future<void> loadTransactions({bool forceRefresh = false}) async {
    if (_transactions.isNotEmpty && !forceRefresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _service.getAllTransactions(
        paymentMode: _selectedPaymentMode,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        cashInHandOnly: _showCashInHandOnly,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (_selectedTransactionType != null) {
        _transactions = _transactions.where((txn) {
          if (_selectedTransactionType == 'RECEIPT_VOUCHER')
            return txn.transactionType == PaymentTransactionType.receiptVoucher;
          if (_selectedTransactionType == 'INVOICE_PAYMENT')
            return txn.transactionType == PaymentTransactionType.invoicePayment;
          if (_selectedTransactionType == 'REFUND')
            return txn.transactionType == PaymentTransactionType.refund;
          return true;
        }).toList();
      }

      _summary = PaymentTransactionSummary.calculate(_transactions);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NEW: Trigger update and refresh list
  Future<bool> updateDepositStatus(int id, PaymentTransactionType type) async {
    try {
      final category = type == PaymentTransactionType.invoicePayment
          ? 'payments'
          : 'receipts';
      await _service.updateDepositStatus(id, category, true);
      await loadTransactions(forceRefresh: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  void setCashInHandFilter(bool show) {
    _showCashInHandOnly = show;
    loadTransactions(forceRefresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadTransactions(forceRefresh: true);
  }
}
