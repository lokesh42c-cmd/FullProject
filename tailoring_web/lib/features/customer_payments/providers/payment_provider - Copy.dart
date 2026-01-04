import 'package:flutter/foundation.dart';
import 'package:tailoring_web/features/customer_payments/models/payment.dart';
import 'package:tailoring_web/features/customer_payments/services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService;

  PaymentProvider(this._paymentService);

  List<Payment> _payments = [];
  PaymentSummary? _summary;
  bool _isLoading = false;
  String? _error;

  int? _selectedOrderId;
  int? _selectedCustomerId;
  String? _selectedPaymentMethod;
  String? _dateFrom;
  String? _dateTo;
  bool _showCashInHandOnly = false;
  String? _refundsFilter;
  String _searchQuery = '';

  List<Payment> get payments => _payments;
  PaymentSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int? get selectedOrderId => _selectedOrderId;
  int? get selectedCustomerId => _selectedCustomerId;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get dateFrom => _dateFrom;
  String? get dateTo => _dateTo;
  bool get showCashInHandOnly => _showCashInHandOnly;
  String? get refundsFilter => _refundsFilter;
  String get searchQuery => _searchQuery;

  double get totalAmount =>
      _payments.fold(0.0, (sum, p) => sum + p.amount.abs());
  int get paymentCount => _payments.where((p) => !p.isRefund).length;
  int get refundCount => _payments.where((p) => p.isRefund).length;

  List<Payment> get cashInHandPayments => _payments
      .where(
        (p) => !p.depositedToBank && p.paymentMethod == 'CASH' && !p.isRefund,
      )
      .toList();

  double get cashInHandAmount =>
      cashInHandPayments.fold(0.0, (sum, p) => sum + p.amount);

  Future<void> loadPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _payments = await _paymentService.getPayments(
        orderId: _selectedOrderId,
        customerId: _selectedCustomerId,
        paymentMethod: _selectedPaymentMethod,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        cashInHand: _showCashInHandOnly ? true : null,
        refunds: _refundsFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      print('✅ Loaded ${_payments.length} payments');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSummary({int? orderId}) async {
    try {
      _summary = await _paymentService.getPaymentSummary(orderId: orderId);
      notifyListeners();
    } catch (e) {
      print('❌ Error loading summary: $e');
    }
  }

  Future<bool> createPayment({
    required int orderId,
    required double amount,
    required String paymentMethod,
    DateTime? paymentDate,
    String? referenceNumber,
    String? notes,
    String? bankName,
  }) async {
    try {
      final payment = await _paymentService.createPayment(
        orderId: orderId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: paymentDate,
        referenceNumber: referenceNumber,
        notes: notes,
        bankName: bankName,
      );

      _payments.insert(0, payment);
      notifyListeners();

      if (_selectedOrderId == orderId) {
        await loadSummary(orderId: orderId);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error creating payment: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePayment({
    required int id,
    double? amount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? referenceNumber,
    String? notes,
    String? bankName,
  }) async {
    try {
      final updatedPayment = await _paymentService.updatePayment(
        id,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: paymentDate,
        referenceNumber: referenceNumber,
        notes: notes,
        bankName: bankName,
      );

      final index = _payments.indexWhere((p) => p.id == id);
      if (index != -1) {
        _payments[index] = updatedPayment;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating payment: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> voidPayment(int id, String reason) async {
    try {
      final voidPayment = await _paymentService.voidPayment(id, reason);
      _payments.insert(0, voidPayment);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error voiding payment: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> markDeposited({
    required int id,
    required DateTime depositDate,
    required String depositBankName,
  }) async {
    try {
      final updatedPayment = await _paymentService.markDeposited(
        id: id,
        depositDate: depositDate,
        depositBankName: depositBankName,
      );

      final index = _payments.indexWhere((p) => p.id == id);
      if (index != -1) {
        _payments[index] = updatedPayment;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error marking as deposited: $e');
      notifyListeners();
      return false;
    }
  }

  void setOrderFilter(int? orderId) {
    _selectedOrderId = orderId;
    loadPayments();
  }

  void setCustomerFilter(int? customerId) {
    _selectedCustomerId = customerId;
    loadPayments();
  }

  void setPaymentMethodFilter(String? method) {
    _selectedPaymentMethod = method;
    loadPayments();
  }

  void setDateRange(String? from, String? to) {
    _dateFrom = from;
    _dateTo = to;
    loadPayments();
  }

  void setCashInHandFilter(bool show) {
    _showCashInHandOnly = show;
    loadPayments();
  }

  void setRefundsFilter(String? filter) {
    _refundsFilter = filter;
    loadPayments();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPayments();
  }

  void clearFilters() {
    _selectedOrderId = null;
    _selectedCustomerId = null;
    _selectedPaymentMethod = null;
    _dateFrom = null;
    _dateTo = null;
    _showCashInHandOnly = false;
    _refundsFilter = null;
    _searchQuery = '';
    loadPayments();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    loadPayments();
    if (_selectedOrderId != null) {
      loadSummary(orderId: _selectedOrderId);
    }
  }
}
