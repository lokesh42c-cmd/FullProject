import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../masters/models/item_unit.dart';
import '../../masters/providers/masters_provider.dart';

/// Item Units Settings Widget
/// Manage units (Pieces, Meters, etc.)
class ItemUnitSettings extends StatefulWidget {
  const ItemUnitSettings({super.key});

  @override
  State<ItemUnitSettings> createState() => _ItemUnitSettingsState();
}

class _ItemUnitSettingsState extends State<ItemUnitSettings> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MastersProvider>().fetchItemUnits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MastersProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.straighten,
                size: 24,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Units', style: AppTheme.heading3),
                  Text(
                    'Manage measurement units for items',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddUnitDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Unit'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (provider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (provider.itemUnits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.straighten,
                      size: 48,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No units configured',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Table(
              border: TableBorder.all(color: AppTheme.borderLight),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundGrey,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('NAME', style: AppTheme.tableHeader),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('CODE', style: AppTheme.tableHeader),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('STATUS', style: AppTheme.tableHeader),
                    ),
                  ],
                ),
                ...provider.itemUnits.map((unit) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(unit.name, style: AppTheme.bodyMedium),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(unit.code, style: AppTheme.bodyMedium),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: unit.isActive
                                ? AppTheme.success.withOpacity(0.1)
                                : AppTheme.textMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unit.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: unit.isActive
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showAddUnitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _AddUnitDialog(),
    );

    if (result == true && mounted) {
      context.read<MastersProvider>().fetchItemUnits();
    }
  }
}

/// Add Unit Dialog
class _AddUnitDialog extends StatefulWidget {
  const _AddUnitDialog();

  @override
  State<_AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<_AddUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final unit = ItemUnit(
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
    );

    final provider = context.read<MastersProvider>();
    final created = await provider.createItemUnit(unit);

    if (created != null && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unit created successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to create unit'),
          backgroundColor: AppTheme.danger,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Add New Unit', style: AppTheme.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Name *',
                      hintText: 'e.g., Pieces, Meters',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Unit name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Code *',
                      hintText: 'e.g., PCS, MTR',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Unit code is required';
                      }
                      if (value.trim().length > 10) {
                        return 'Code must be 10 characters or less';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveUnit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
