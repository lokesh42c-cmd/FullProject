import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';

/// Customer API Service
///
/// Handles all customer-related API calls matching Django backend
class CustomerService {
  final ApiClient _apiClient;

  CustomerService(this._apiClient);

  // ==================== CUSTOMER ENDPOINTS ====================

  /// Get paginated list of customers
  Future<CustomerListResponse> getCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? customerType,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (customerType != null && customerType != 'ALL') {
      queryParams['customer_type'] = customerType;
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive;
    }

    final response = await _apiClient.get(
      'orders/customers/',
      queryParameters: queryParams,
    );
    return CustomerListResponse.fromJson(response.data);
  }

  /// Get customer by ID with all details
  Future<Customer> getCustomer(int id) async {
    final response = await _apiClient.get('orders/customers/$id/');
    return Customer.fromJson(response.data);
  }

  /// Create new customer
  Future<Customer> createCustomer(Customer customer) async {
    final response = await _apiClient.post(
      'orders/customers/',
      data: customer.toJson(),
    );
    return Customer.fromJson(response.data);
  }

  /// Update customer (full update)
  Future<Customer> updateCustomer(int id, Customer customer) async {
    final response = await _apiClient.put(
      'orders/customers/$id/',
      data: customer.toJson(),
    );
    return Customer.fromJson(response.data);
  }

  /// Partial update customer (recommended)
  Future<Customer> patchCustomer(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      'orders/customers/$id/',
      data: data,
    );
    return Customer.fromJson(response.data);
  }

  /// Delete customer (soft delete - sets is_active = false)
  Future<void> deleteCustomer(int id) async {
    await _apiClient.delete('orders/customers/$id/');
  }

  // ==================== HELPER METHODS ====================

  /// Search customers by name or phone
  Future<CustomerListResponse> searchCustomers(String query) async {
    return getCustomers(search: query);
  }

  /// Get only active customers
  Future<CustomerListResponse> getActiveCustomers({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getCustomers(page: page, pageSize: pageSize, isActive: true);
  }

  /// Get only business customers
  Future<CustomerListResponse> getBusinessCustomers({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getCustomers(page: page, pageSize: pageSize, customerType: 'B2B');
  }

  /// Get only individual customers
  Future<CustomerListResponse> getIndividualCustomers({
    int page = 1,
    int pageSize = 20,
  }) async {
    return getCustomers(page: page, pageSize: pageSize, customerType: 'B2C');
  }
}
