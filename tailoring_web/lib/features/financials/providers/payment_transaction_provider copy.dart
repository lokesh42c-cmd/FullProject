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

  // Filter States
  String? _selectedPaymentMode;
  String? _selectedTransactionType;
  String? _dateFrom;
  String? _dateTo;
  bool _showCashInHandOnly = false;
  String _searchQuery = '';

  // Public Getters for UI
  List<PaymentTransaction> get transactions => _transactions;
  PaymentTransactionSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedPaymentMode => _selectedPaymentMode;
  String? get selectedTransactionType => _selectedTransactionType;
  String? get dateFrom => _dateFrom;
  String? get dateTo => _dateTo;
  bool get showCashInHandOnly => _showCashInHandOnly;
  String get searchQuery => _searchQuery;

  /// Load transactions with RAM persistence
  Future<void> loadTransactions({bool forceRefresh = false}) async {
    // PERSISTENCE: If we have data and aren't forcing a refresh, keep the RAM data
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

      // Local UI Filtering for Transaction Type
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

  // --- Filter Setters (Each triggers a fresh fetch) ---

  void setPaymentModeFilter(String? mode) {
    _selectedPaymentMode = mode;
    loadTransactions(forceRefresh: true);
  }

  void setTransactionTypeFilter(String? type) {
    _selectedTransactionType = type;
    loadTransactions(forceRefresh: true);
  }

  void setDateRange(String? from, String? to) {
    _dateFrom = from;
    _dateTo = to;
    loadTransactions(forceRefresh: true);
  }

  void setCashInHandFilter(bool show) {
    _showCashInHandOnly = show;
    loadTransactions(forceRefresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadTransactions(forceRefresh: true);
  }

  void clearFilters() {
    _selectedPaymentMode = null;
    _selectedTransactionType = null;
    _dateFrom = null;
    _dateTo = null;
    _showCashInHandOnly = false;
    _searchQuery = '';
    loadTransactions(forceRefresh: true);
  }
}
