import 'package:flutter/foundation.dart';
import 'package:tailoring_web/core/api/api_client.dart';

/// Invoice Provider - State Management for Invoices
class InvoiceProvider with ChangeNotifier {
  final ApiClient _apiClient;

  InvoiceProvider(this._apiClient);

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _invoices = [];
  int _totalCount = 0;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 20;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  String get statusFilter => _statusFilter;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get invoices => _invoices;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get searchQuery => _searchQuery;

  int get totalPages => (_totalCount / _pageSize).ceil();

  /// Fetch invoices from API
  Future<void> fetchInvoices({bool refresh = false}) async {
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

      if (_statusFilter != 'ALL') {
        params['status'] = _statusFilter;
      }

      final response = await _apiClient.get(
        'invoicing/invoices/', // Standard endpoint for invoices
        queryParameters: params,
      );

      _totalCount = response.data['count'] ?? 0;
      _invoices = response.data['results'] as List;

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch invoices';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchInvoices(refresh: true);
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    fetchInvoices(refresh: true);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchInvoices(refresh: true);
  }
}
