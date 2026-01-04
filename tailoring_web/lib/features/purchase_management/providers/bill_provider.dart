import 'package:flutter/material.dart';
import 'package:tailoring_web/features/purchase_management/models/vendor.dart';
import 'package:tailoring_web/features/purchase_management/models/payment.dart';
import 'package:tailoring_web/features/purchase_management/models/purchase_bill.dart';
import 'package:tailoring_web/features/purchase_management/services/purchase_api_service.dart';

class BillProvider extends ChangeNotifier {
  final PurchaseApiService _apiService;

  BillProvider(this._apiService);

  List<PurchaseBill> _bills = [];
  PurchaseBill? _currentBill;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterStatus = 'ALL';
  int? _filterVendor;
  int _totalCount = 0;
  int _currentPage = 1;

  List<PurchaseBill> get bills => _bills;
  PurchaseBill? get currentBill => _currentBill;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  int? get filterVendor => _filterVendor;
  int get totalCount => _totalCount;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchBills(refresh: true);
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _currentPage = 1;
    fetchBills(refresh: true);
  }

  void setFilterVendor(int? vendorId) {
    _filterVendor = vendorId;
    _currentPage = 1;
    fetchBills(refresh: true);
  }

  Future<void> fetchBills({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _bills = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getBills(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        vendor: _filterVendor,
        paymentStatus: _filterStatus != 'ALL' ? _filterStatus : null,
        ordering: '-bill_date',
        page: _currentPage,
      );

      _totalCount = response['count'] as int;
      final List<PurchaseBill> fetchedBills =
          response['results'] as List<PurchaseBill>;

      if (refresh) {
        _bills = fetchedBills;
      } else {
        _bills.addAll(fetchedBills);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseBill> getBillById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentBill = await _apiService.getBill(id);
      _isLoading = false;
      notifyListeners();
      return _currentBill!;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Payment>> getBillPayments(int billId) async {
    try {
      return await _apiService.getBillPayments(billId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<int?> createBill(PurchaseBill bill) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createBill(bill);
      _isLoading = false;
      notifyListeners();
      await fetchBills(refresh: true);
      return created.id;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateBill(int id, PurchaseBill bill) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateBill(id, bill);
      _currentBill = updated;
      _isLoading = false;
      notifyListeners();
      await fetchBills(refresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBill(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteBill(id);
      _isLoading = false;
      notifyListeners();
      await fetchBills(refresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void refresh() {
    fetchBills(refresh: true);
  }

  void clearCurrentBill() {
    _currentBill = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
