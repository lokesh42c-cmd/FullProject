import 'package:flutter/foundation.dart';
import '../models/item_unit.dart';
import 'package:tailoring_web/core/api/api_client.dart';

/// Masters Provider
/// Manages master data like ItemUnits
class MastersProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  MastersProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // State
  List<ItemUnit> _itemUnits = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ItemUnit> get itemUnits => _itemUnits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all item units
  Future<void> fetchItemUnits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('orders/item-units/');

      // Handle paginated response
      final dynamic data = response.data;
      final List<dynamic> results;

      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List<dynamic>;
      } else {
        results = data as List<dynamic>;
      }

      _itemUnits = results
          .map((json) => ItemUnit.fromJson(json as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to fetch item units: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new item unit
  Future<ItemUnit?> createItemUnit(ItemUnit unit) async {
    try {
      final response = await _apiClient.post(
        'orders/item-units/',
        data: unit.toJson(),
      );
      final createdUnit = ItemUnit.fromJson(
        response.data as Map<String, dynamic>,
      );
      _itemUnits.add(createdUnit);
      notifyListeners();
      return createdUnit;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to create item unit: $e';
      notifyListeners();
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
