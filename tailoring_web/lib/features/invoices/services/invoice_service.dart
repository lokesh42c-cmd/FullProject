import 'package:tailoring_web/core/api/api_client.dart';
import '../models/invoice.dart';

/// Invoice Service
/// Handles all invoice-related API calls
class InvoiceService {
  final ApiClient _apiClient;

  InvoiceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetch all invoices with optional filters
  Future<List<Invoice>> fetchInvoices({
    String? search,
    String? status,
    String? paymentStatus,
    String? taxType,
    int? customerId,
    int? orderId,
  }) async {
    // Build query parameters
    final Map<String, dynamic> queryParams = {};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParams['payment_status'] = paymentStatus;
    }
    if (taxType != null && taxType.isNotEmpty) {
      queryParams['tax_type'] = taxType;
    }
    if (customerId != null) {
      queryParams['customer'] = customerId.toString();
    }
    if (orderId != null) {
      queryParams['order'] = orderId.toString();
    }

    final response = await _apiClient.get(
      'invoicing/invoices/',
      queryParameters: queryParams,
    );

    // ✅ Fixed for Pagination: Extract the list from the 'results' key
    // The API response is now a Map containing metadata, not a direct List
    final List<dynamic> data = response.data['results'] as List<dynamic>;
    return data.map((json) => Invoice.fromJson(json)).toList();
  }

  /// Fetch single invoice by ID
  Future<Invoice> fetchInvoiceById(int id) async {
    final response = await _apiClient.get('invoicing/invoices/$id/');
    return Invoice.fromJson(response.data);
  }

  /// Create new invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    final response = await _apiClient.post(
      'invoicing/invoices/',
      data: invoice.toJson(),
    );
    return Invoice.fromJson(response.data);
  }

  /// Update existing invoice (for drafts)
  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    final response = await _apiClient.put(
      'invoicing/invoices/$id/',
      data: invoice.toJson(),
    );
    return Invoice.fromJson(response.data);
  }

  /// Partial update invoice
  Future<Invoice> partialUpdateInvoice(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      'invoicing/invoices/$id/',
      data: data,
    );
    return Invoice.fromJson(response.data);
  }

  /// Issue invoice (DRAFT → ISSUED)
  Future<Invoice> issueInvoice(int id) async {
    final response = await _apiClient.post(
      'invoicing/invoices/$id/issue/',
      data: {},
    );
    return Invoice.fromJson(response.data);
  }

  /// Cancel invoice
  Future<Invoice> cancelInvoice(int id, {String? reason}) async {
    final response = await _apiClient.post(
      'invoicing/invoices/$id/cancel/',
      data: reason != null ? {'reason': reason} : {},
    );
    return Invoice.fromJson(response.data);
  }

  /// Get unpaid invoices
  Future<List<Invoice>> getUnpaidInvoices() async {
    final response = await _apiClient.get('invoicing/invoices/unpaid/');

    // ✅ Fixed for Pagination: Extract the list from the 'results' key
    final List<dynamic> data = response.data['results'] as List<dynamic>;
    return data.map((json) => Invoice.fromJson(json)).toList();
  }

  /// Delete invoice (if allowed)
  Future<void> deleteInvoice(int id) async {
    await _apiClient.delete('invoicing/invoices/$id/');
  }
}
