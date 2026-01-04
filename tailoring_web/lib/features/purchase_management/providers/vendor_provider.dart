import 'package:flutter/material.dart';
import 'package:tailoring_web/features/purchase_management/models/vendor.dart';
import 'package:tailoring_web/features/purchase_management/services/purchase_api_service.dart';

class VendorProvider extends ChangeNotifier {
  final PurchaseApiService _apiService;
  VendorProvider(this._apiService);

  List<Vendor> _vendors = [];
  Vendor? _currentVendor;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterActive = 'ALL'; // ALL, ACTIVE, INACTIVE, OUTSTANDING
  int _totalCount = 0;
  int _currentPage = 1;

  List<Vendor> get vendors => _vendors;
  Vendor? get currentVendor => _currentVendor;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get filterActive => _filterActive;
  int get totalCount => _totalCount;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchVendors(refresh: true);
  }

  void setFilterActive(String filter) {
    _filterActive = filter;
    _currentPage = 1;
    fetchVendors(refresh: true);
  }

  Future<void> fetchVendors({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _vendors = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool? isActive;
      if (_filterActive == 'ACTIVE') {
        isActive = true;
      } else if (_filterActive == 'INACTIVE') {
        isActive = false;
      }

      final response = await _apiService.getVendors(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: isActive,
        ordering: '-outstanding_balance',
        page: _currentPage,
      );

      _totalCount = response['count'] as int;
      final List<Vendor> fetchedVendors = response['results'] as List<Vendor>;

      if (refresh) {
        _vendors = fetchedVendors;
      } else {
        _vendors.addAll(fetchedVendors);
      }

      // Special filter for outstanding
      if (_filterActive == 'OUTSTANDING') {
        _vendors = _vendors.where((v) => v.hasBalance).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVendor(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentVendor = await _apiService.getVendor(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> createVendor(Vendor vendor) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdVendor = await _apiService.createVendor(vendor);
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchVendors(refresh: true);

      return createdVendor.id;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateVendor(int id, Vendor vendor) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedVendor = await _apiService.updateVendor(id, vendor);
      _currentVendor = updatedVendor;
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchVendors(refresh: true);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVendor(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteVendor(id);
      _isLoading = false;
      notifyListeners();

      // Refresh list
      await fetchVendors(refresh: true);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void refresh() {
    fetchVendors(refresh: true);
  }

  void clearCurrentVendor() {
    _currentVendor = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
