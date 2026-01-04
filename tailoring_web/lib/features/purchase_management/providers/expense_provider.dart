import 'package:flutter/material.dart';
import 'package:tailoring_web/features/purchase_management/models/expense.dart';
import 'package:tailoring_web/features/purchase_management/services/purchase_api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final PurchaseApiService _apiService;
  ExpenseProvider(this._apiService);

  List<Expense> _expenses = [];
  Expense? _currentExpense;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterCategory = 'ALL';
  String _filterStatus = 'ALL';
  int _totalCount = 0;
  int _currentPage = 1;

  List<Expense> get expenses => _expenses;
  Expense? get currentExpense => _currentExpense;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get filterCategory => _filterCategory;
  String get filterStatus => _filterStatus;
  int get totalCount => _totalCount;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchExpenses(refresh: true);
  }

  void setFilterCategory(String category) {
    _filterCategory = category;
    _currentPage = 1;
    fetchExpenses(refresh: true);
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _currentPage = 1;
    fetchExpenses(refresh: true);
  }

  Future<void> fetchExpenses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _expenses = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getExpenses(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _filterCategory != 'ALL' ? _filterCategory : null,
        paymentStatus: _filterStatus != 'ALL' ? _filterStatus : null,
        ordering: '-expense_date',
        page: _currentPage,
      );

      _totalCount = response['count'] as int;
      final List<Expense> fetchedExpenses =
          response['results'] as List<Expense>;

      if (refresh) {
        _expenses = fetchedExpenses;
      } else {
        _expenses.addAll(fetchedExpenses);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExpense(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentExpense = await _apiService.getExpense(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> createExpense(Expense expense) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createExpense(expense);
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchExpenses(refresh: true);

      return created.id;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateExpense(int id, Expense expense) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateExpense(id, expense);
      _currentExpense = updated;
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchExpenses(refresh: true);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteExpense(id);
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchExpenses(refresh: true);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void refresh() {
    fetchExpenses(refresh: true);
  }

  void clearCurrentExpense() {
    _currentExpense = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper to get today's total
  double getTodayTotal() {
    final today = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.expenseDate.year == today.year &&
              e.expenseDate.month == today.month &&
              e.expenseDate.day == today.day,
        )
        .fold(0.0, (sum, e) => sum + e.expenseAmountDouble);
  }

  // Helper to get total by category
  Map<String, double> getTotalsByCategory() {
    final totals = <String, double>{};
    for (var expense in _expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0.0) + expense.expenseAmountDouble;
    }
    return totals;
  }
}
