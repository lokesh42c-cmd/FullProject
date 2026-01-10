import 'package:tailoring_web/core/api/api_client.dart';
import '../models/item.dart';

/// Item Service
/// Handles all Item-related API calls
class ItemService {
  final ApiClient _apiClient;

  ItemService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch all items with optional filters
  Future<List<Item>> fetchItems({
    String? search,
    String? itemType,
    bool? trackStock,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (itemType != null) {
        queryParams['item_type'] = itemType;
      }
      if (trackStock != null) {
        queryParams['track_stock'] = trackStock;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive;
      }

      final response = await _apiClient.get(
        'orders/items/',
        queryParameters: queryParams,
      );

      // Handle paginated response
      final dynamic data = response.data;
      final List<dynamic> results;

      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List<dynamic>;
      } else {
        results = data as List<dynamic>;
      }

      return results
          .map((json) => Item.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch single item by ID
  Future<Item> fetchItemById(int id) async {
    try {
      final response = await _apiClient.get('orders/items/$id/');
      return Item.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new item
  Future<Item> createItem(Item item) async {
    try {
      final response = await _apiClient.post(
        'orders/items/',
        data: item.toJson(),
      );
      return Item.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing item
  Future<Item> updateItem(int id, Item item) async {
    try {
      final response = await _apiClient.put(
        'orders/items/$id/',
        data: item.toJson(),
      );
      return Item.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete item (soft delete)
  Future<void> deleteItem(int id) async {
    try {
      await _apiClient.delete('orders/items/$id/');
    } catch (e) {
      rethrow;
    }
  }

  /// Search items by name or barcode (for autocomplete)
  Future<List<Item>> searchItems(String query) async {
    try {
      final response = await _apiClient.get(
        'orders/items/',
        queryParameters: {'search': query, 'is_active': true},
      );

      // Handle paginated response
      final dynamic data = response.data;
      final List<dynamic> results;

      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List<dynamic>;
      } else {
        results = data as List<dynamic>;
      }

      return results
          .map((json) => Item.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
