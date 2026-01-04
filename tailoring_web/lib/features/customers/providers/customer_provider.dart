import 'package:flutter/foundation.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';

/// Customer Provider - State Management for Customer List
class CustomerProvider with ChangeNotifier {
  final ApiClient _apiClient;

  CustomerProvider(this._apiClient);

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<Customer> _customers = [];
  int _totalCount = 0;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 20;

  // Search & Filter
  String _searchQuery = '';
  String _filterType = 'ALL'; // ALL, B2C, B2B

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Customer> get customers => _customers;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get searchQuery => _searchQuery;
  String get filterType => _filterType;
  bool get hasSearch => _searchQuery.isNotEmpty;

  int get totalPages => (_totalCount / _pageSize).ceil();

  /// Fetch customers from API with smart search
  Future<void> fetchCustomers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = {
        'page': _currentPage.toString(),
        'page_size': _pageSize.toString(),
      };

      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      if (_filterType != 'ALL') {
        params['customer_type'] = _filterType;
      }

      final response = await _apiClient.get(
        'orders/customers/',
        queryParameters: params,
      );

      _totalCount = response.data['count'] ?? 0;
      final results = response.data['results'] as List;
      _customers = results.map((json) => Customer.fromJson(json)).toList();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch customers';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchCustomers(refresh: true);
  }

  void setFilterType(String type) {
    _filterType = type;
    fetchCustomers(refresh: true);
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchCustomers();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      fetchCustomers();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      fetchCustomers();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchCustomers(refresh: true);
  }
}
