import 'package:tailoring_web/core/api/api_client.dart';
import '../models/item.dart';

/// Item Service
///
/// Handles all item-related API calls (services and products)
class ItemService {
  final ApiClient _apiClient;

  ItemService(this._apiClient);

  /// Get all items with optional filters
  Future<ItemListResponse> getItems({
    String? itemType,
    bool? isActive,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (itemType != null) {
        queryParams['item_type'] = itemType;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        'orders/items/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return ItemListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load items: $e');
    }
  }

  /// Get single item
  Future<Item> getItem(int id) async {
    try {
      final response = await _apiClient.get('orders/items/$id/');
      return Item.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load item: $e');
    }
  }

  /// Create item
  Future<Item> createItem(Item item) async {
    try {
      final response = await _apiClient.post(
        'orders/items/',
        data: item.toJson(),
      );
      return Item.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  /// Update item
  Future<Item> updateItem(int id, Item item) async {
    try {
      final response = await _apiClient.put(
        'orders/items/$id/',
        data: item.toJson(),
      );
      return Item.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Delete item
  Future<void> deleteItem(int id) async {
    try {
      await _apiClient.delete('orders/items/$id/');
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Toggle active status
  Future<Item> toggleActive(int id, bool isActive) async {
    try {
      final response = await _apiClient.patch(
        'orders/items/$id/',
        data: {'is_active': isActive},
      );
      return Item.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to toggle item status: $e');
    }
  }
}
