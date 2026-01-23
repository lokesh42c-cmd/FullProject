import 'package:tailoring_web/core/api/api_client.dart';
import '../models/invoice.dart';

class InvoiceService {
  final ApiClient _apiClient = ApiClient();

  // ==================== INVOICES ====================

  /// Get all invoices
  Future<List<Invoice>> getAllInvoices() async {
    try {
      final response = await _apiClient.get('invoices/invoices/');

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Invoice.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching invoices: $e');
      rethrow;
    }
  }

  /// Create a new invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final response = await _apiClient.post(
        'invoices/invoices/',
        data: invoice.toJson(),
      );
      return Invoice.fromJson(response.data);
    } catch (e) {
      print('Error creating invoice: $e');
      rethrow;
    }
  }

  /// Get invoice by ID
  Future<Invoice> getInvoiceById(int id) async {
    try {
      final response = await _apiClient.get('invoices/invoices/$id/');
      return Invoice.fromJson(response.data);
    } catch (e) {
      print('Error fetching invoice: $e');
      rethrow;
    }
  }

  /// Get all invoices for an order
  Future<List<Invoice>> getInvoicesByOrder(int orderId) async {
    try {
      final response = await _apiClient.get(
        'invoices/invoices/',
        queryParameters: {'order': orderId},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Invoice.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching invoices by order: $e');
      rethrow;
    }
  }

  /// Get all invoices for a customer
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    try {
      final response = await _apiClient.get(
        'invoices/invoices/',
        queryParameters: {'customer': customerId},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Invoice.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching invoices by customer: $e');
      rethrow;
    }
  }

  /// Get all unpaid/partially paid invoices
  Future<List<Invoice>> getUnpaidInvoices() async {
    try {
      final response = await _apiClient.get('invoices/invoices/unpaid/');

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Invoice.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching unpaid invoices: $e');
      rethrow;
    }
  }

  /// Update invoice
  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    try {
      final response = await _apiClient.patch(
        'invoices/invoices/$id/',
        data: invoice.toJson(),
      );
      return Invoice.fromJson(response.data);
    } catch (e) {
      print('Error updating invoice: $e');
      rethrow;
    }
  }

  /// Issue invoice (DRAFT → ISSUED)
  Future<Invoice> issueInvoice(int id) async {
    try {
      final response = await _apiClient.post('invoices/invoices/$id/issue/');
      // Fetch updated invoice
      return await getInvoiceById(id);
    } catch (e) {
      print('Error issuing invoice: $e');
      rethrow;
    }
  }

  /// Cancel invoice
  Future<Invoice> cancelInvoice(int id) async {
    try {
      final response = await _apiClient.post('invoices/invoices/$id/cancel/');
      // Fetch updated invoice
      return await getInvoiceById(id);
    } catch (e) {
      print('Error cancelling invoice: $e');
      rethrow;
    }
  }

  /// Delete invoice
  Future<void> deleteInvoice(int id) async {
    try {
      await _apiClient.delete('invoices/invoices/$id/');
    } catch (e) {
      print('Error deleting invoice: $e');
      rethrow;
    }
  }
}
