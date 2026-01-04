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

  // --- FIXED CALCULATION LOGIC ---

  /// Sum of actual payments (excluding refunds)
  double get totalPaid =>
      _payments.where((p) => !p.isRefund).fold(0.0, (sum, p) => sum + p.amount);

  /// Sum of refund transactions (as a positive number)
  double get totalRefunded => _payments
      .where((p) => p.isRefund)
      .fold(0.0, (sum, p) => sum + p.amount.abs());

  /// Net money actually kept (Actual Paid - Refunded)
  double get netCollected => totalPaid - totalRefunded;

  /// REQUIRED BY UI: This resolves your 'totalAmount' getter error
  double get totalAmount => netCollected;

  /// Balance remaining logic: (Order Total) - (Net Collected)
  double get balance {
    if (_summary != null) {
      return _summary!.totalAmount - netCollected;
    }
    return 0.0;
  }

  /// Required for the count shown on the screen
  int get paymentCount => _payments.where((p) => !p.isRefund).length;

  // --- API METHODS (Synchronized with PaymentService) ---

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
    } catch (e) {
      _error = e.toString();
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
      print('❌ Summary Error: $e');
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
      if (_selectedOrderId == orderId) {
        await loadSummary(orderId: orderId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> voidPayment(int id, String reason) async {
    try {
      final voided = await _paymentService.voidPayment(id, reason);
      _payments.insert(0, voided);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
      notifyListeners();
      return false;
    }
  }

  // --- FILTERS & SETTERS ---

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
}
