import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/item_service.dart';

/// Item Provider
///
/// Manages state for items (services and products)
class ItemProvider extends ChangeNotifier {
  final ItemService _service;

  ItemProvider(this._service);

  List<Item> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String? _filterType;
  bool? _filterActive = true;
  String _searchQuery = '';

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filterType => _filterType;
  bool? get filterActive => _filterActive;
  String get searchQuery => _searchQuery;

  /// Get filtered items
  List<Item> get filteredItems {
    var filtered = _items;

    // Filter by type
    if (_filterType != null) {
      filtered = filtered.where((i) => i.itemType == _filterType).toList();
    }

    // Filter by active
    if (_filterActive != null) {
      filtered = filtered.where((i) => i.isActive == _filterActive).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((i) {
        return i.name.toLowerCase().contains(query) ||
            (i.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  /// Get services only
  List<Item> get services =>
      _items.where((i) => i.itemType == ItemType.service).toList();

  /// Get products only
  List<Item> get products =>
      _items.where((i) => i.itemType == ItemType.product).toList();

  /// Get active items only
  List<Item> get activeItems => _items.where((i) => i.isActive).toList();

  /// Fetch all items
  Future<void> fetchItems({String? itemType, bool? isActive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getItems(
        itemType: itemType,
        isActive: isActive,
      );
      _items = response.items;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create item
  Future<bool> createItem(Item item) async {
    try {
      final created = await _service.createItem(item);
      _items.add(created);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      // Extract clean error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11); // Remove "Exception: " prefix
      }
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }

  /// Update item
  Future<bool> updateItem(int id, Item item) async {
    try {
      final updated = await _service.updateItem(id, item);
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        _items[index] = updated;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      // Extract clean error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11); // Remove "Exception: " prefix
      }
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }

  /// Delete item
  Future<bool> deleteItem(int id) async {
    try {
      await _service.deleteItem(id);
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle active status
  Future<bool> toggleActive(int id) async {
    try {
      final item = _items.firstWhere((i) => i.id == id);
      final updated = await _service.toggleActive(id, !item.isActive);
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        _items[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Set filter type
  void setFilterType(String? type) {
    _filterType = type;
    notifyListeners();
  }

  /// Set filter active
  void setFilterActive(bool? active) {
    _filterActive = active;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _filterType = null;
    _filterActive = true;
    _searchQuery = '';
    notifyListeners();
  }

  /// Refresh list
  Future<void> refresh() => fetchItems();
}
