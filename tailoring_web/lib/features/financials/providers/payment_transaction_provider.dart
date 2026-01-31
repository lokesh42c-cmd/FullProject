import 'package:flutter/foundation.dart';
import '../models/payment_transaction.dart';
import '../services/payment_transaction_service.dart';

class PaymentTransactionProvider with ChangeNotifier {
  final PaymentTransactionService _service;
  PaymentTransactionProvider(this._service);

  List<PaymentTransaction> _allTransactions = [];
  List<PaymentTransaction> _filteredTransactions = [];
  PaymentTransactionSummary? _summary;
  bool _isLoading = false;

  // Filter States
  bool _showCashInHandOnly = false;
  String _searchQuery = '';

  List<PaymentTransaction> get transactions => _filteredTransactions;
  PaymentTransactionSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  bool get showCashInHandOnly => _showCashInHandOnly;

  Future<void> loadTransactions({bool forceRefresh = false}) async {
    if (_allTransactions.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allTransactions = await _service.getTransactions();
      _applyFiltersAndCalculate();
    } catch (e) {
      debugPrint('Provider Load Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFiltersAndCalculate() {
    _filteredTransactions = _allTransactions.where((txn) {
      final matchesSearch =
          txn.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          txn.transactionNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesCashFilter =
          !_showCashInHandOnly ||
          (txn.paymentMode == 'CASH' && !txn.depositedToBank);

      return matchesSearch && matchesCashFilter;
    }).toList();

    _summary = PaymentTransactionSummary.calculate(_filteredTransactions);
  }

  void setCashInHandFilter(bool show) {
    _showCashInHandOnly = show;
    _applyFiltersAndCalculate();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndCalculate();
    notifyListeners();
  }

  Future<bool> updateDepositStatus(int id, PaymentTransactionType type) async {
    _isLoading = true;
    notifyListeners();
    try {
      final String category = type == PaymentTransactionType.invoicePayment
          ? 'payments'
          : 'receipts';
      await _service.updateDepositStatus(id, category, true);
      await loadTransactions(forceRefresh: true);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
