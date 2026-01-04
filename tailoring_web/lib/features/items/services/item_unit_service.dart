import 'package:tailoring_web/core/api/api_client.dart';
import '../models/item_unit.dart';

/// Item Unit Service
///
/// Handles all item unit related API calls
class ItemUnitService {
  final ApiClient _apiClient;

  ItemUnitService(this._apiClient);

  /// Get all item units
  Future<ItemUnitListResponse> getItemUnits({bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{};

      if (isActive != null) {
        queryParams['is_active'] = isActive;
      }

      final response = await _apiClient.get(
        'orders/item-units/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return ItemUnitListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load item units: $e');
    }
  }

  /// Get single item unit
  Future<ItemUnit> getItemUnit(int id) async {
    try {
      final response = await _apiClient.get('orders/item-units/$id/');
      return ItemUnit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load item unit: $e');
    }
  }

  /// Create item unit
  Future<ItemUnit> createItemUnit(ItemUnit unit) async {
    try {
      final response = await _apiClient.post(
        'orders/item-units/',
        data: unit.toJson(),
      );
      return ItemUnit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create item unit: $e');
    }
  }

  /// Update item unit
  Future<ItemUnit> updateItemUnit(int id, ItemUnit unit) async {
    try {
      final response = await _apiClient.put(
        'orders/item-units/$id/',
        data: unit.toJson(),
      );
      return ItemUnit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update item unit: $e');
    }
  }

  /// Delete item unit
  Future<void> deleteItemUnit(int id) async {
    try {
      await _apiClient.delete('orders/item-units/$id/');
    } catch (e) {
      throw Exception('Failed to delete item unit: $e');
    }
  }

  /// Toggle active status
  Future<ItemUnit> toggleActive(int id, bool isActive) async {
    try {
      final response = await _apiClient.patch(
        'orders/item-units/$id/',
        data: {'is_active': isActive},
      );
      return ItemUnit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to toggle item unit status: $e');
    }
  }
}
