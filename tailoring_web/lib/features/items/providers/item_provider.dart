import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import 'package:tailoring_web/core/api/api_client.dart';

/// Item Provider
/// Manages Item state and business logic
class ItemProvider with ChangeNotifier {
  final ItemService _itemService;

  ItemProvider({ItemService? itemService})
    : _itemService = itemService ?? ItemService();

  // State
  List<Item> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String? _searchQuery;
  String? _filterItemType;
  bool? _filterTrackStock;
  bool? _filterIsActive = true;

  // Getters
  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  String? get filterItemType => _filterItemType;
  bool? get filterTrackStock => _filterTrackStock;
  bool? get filterIsActive => _filterIsActive;

  // Filtered items
  List<Item> get filteredItems {
    return _items.where((item) {
      // Search filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesBarcode =
            item.barcode?.toLowerCase().contains(query) ?? false;
        final matchesDescription =
            item.description?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesBarcode && !matchesDescription) {
          return false;
        }
      }

      // Item type filter
      if (_filterItemType != null && item.itemType != _filterItemType) {
        return false;
      }

      // Track stock filter
      if (_filterTrackStock != null && item.trackStock != _filterTrackStock) {
        return false;
      }

      // Active filter
      if (_filterIsActive != null && item.isActive != _filterIsActive) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Fetch all items
  Future<void> fetchItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _itemService.fetchItems(
        search: _searchQuery,
        itemType: _filterItemType,
        trackStock: _filterTrackStock,
        isActive: _filterIsActive,
      );
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to fetch items: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch item by ID
  Future<Item?> fetchItemById(int id) async {
    try {
      return await _itemService.fetchItemById(id);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to fetch item: $e';
      notifyListeners();
      return null;
    }
  }

  /// Create new item
  Future<Item?> createItem(Item item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdItem = await _itemService.createItem(item);
      _items.insert(0, createdItem);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return createdItem;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to create item: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update existing item
  Future<Item?> updateItem(int id, Item item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = await _itemService.updateItem(id, item);
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        _items[index] = updatedItem;
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return updatedItem;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to update item: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Delete item
  Future<bool> deleteItem(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _itemService.deleteItem(id);
      _items.removeWhere((item) => item.id == id);
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
      _errorMessage = 'Failed to delete item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Search items (for autocomplete)
  Future<List<Item>> searchItems(String query) async {
    try {
      return await _itemService.searchItems(query);
    } catch (e) {
      return [];
    }
  }

  /// Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set item type filter
  void setFilterItemType(String? itemType) {
    _filterItemType = itemType;
    notifyListeners();
  }

  /// Set track stock filter
  void setFilterTrackStock(bool? trackStock) {
    _filterTrackStock = trackStock;
    notifyListeners();
  }

  /// Set active filter
  void setFilterIsActive(bool? isActive) {
    _filterIsActive = isActive;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = null;
    _filterItemType = null;
    _filterTrackStock = null;
    _filterIsActive = true;
    notifyListeners();
  }

  /// Refresh items
  Future<void> refresh() async {
    await fetchItems();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
