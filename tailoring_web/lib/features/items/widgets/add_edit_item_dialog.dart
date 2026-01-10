import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/item.dart';
import '../../items/providers/item_provider.dart';
import '../../masters/models/item_unit.dart';
import '../../masters/providers/masters_provider.dart';

/// Add/Edit Item Dialog
/// Form for creating or editing items
class AddEditItemDialog extends StatefulWidget {
  final Item? item;

  const AddEditItemDialog({super.key, this.item});

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _hsnSacCodeController = TextEditingController();
  final _taxPercentController = TextEditingController(text: '0');
  final _barcodeController = TextEditingController();
  final _openingStockController = TextEditingController(text: '0');
  final _minStockLevelController = TextEditingController(text: '0');

  String _itemType = 'SERVICE';
  bool _trackStock = false;
  bool _allowNegativeStock = true;
  int? _selectedUnitId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Load units
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MastersProvider>().fetchItemUnits();
    });

    // Populate form if editing
    if (widget.item != null) {
      final item = widget.item!;
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _itemType = item.itemType;
      _trackStock = item.trackStock;
      _allowNegativeStock = item.allowNegativeStock;
      _selectedUnitId = item.unitId;
      _sellingPriceController.text =
          item.sellingPrice?.toStringAsFixed(2) ?? '';
      _purchasePriceController.text =
          item.purchasePrice?.toStringAsFixed(2) ?? '';
      _hsnSacCodeController.text = item.hsnSacCode ?? '';
      _taxPercentController.text = item.taxPercent.toStringAsFixed(2);
      _barcodeController.text = item.barcode ?? '';
      _openingStockController.text = item.openingStock.toStringAsFixed(2);
      _minStockLevelController.text = item.minStockLevel.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _hsnSacCodeController.dispose();
    _taxPercentController.dispose();
    _barcodeController.dispose();
    _openingStockController.dispose();
    _minStockLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse numeric values safely
      final openingStock = _openingStockController.text.isEmpty
          ? 0.0
          : (double.tryParse(_openingStockController.text) ?? 0.0);

      final minStockLevel = _minStockLevelController.text.isEmpty
          ? 0.0
          : (double.tryParse(_minStockLevelController.text) ?? 0.0);

      final sellingPrice = _sellingPriceController.text.isEmpty
          ? null
          : double.tryParse(_sellingPriceController.text);

      final purchasePrice = _purchasePriceController.text.isEmpty
          ? null
          : double.tryParse(_purchasePriceController.text);

      final taxPercent = _taxPercentController.text.isEmpty
          ? 0.0
          : (double.tryParse(_taxPercentController.text) ?? 0.0);

      final item = Item(
        id: widget.item?.id,
        itemType: _itemType,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        unitId: _selectedUnitId,
        trackStock: _trackStock,
        allowNegativeStock: _allowNegativeStock,
        openingStock: openingStock,
        currentStock: 0.0,
        minStockLevel: minStockLevel,
        sellingPrice: sellingPrice,
        purchasePrice: purchasePrice,
        hsnSacCode: _hsnSacCodeController.text.trim().isEmpty
            ? null
            : _hsnSacCodeController.text.trim(),
        taxPercent: taxPercent,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
      );

      final provider = context.read<ItemProvider>();
      Item? savedItem;

      if (widget.item == null) {
        // Create new item
        savedItem = await provider.createItem(item);
      } else {
        // Update existing item
        savedItem = await provider.updateItem(widget.item!.id!, item);
      }

      if (savedItem != null && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? 'Item created successfully'
                  : 'Item updated successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save item'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mastersProvider = context.watch<MastersProvider>();

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundWhite,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.item == null ? 'Add New Item' : 'Edit Item',
                    style: AppTheme.heading3,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Type
                      Text('Item Type *', style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'SERVICE',
                            label: Text('Service'),
                            icon: Icon(Icons.build, size: 16),
                          ),
                          ButtonSegment(
                            value: 'PRODUCT',
                            label: Text('Product'),
                            icon: Icon(Icons.inventory, size: 16),
                          ),
                        ],
                        selected: {_itemType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _itemType = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Item Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'Enter item name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Item name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter description',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Unit
                      DropdownButtonFormField<int>(
                        value: _selectedUnitId,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'Select unit',
                        ),
                        items: mastersProvider.itemUnits.map((unit) {
                          return DropdownMenuItem<int>(
                            value: unit.id,
                            child: Text('${unit.name} (${unit.code})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Pricing Section
                      Text(
                        'Pricing',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: AppTheme.fontSemibold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price',
                                prefixText: '₹',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _purchasePriceController,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Price',
                                prefixText: '₹',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // GST Section
                      Text(
                        'GST Details',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: AppTheme.fontSemibold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hsnSacCodeController,
                              decoration: const InputDecoration(
                                labelText: 'HSN/SAC Code',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _taxPercentController,
                              decoration: const InputDecoration(
                                labelText: 'Tax %',
                                suffixText: '%',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Barcode
                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          hintText: 'Enter barcode',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stock Tracking
                      CheckboxListTile(
                        title: const Text('Track Stock'),
                        subtitle: const Text('Enable inventory tracking'),
                        value: _trackStock,
                        onChanged: (value) {
                          setState(() {
                            _trackStock = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (_trackStock) ...[
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text('Allow Negative Stock'),
                          subtitle: const Text(
                            'Allow orders when stock is low',
                          ),
                          value: _allowNegativeStock,
                          onChanged: (value) {
                            setState(() {
                              _allowNegativeStock = value ?? true;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _openingStockController,
                                decoration: const InputDecoration(
                                  labelText: 'Opening Stock',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                enabled: widget.item == null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _minStockLevelController,
                                decoration: const InputDecoration(
                                  labelText: 'Min Stock Level',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundWhite,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveItem,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.item == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
