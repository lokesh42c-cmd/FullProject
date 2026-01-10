import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layouts/main_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../widgets/add_edit_item_dialog.dart';

/// Item List Screen
/// Displays all items with filters
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
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Item'),
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
                    child: DropdownButton<String>(
                      value: provider.filterItemType ?? 'ALL',
                      style: AppTheme.bodySmall,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Types'),
                        ),
                        DropdownMenuItem(
                          value: 'SERVICE',
                          child: Text('Services'),
                        ),
                        DropdownMenuItem(
                          value: 'PRODUCT',
                          child: Text('Products'),
                        ),
                      ],
                      onChanged: (value) {
                        provider.setFilterItemType(
                          value == 'ALL' ? null : value,
                        );
                        provider.fetchItems();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),

                // Active filter
                FilterChip(
                  label: const Text('Active Only'),
                  selected: provider.filterIsActive == true,
                  onSelected: (selected) {
                    provider.setFilterIsActive(selected ? true : null);
                    provider.fetchItems();
                  },
                ),
              ],
            ),
          ),

          // Items table
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                ? _buildEmptyState()
                : _buildItemsTable(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'No items found',
            style: AppTheme.heading3.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            'Create your first item to get started',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.space5),
          ElevatedButton.icon(
            onPressed: () => _showAddItemDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Item'),
          ),
        ],
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
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text('ITEM NAME', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('TYPE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('PRICE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('STOCK', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('UNIT', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('STATUS', style: AppTheme.tableHeader),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text('ACTIONS', style: AppTheme.tableHeader),
                  ),
                ],
              ),
            ),

            // Table body
            ...provider.items.map((item) {
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
      child: InkWell(
        onTap: () => _showEditItemDialog(item),
        hoverColor: AppTheme.backgroundGrey.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Item Name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: AppTheme.fontSemibold,
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: AppTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Type
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  constraints: const BoxConstraints(maxWidth: 100),
                  decoration: BoxDecoration(
                    color: item.itemType == 'SERVICE'
                        ? AppTheme.info.withOpacity(0.1)
                        : AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.typeDisplay,
                    style: TextStyle(
                      color: item.itemType == 'SERVICE'
                          ? AppTheme.info
                          : AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Price
              Expanded(
                flex: 2,
                child: Text(item.priceWithUnit, style: AppTheme.bodyMedium),
              ),

              // Stock
              Expanded(
                flex: 2,
                child: Text(
                  item.trackStock
                      ? item.currentStock.toStringAsFixed(0)
                      : 'N/A',
                  style: AppTheme.bodyMedium.copyWith(
                    color: item.isLowStock
                        ? AppTheme.danger
                        : AppTheme.textPrimary,
                  ),
                ),
              ),

              // Unit
              Expanded(
                flex: 2,
                child: Text(item.unitName ?? '-', style: AppTheme.bodyMedium),
              ),

              // Status
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  constraints: const BoxConstraints(maxWidth: 100),
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showEditItemDialog(item),
                      tooltip: 'Edit',
                      color: AppTheme.primaryBlue,
                    ),
                    IconButton(
                      icon: Icon(
                        item.isActive ? Icons.toggle_on : Icons.toggle_off,
                        size: 18,
                      ),
                      onPressed: () => _toggleItemActive(item),
                      tooltip: item.isActive ? 'Deactivate' : 'Activate',
                      color: item.isActive
                          ? AppTheme.success
                          : AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddEditItemDialog(),
    );

    if (result == true && mounted) {
      context.read<ItemProvider>().fetchItems();
    }
  }

  Future<void> _showEditItemDialog(Item item) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddEditItemDialog(item: item),
    );

    if (result == true && mounted) {
      context.read<ItemProvider>().fetchItems();
    }
  }

  Future<void> _toggleItemActive(Item item) async {
    final provider = context.read<ItemProvider>();
    final success = await provider.updateItem(
      item.id!,
      item.copyWith(isActive: !item.isActive),
    );

    if (success != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.name} ${item.isActive ? "deactivated" : "activated"}',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      provider.fetchItems();
    }
  }
}
