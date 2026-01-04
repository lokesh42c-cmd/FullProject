import 'package:flutter/material.dart';
import 'package:tailoring_web/features/purchase_management/models/expense.dart';
import 'package:tailoring_web/features/purchase_management/models/payment.dart';
import 'package:tailoring_web/features/purchase_management/services/purchase_api_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PurchaseApiService _apiService;
  PaymentProvider(this._apiService);

  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterType = 'ALL'; // ALL, PURCHASE_BILL, EXPENSE
  String _filterMethod = 'ALL'; // ALL, CASH, UPI, etc.
  int _totalCount = 0;
  int _currentPage = 1;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get filterType => _filterType;
  String get filterMethod => _filterMethod;
  int get totalCount => _totalCount;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchPayments(refresh: true);
  }

  void setFilterType(String type) {
    _filterType = type;
    _currentPage = 1;
    fetchPayments(refresh: true);
  }

  void setFilterMethod(String method) {
    _filterMethod = method;
    _currentPage = 1;
    fetchPayments(refresh: true);
  }

  Future<void> fetchPayments({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _payments = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getPayments(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        paymentType: _filterType != 'ALL' ? _filterType : null,
        paymentMethod: _filterMethod != 'ALL' ? _filterMethod : null,
        ordering: '-payment_date',
        page: _currentPage,
      );

      _totalCount = response['count'] as int;
      final List<Payment> fetchedPayments =
          response['results'] as List<Payment>;

      if (refresh) {
        _payments = fetchedPayments;
      } else {
        _payments.addAll(fetchedPayments);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPayment(Payment payment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.createPayment(payment);
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchPayments(refresh: true);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePayment(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletePayment(id);
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchPayments(refresh: true);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void refresh() {
    fetchPayments(refresh: true);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper to get today's total
  double getTodayTotal() {
    final today = DateTime.now();
    return _payments
        .where(
          (p) =>
              p.paymentDate.year == today.year &&
              p.paymentDate.month == today.month &&
              p.paymentDate.day == today.day,
        )
        .fold(0.0, (sum, p) => sum + p.amountDouble);
  }

  // Helper to get total by method
  Map<String, double> getTotalsByMethod() {
    final totals = <String, double>{};
    for (var payment in _payments) {
      totals[payment.paymentMethod] =
          (totals[payment.paymentMethod] ?? 0.0) + payment.amountDouble;
    }
    return totals;
  }
}
