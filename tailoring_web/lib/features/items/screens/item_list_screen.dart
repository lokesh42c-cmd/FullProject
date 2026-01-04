import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../widgets/add_edit_item_dialog.dart';

/// Items List Screen
///
/// Shows all items (services and products) with filters
class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();

    return MainLayout(
      currentRoute: '/items',
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Text('Items', style: AppTheme.heading2),
                const SizedBox(width: AppTheme.space2),
                Text(
                  'Services & Products for daily operations',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: AppTheme.inputHeight,
                    child: TextField(
                      controller: _searchController,
                      style: AppTheme.bodySmall,
                      decoration: const InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                      onChanged: (value) => provider.setSearchQuery(value),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),

                // Type filter
                Container(
                  height: AppTheme.inputHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: provider.filterType,
                      style: AppTheme.bodySmall,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Types')),
                        DropdownMenuItem(
                          value: 'SERVICE',
                          child: Text('Services'),
                        ),
                        DropdownMenuItem(
                          value: 'PRODUCT',
                          child: Text('Products'),
                        ),
                      ],
                      onChanged: (value) => provider.setFilterType(value),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),

                // Active filter
                FilterChip(
                  label: const Text('Active Only'),
                  selected: provider.filterActive == true,
                  onSelected: (selected) {
                    provider.setFilterActive(selected ? true : null);
                  },
                ),
              ],
            ),
          ),

          // Items table
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                ? Center(child: Text(provider.errorMessage!))
                : provider.filteredItems.isEmpty
                ? _buildEmptyState()
                : _buildItemsTable(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              'No items found',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              'Add your first service or product item',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(ItemProvider provider) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundGrey,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('NAME', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('TYPE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('PRICE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('TAX %', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('UNIT', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('STATUS', style: AppTheme.tableHeader),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text('ACTIONS', style: AppTheme.tableHeader),
                  ),
                ],
              ),
            ),

            // Table body
            ...provider.filteredItems.map((item) {
              return _buildItemRow(item, provider);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Item item, ItemProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTheme.bodyMedium),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Type
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.itemType == 'SERVICE'
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : AppTheme.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.typeDisplay,
                  style: TextStyle(
                    color: item.itemType == 'SERVICE'
                        ? AppTheme.primaryBlue
                        : AppTheme.accentOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Price
            Expanded(
              flex: 2,
              child: Text(item.priceWithUnit, style: AppTheme.bodyMedium),
            ),

            // Tax
            Expanded(
              flex: 1,
              child: Text(
                '${item.taxPercent.toStringAsFixed(1)}%',
                style: AppTheme.bodyMedium,
              ),
            ),

            // Unit
            Expanded(
              flex: 1,
              child: Text(item.unit?.code ?? '-', style: AppTheme.bodyMedium),
            ),

            // Status
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isActive
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.statusText,
                  style: TextStyle(
                    color: item.isActive
                        ? AppTheme.success
                        : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Actions
            SizedBox(
              width: 120,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditItemDialog(item),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      item.isActive ? Icons.toggle_on : Icons.toggle_off,
                      size: 18,
                    ),
                    onPressed: () => _toggleActive(item, provider),
                    tooltip: item.isActive ? 'Deactivate' : 'Activate',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _deleteItem(item, provider),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditItemDialog(),
    );

    if (result == true && mounted) {
      // Item was created, refresh the list
      await context.read<ItemProvider>().fetchItems();
    }
  }

  Future<void> _showEditItemDialog(Item item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditItemDialog(item: item),
    );

    if (result == true && mounted) {
      // Item was updated, refresh the list
      await context.read<ItemProvider>().fetchItems();
    }
  }

  Future<void> _toggleActive(Item item, ItemProvider provider) async {
    final success = await provider.toggleActive(item.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.isActive
                ? 'Item deactivated successfully'
                : 'Item activated successfully',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _deleteItem(Item item, ItemProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteItem(item.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }
}
