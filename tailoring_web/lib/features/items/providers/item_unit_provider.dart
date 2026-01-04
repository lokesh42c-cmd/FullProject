import 'package:flutter/material.dart';
import '../models/item_unit.dart';
import '../services/item_unit_service.dart';

/// Item Unit Provider
///
/// Manages state for item units
class ItemUnitProvider extends ChangeNotifier {
  final ItemUnitService _service;

  ItemUnitProvider(this._service);

  List<ItemUnit> _units = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ItemUnit> get units => _units;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get active units only
  List<ItemUnit> get activeUnits => _units.where((u) => u.isActive).toList();

  /// Fetch all units
  Future<void> fetchUnits({bool? isActive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getItemUnits(isActive: isActive);
      _units = response.units;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create unit
  Future<bool> createUnit(ItemUnit unit) async {
    try {
      final created = await _service.createItemUnit(unit);
      _units.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update unit
  Future<bool> updateUnit(int id, ItemUnit unit) async {
    try {
      final updated = await _service.updateItemUnit(id, unit);
      final index = _units.indexWhere((u) => u.id == id);
      if (index != -1) {
        _units[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete unit
  Future<bool> deleteUnit(int id) async {
    try {
      await _service.deleteItemUnit(id);
      _units.removeWhere((u) => u.id == id);
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
      final unit = _units.firstWhere((u) => u.id == id);
      final updated = await _service.toggleActive(id, !unit.isActive);
      final index = _units.indexWhere((u) => u.id == id);
      if (index != -1) {
        _units[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh list
  Future<void> refresh() => fetchUnits();
}
