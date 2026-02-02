import 'package:flutter/foundation.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

/// Invoice Provider
/// Manages Invoice state and business logic
class InvoiceProvider with ChangeNotifier {
  final InvoiceService _invoiceService;

  InvoiceProvider({InvoiceService? invoiceService})
    : _invoiceService = invoiceService ?? InvoiceService();

  // State
  List<Invoice> _invoices = [];
  Invoice? _currentInvoice;
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String? _searchQuery;
  String? _statusFilter;
  String? _filterPaymentStatus;
  String? _filterTaxType;
  int? _filterCustomerId;
  int? _filterOrderId;

  // Getters
  List<Invoice> get invoices => _invoices;
  Invoice? get currentInvoice => _currentInvoice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get filterPaymentStatus => _filterPaymentStatus;
  String? get filterTaxType => _filterTaxType;
  int? get filterCustomerId => _filterCustomerId;
  int? get filterOrderId => _filterOrderId;

  // Filtered invoices
  List<Invoice> get filteredInvoices {
    return _invoices.where((invoice) {
      // Search filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        final matchesNumber = invoice.invoiceNumber.toLowerCase().contains(
          query,
        );
        final matchesCustomer =
            invoice.customerName?.toLowerCase().contains(query) ?? false;
        final matchesPhone =
            invoice.customerPhone?.toLowerCase().contains(query) ?? false;
        if (!matchesNumber && !matchesCustomer && !matchesPhone) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != null && invoice.status != _statusFilter) {
        return false;
      }

      // Payment status filter
      if (_filterPaymentStatus != null &&
          invoice.paymentStatus != _filterPaymentStatus) {
        return false;
      }

      // Tax type filter
      if (_filterTaxType != null && invoice.taxType != _filterTaxType) {
        return false;
      }

      // Customer filter
      if (_filterCustomerId != null && invoice.customer != _filterCustomerId) {
        return false;
      }

      // Order filter
      if (_filterOrderId != null && invoice.order != _filterOrderId) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Fetch all invoices
  Future<void> fetchInvoices({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoices = await _invoiceService.fetchInvoices(
        search: _searchQuery,
        status: _statusFilter,
        paymentStatus: _filterPaymentStatus,
        taxType: _filterTaxType,
        customerId: _filterCustomerId,
        orderId: _filterOrderId,
      );
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to fetch invoices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch invoice by ID
  Future<Invoice?> fetchInvoiceById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentInvoice = await _invoiceService.fetchInvoiceById(id);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return _currentInvoice;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to fetch invoice: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Create new invoice
  Future<Invoice?> createInvoice(Invoice invoice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdInvoice = await _invoiceService.createInvoice(invoice);
      _invoices.insert(0, createdInvoice);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return createdInvoice;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to create invoice: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update existing invoice (for drafts)
  Future<Invoice?> updateInvoice(int id, Invoice invoice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedInvoice = await _invoiceService.updateInvoice(id, invoice);
      final index = _invoices.indexWhere((inv) => inv.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return updatedInvoice;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to update invoice: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Issue invoice (DRAFT → ISSUED)
  Future<bool> issueInvoice(int id) async {
    try {
      final issuedInvoice = await _invoiceService.issueInvoice(id);
      final index = _invoices.indexWhere((inv) => inv.id == id);
      if (index != -1) {
        _invoices[index] = issuedInvoice;
      }
      if (_currentInvoice?.id == id) {
        _currentInvoice = issuedInvoice;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to issue invoice: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cancel invoice
  Future<bool> cancelInvoice(int id, {String? reason}) async {
    try {
      final cancelledInvoice = await _invoiceService.cancelInvoice(
        id,
        reason: reason,
      );
      final index = _invoices.indexWhere((inv) => inv.id == id);
      if (index != -1) {
        _invoices[index] = cancelledInvoice;
      }
      if (_currentInvoice?.id == id) {
        _currentInvoice = cancelledInvoice;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to cancel invoice: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete invoice
  Future<bool> deleteInvoice(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _invoiceService.deleteInvoice(id);
      _invoices.removeWhere((invoice) => invoice.id == id);
      if (_currentInvoice?.id == id) {
        _currentInvoice = null;
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete invoice: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get unpaid invoices
  Future<void> fetchUnpaidInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoices = await _invoiceService.getUnpaidInvoices();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to fetch unpaid invoices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== FILTER METHODS ====================

  /// Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Set payment status filter
  void setFilterPaymentStatus(String? status) {
    _filterPaymentStatus = status;
    notifyListeners();
  }

  /// Set tax type filter
  void setFilterTaxType(String? taxType) {
    _filterTaxType = taxType;
    notifyListeners();
  }

  /// Set customer filter
  void setFilterCustomerId(int? customerId) {
    _filterCustomerId = customerId;
    notifyListeners();
  }

  /// Set order filter
  void setFilterOrderId(int? orderId) {
    _filterOrderId = orderId;
    notifyListeners();
  }

  /// Clear customer filter
  void clearCustomerFilter() {
    _filterCustomerId = null;
    notifyListeners();
  }

  /// Clear order filter
  void clearOrderFilter() {
    _filterOrderId = null;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = null;
    _statusFilter = null;
    _filterPaymentStatus = null;
    _filterTaxType = null;
    _filterCustomerId = null;
    _filterOrderId = null;
    notifyListeners();
  }

  /// Refresh invoices
  Future<void> refresh() async {
    await fetchInvoices(refresh: true);
  }

  /// Clear current invoice
  void clearCurrentInvoice() {
    _currentInvoice = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
