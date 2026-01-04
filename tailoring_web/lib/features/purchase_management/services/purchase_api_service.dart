import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/purchase_management/models/vendor.dart';
import 'package:tailoring_web/features/purchase_management/models/purchase_bill.dart';
import 'package:tailoring_web/features/purchase_management/models/expense.dart';
import 'package:tailoring_web/features/purchase_management/models/payment.dart';

class PurchaseApiService {
  final ApiClient apiClient;

  PurchaseApiService(this.apiClient);

  String get baseUrl => '/api/purchase';

  // Vendors
  Future<Map<String, dynamic>> getVendors({
    String? search,
    bool? isActive,
    String? ordering,
    int? page,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (isActive != null) queryParams['is_active'] = isActive.toString();
    if (ordering != null) queryParams['ordering'] = ordering;
    if (page != null) queryParams['page'] = page.toString();

    final response = await apiClient.get(
      '$baseUrl/vendors/',
      queryParameters: queryParams,
    );
    final data = response.data;
    return {
      'count': data['count'],
      'results': (data['results'] as List)
          .map((json) => Vendor.fromJson(json))
          .toList(),
    };
  }

  Future<Vendor> getVendor(int id) async {
    final response = await apiClient.get('$baseUrl/vendors/$id/');
    return Vendor.fromJson(response.data);
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final response = await apiClient.post(
      '$baseUrl/vendors/',
      data: vendor.toJson(),
    );
    return Vendor.fromJson(response.data);
  }

  Future<Vendor> updateVendor(int id, Vendor vendor) async {
    final response = await apiClient.put(
      '$baseUrl/vendors/$id/',
      data: vendor.toJson(),
    );
    return Vendor.fromJson(response.data);
  }

  Future<void> deleteVendor(int id) async {
    await apiClient.delete('$baseUrl/vendors/$id/');
  }

  // Bills
  Future<Map<String, dynamic>> getBills({
    String? search,
    int? vendor,
    String? paymentStatus,
    String? ordering,
    int? page,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (vendor != null) queryParams['vendor'] = vendor.toString();
    if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
    if (ordering != null) queryParams['ordering'] = ordering;
    if (page != null) queryParams['page'] = page.toString();

    final response = await apiClient.get(
      '$baseUrl/bills/',
      queryParameters: queryParams,
    );
    final data = response.data;
    return {
      'count': data['count'],
      'results': (data['results'] as List)
          .map((json) => PurchaseBill.fromJson(json))
          .toList(),
    };
  }

  Future<PurchaseBill> getBill(int id) async {
    final response = await apiClient.get('$baseUrl/bills/$id/');
    return PurchaseBill.fromJson(response.data);
  }

  Future<PurchaseBill> createBill(PurchaseBill bill) async {
    final response = await apiClient.post(
      '$baseUrl/bills/',
      data: bill.toJson(),
    );
    return PurchaseBill.fromJson(response.data['bill']);
  }

  Future<PurchaseBill> updateBill(int id, PurchaseBill bill) async {
    final response = await apiClient.put(
      '$baseUrl/bills/$id/',
      data: bill.toJson(),
    );
    return PurchaseBill.fromJson(response.data);
  }

  Future<void> deleteBill(int id) async {
    await apiClient.delete('$baseUrl/bills/$id/');
  }

  Future<List<Payment>> getBillPayments(int billId) async {
    final response = await apiClient.get('$baseUrl/bills/$billId/payments/');
    final data = response.data as List;
    return data.map((json) => Payment.fromJson(json)).toList();
  }

  // Expenses
  Future<Map<String, dynamic>> getExpenses({
    String? search,
    String? category,
    String? paymentStatus,
    String? ordering,
    int? page,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
    if (ordering != null) queryParams['ordering'] = ordering;
    if (page != null) queryParams['page'] = page.toString();

    final response = await apiClient.get(
      '$baseUrl/expenses/',
      queryParameters: queryParams,
    );
    final data = response.data;
    return {
      'count': data['count'],
      'results': (data['results'] as List)
          .map((json) => Expense.fromJson(json))
          .toList(),
    };
  }

  Future<Expense> getExpense(int id) async {
    final response = await apiClient.get('$baseUrl/expenses/$id/');
    return Expense.fromJson(response.data);
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await apiClient.post(
      '$baseUrl/expenses/',
      data: expense.toJson(),
    );
    return Expense.fromJson(response.data);
  }

  Future<Expense> updateExpense(int id, Expense expense) async {
    final response = await apiClient.put(
      '$baseUrl/expenses/$id/',
      data: expense.toJson(),
    );
    return Expense.fromJson(response.data);
  }

  Future<void> deleteExpense(int id) async {
    await apiClient.delete('$baseUrl/expenses/$id/');
  }

  // Payments
  Future<Map<String, dynamic>> getPayments({
    String? search,
    String? paymentType,
    String? paymentMethod,
    String? ordering,
    int? page,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (paymentType != null) queryParams['payment_type'] = paymentType;
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
    if (ordering != null) queryParams['ordering'] = ordering;
    if (page != null) queryParams['page'] = page.toString();

    final response = await apiClient.get(
      '$baseUrl/payments/',
      queryParameters: queryParams,
    );
    final data = response.data;
    return {
      'count': data['count'],
      'results': (data['results'] as List)
          .map((json) => Payment.fromJson(json))
          .toList(),
    };
  }

  Future<Payment> getPayment(int id) async {
    final response = await apiClient.get('$baseUrl/payments/$id/');
    return Payment.fromJson(response.data);
  }

  Future<Payment> createPayment(Payment payment) async {
    final response = await apiClient.post(
      '$baseUrl/payments/',
      data: payment.toJson(),
    );
    return Payment.fromJson(response.data);
  }

  Future<void> deletePayment(int id) async {
    await apiClient.delete('$baseUrl/payments/$id/');
  }
}
