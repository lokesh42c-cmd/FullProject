import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../models/item.dart';
import '../models/item_unit.dart';
import '../providers/item_provider.dart';
import '../providers/item_unit_provider.dart';

/// Add/Edit Item Dialog
class AddEditItemDialog extends StatefulWidget {
  final Item? item;

  const AddEditItemDialog({super.key, this.item});

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _taxController;
  late TextEditingController _hsnSacController;

  String _selectedType = 'SERVICE';
  int? _selectedUnitId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _priceController = TextEditingController(
      text: item?.price.toString() ?? '',
    );
    _taxController = TextEditingController(
      text: item?.taxPercent.toString() ?? '18.0',
    );
    _hsnSacController = TextEditingController(text: item?.hsnSacCode ?? '');

    _selectedType = item?.itemType ?? 'SERVICE';
    _selectedUnitId = item?.unitId ?? item?.unit?.id;
    _isActive = item?.isActive ?? true;

    // Load units
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemUnitProvider>().fetchUnits(isActive: true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    _hsnSacController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final unitProvider = context.watch<ItemUnitProvider>();

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space5),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGray,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Text(
                    isEdit ? 'Edit Item' : 'Add Item',
                    style: AppTheme.heading2,
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
                padding: const EdgeInsets.all(AppTheme.space6),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Service'),
                              value: 'SERVICE',
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() => _selectedType = value!);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Product'),
                              value: 'PRODUCT',
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() => _selectedType = value!);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'e.g., Blouse Stitching, Silk Fabric',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Price and Tax
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price *',
                                prefixText: '₹',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space4),
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              decoration: const InputDecoration(
                                labelText: 'Tax %',
                                hintText: '18.0',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Unit and HSN/SAC
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedUnitId,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Select unit'),
                                ),
                                ...unitProvider.activeUnits.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit.id,
                                    child: Text(unit.displayName),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedUnitId = value);
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.space4),
                          Expanded(
                            child: TextFormField(
                              controller: _hsnSacController,
                              decoration: InputDecoration(
                                labelText: _selectedType == 'SERVICE'
                                    ? 'SAC Code'
                                    : 'HSN Code',
                                hintText: '998599',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Active status
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: Text(
                          _isActive
                              ? 'Item is currently active'
                              : 'Item is inactive',
                          style: AppTheme.bodySmall,
                        ),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppTheme.space5),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGray,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.space3),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final item = Item(
      id: widget.item?.id,
      itemType: _selectedType,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      unitId: _selectedUnitId,
      hsnSacCode: _hsnSacController.text.trim().isEmpty
          ? null
          : _hsnSacController.text.trim(),
      price: double.parse(_priceController.text),
      taxPercent: double.parse(_taxController.text),
      isActive: _isActive,
    );

    final provider = context.read<ItemProvider>();
    final bool success;

    if (widget.item == null) {
      success = await provider.createItem(item);
    } else {
      success = await provider.updateItem(widget.item!.id!, item);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      // SUCCESS - Close dialog and show success message
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
      // ERROR - Keep dialog open and show error
      final errorMsg = provider.errorMessage ?? 'Failed to save item';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 5),
        ),
      );

      // DON'T CLOSE DIALOG - User can fix the error!
    }
  }
}
