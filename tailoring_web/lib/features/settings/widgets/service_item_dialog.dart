import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../models/service_item.dart';
import '../providers/service_item_provider.dart';

class ServiceItemDialog extends StatefulWidget {
  final ServiceItem? serviceItem;

  const ServiceItemDialog({super.key, this.serviceItem});

  @override
  State<ServiceItemDialog> createState() => _ServiceItemDialogState();
}

class _ServiceItemDialogState extends State<ServiceItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _defaultPriceController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _taxRateController;
  late TextEditingController _sacCodeController;
  late TextEditingController _estimatedDaysController;
  late TextEditingController _notesController;

  String _selectedCategory = 'STITCHING';
  String _selectedUnit = 'PER_ITEM';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final service = widget.serviceItem;

    _nameController = TextEditingController(text: service?.name ?? '');
    _descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    _defaultPriceController = TextEditingController(
      text: service?.defaultPrice.toString() ?? '',
    );
    _minPriceController = TextEditingController(
      text: service?.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: service?.maxPrice?.toString() ?? '',
    );
    _taxRateController = TextEditingController(
      text: service?.taxRate.toString() ?? '18.00',
    );
    _sacCodeController = TextEditingController(text: service?.sacCode ?? '');
    _estimatedDaysController = TextEditingController(
      text: service?.estimatedDays?.toString() ?? '',
    );
    _notesController = TextEditingController(text: service?.notes ?? '');

    _selectedCategory = service?.category ?? 'STITCHING';
    _selectedUnit = service?.unit ?? 'PER_ITEM';
    _isActive = service?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _defaultPriceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _taxRateController.dispose();
    _sacCodeController.dispose();
    _estimatedDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.serviceItem != null;

    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
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
                    isEdit ? 'Edit Service Item' : 'Add Service Item',
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
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Service Name *',
                          hintText: 'e.g., Blouse Stitching',
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
                          hintText: 'Brief description of the service',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Category and Unit
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                              ),
                              items: ServiceCategory.all.map((cat) {
                                return DropdownMenuItem(
                                  value: cat['value'],
                                  child: Text(cat['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategory = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.space4),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit *',
                              ),
                              items: ServiceUnit.all.map((unit) {
                                return DropdownMenuItem(
                                  value: unit['value'],
                                  child: Text(unit['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedUnit = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Pricing
                      Text('Pricing', style: AppTheme.bodyMediumBold),
                      const SizedBox(height: AppTheme.space3),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _defaultPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Default Price *',
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
                              controller: _minPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Min Price',
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
                          const SizedBox(width: AppTheme.space4),
                          Expanded(
                            child: TextFormField(
                              controller: _maxPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Max Price',
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
                      const SizedBox(height: AppTheme.space4),

                      // Tax and HSN
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxRateController,
                              decoration: const InputDecoration(
                                labelText: 'Tax Rate (%) *',
                                hintText: '18.00',
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
                              controller: _sacCodeController,
                              decoration: const InputDecoration(
                                labelText: 'SAC Code',
                                hintText: '998599',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Estimated Days
                      TextFormField(
                        controller: _estimatedDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Days',
                          hintText: 'Typical completion time',
                          suffixText: 'days',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes',
                          hintText:
                              'Notes for staff (not visible to customers)',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Active Status
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: Text(
                          _isActive
                              ? 'Service is currently offered'
                              : 'Service is inactive',
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

            // Actions
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
                    onPressed: _isLoading ? null : _saveService,
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

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final serviceItem = ServiceItem(
      id: widget.serviceItem?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      defaultPrice: double.parse(_defaultPriceController.text),
      minPrice: _minPriceController.text.isEmpty
          ? null
          : double.parse(_minPriceController.text),
      maxPrice: _maxPriceController.text.isEmpty
          ? null
          : double.parse(_maxPriceController.text),
      unit: _selectedUnit,
      taxRate: double.parse(_taxRateController.text),
      sacCode: _sacCodeController.text.trim().isEmpty
          ? null
          : _sacCodeController.text.trim(),
      isActive: _isActive,
      estimatedDays: _estimatedDaysController.text.isEmpty
          ? null
          : int.parse(_estimatedDaysController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final provider = context.read<ServiceItemProvider>();
    final bool success;

    if (widget.serviceItem == null) {
      success = await provider.createServiceItem(serviceItem);
    } else {
      success = await provider.updateServiceItem(
        widget.serviceItem!.id!,
        serviceItem,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.serviceItem == null
                ? 'Service created successfully'
                : 'Service updated successfully',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save service'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
}
