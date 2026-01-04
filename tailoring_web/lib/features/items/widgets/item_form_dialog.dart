import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/item_unit_provider.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item;

  const ItemFormDialog({super.key, this.item});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // ===================== Controllers =====================
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _taxController = TextEditingController();

  // ===================== State =====================
  String _itemType = 'PRODUCT';
  int? _selectedUnitId;

  @override
  void initState() {
    super.initState();

    // Load units for dropdown
    context.read<ItemUnitProvider>().loadUnits();

    if (widget.item != null) {
      final item = widget.item!;
      _itemType = item.itemType;
      _selectedUnitId = item.unit?.id;
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _priceController.text = item.price.toString();
      _taxController.text = item.taxPercent.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 720,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(child: _buildForm()),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Text(
      widget.item == null ? 'Add Item' : 'Edit Item',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  // ===================== FORM =====================

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemType(),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Name is required' : null,
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'E.g. Includes cutting, lining, hooks',
            ),
          ),

          const SizedBox(height: 12),

          _buildUnitDropdown(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Price is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tax %'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== ITEM TYPE =====================

  Widget _buildItemType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Type *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Radio<String>(
              value: 'PRODUCT',
              groupValue: _itemType,
              onChanged: (v) => setState(() => _itemType = v!),
            ),
            const Text('Product'),
            const SizedBox(width: 16),
            Radio<String>(
              value: 'SERVICE',
              groupValue: _itemType,
              onChanged: (v) => setState(() => _itemType = v!),
            ),
            const Text('Service'),
          ],
        ),
      ],
    );
  }

  // ===================== UNIT DROPDOWN =====================

  Widget _buildUnitDropdown() {
    return Consumer<ItemUnitProvider>(
      builder: (context, unitProvider, _) {
        if (unitProvider.loading) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: CircularProgressIndicator(),
          );
        }

        return DropdownButtonFormField<int>(
          value: _selectedUnitId,
          decoration: const InputDecoration(labelText: 'Unit *'),
          items: unitProvider.units.map((u) {
            return DropdownMenuItem(value: u.id, child: Text(u.name));
          }).toList(),
          onChanged: (v) => setState(() => _selectedUnitId = v),
          validator: (v) => v == null ? 'Unit is required' : null,
        );
      },
    );
  }

  // ===================== FOOTER =====================

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  // ===================== SAVE =====================

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'item_type': _itemType,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'unit': _selectedUnitId,
      'price': double.parse(_priceController.text),
      'tax_percent': double.tryParse(_taxController.text) ?? 0,
    };

    final provider = context.read<ItemProvider>();

    if (widget.item == null) {
      provider.addItem(payload);
    } else {
      provider.updateItem(widget.item!.id, payload);
    }

    Navigator.pop(context);
  }
}
