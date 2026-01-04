import 'package:flutter/foundation.dart';
import '../models/service_item.dart';
import '../services/service_item_service.dart';

class ServiceItemProvider with ChangeNotifier {
  final ServiceItemService _service;

  ServiceItemProvider({ServiceItemService? service})
    : _service = service ?? ServiceItemService();

  List<ServiceItem> _serviceItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _filterCategory;
  bool? _filterActive = true;

  List<ServiceItem> get serviceItems => _serviceItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ServiceItem> get filteredServiceItems {
    var items = _serviceItems;
    if (_filterActive != null)
      items = items.where((i) => i.isActive == _filterActive).toList();
    if (_filterCategory != null)
      items = items.where((i) => i.category == _filterCategory).toList();
    return items;
  }

  Future<void> fetchServiceItems({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _serviceItems = await _service.getServiceItems(
        isActive: _filterActive,
        category: _filterCategory,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create service item - ensures loading state resets on error
  Future<bool> createServiceItem(ServiceItem serviceItem) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await _service.createServiceItem(serviceItem);
      _serviceItems.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      // Clean error message for display
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow; // Rethrow to let the UI show the error snackbar
    } finally {
      // ROOT CAUSE FIX: Stop loading regardless of success or failure
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateServiceItem(int id, ServiceItem serviceItem) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _service.updateServiceItem(id, serviceItem);
      final index = _serviceItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _serviceItems[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteServiceItem(int id) async {
    try {
      await _service.deleteServiceItem(id);
      _serviceItems.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleActiveStatus(int id) async {
    try {
      final item = _serviceItems.firstWhere((item) => item.id == id);
      final updated = await _service.toggleActiveStatus(id, !item.isActive);
      final index = _serviceItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _serviceItems[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    fetchServiceItems();
  }

  void setFilterActive(bool? isActive) {
    _filterActive = isActive;
    fetchServiceItems();
  }
}
