import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order_item.dart';
import '../../items/models/item.dart';
import 'item_autocomplete.dart';

/// Order Items Table Widget
/// Inline table for managing order items with add/edit/delete
class OrderItemsTable extends StatefulWidget {
  final List<OrderItem> items;
  final Function(List<OrderItem>) onItemsChanged;
  final bool isTaxInclusive;

  const OrderItemsTable({
    super.key,
    required this.items,
    required this.onItemsChanged,
    this.isTaxInclusive = false,
  });

  @override
  State<OrderItemsTable> createState() => _OrderItemsTableState();
}

class _OrderItemsTableState extends State<OrderItemsTable> {
  Item? _selectedItem;

  void _onItemSelected(Item? item) {
    if (item == null) return;

    // Auto-add item immediately on selection
    final newItem = OrderItem(
      itemType: item.itemType,
      itemId: item.id,
      itemDescription: item.name,
      itemName: item.name,
      quantity: 1.0,
      unitPrice: item.sellingPrice ?? 0.0,
      taxPercentage: item.taxPercent,
      discount: 0.0,
      status: 'PENDING',
    );

    final updatedItems = [...widget.items, newItem];
    widget.onItemsChanged(updatedItems);

    // Clear selection for next item
    setState(() {
      _selectedItem = null;
    });
  }

  void _updateItem(int index, OrderItem updatedItem) {
    final updatedItems = [...widget.items];
    updatedItems[index] = updatedItem;
    widget.onItemsChanged(updatedItems);
  }

  void _deleteItem(int index) {
    final updatedItems = [...widget.items];
    updatedItems.removeAt(index);
    widget.onItemsChanged(updatedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          // Add item row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundGray,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: ItemAutocomplete(
              key: ValueKey(_selectedItem), // Force rebuild when item is added
              onItemSelected: _onItemSelected,
              hintText: 'Search and select item to add...',
            ),
          ),

          // Table header
          if (widget.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text('ITEM', style: AppTheme.tableHeader),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text('QTY', style: AppTheme.tableHeader),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Text('PRICE', style: AppTheme.tableHeader),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Text('DISCOUNT', style: AppTheme.tableHeader),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text('TAX %', style: AppTheme.tableHeader),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Text('TOTAL', style: AppTheme.tableHeader),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text('', style: AppTheme.tableHeader),
                  ),
                ],
              ),
            ),

          // Table rows
          if (widget.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No items added yet',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _OrderItemRow(
                item: item,
                onUpdate: (updatedItem) => _updateItem(index, updatedItem),
                onDelete: () => _deleteItem(index),
              );
            }).toList(),
        ],
      ),
    );
  }
}

/// Single order item row with inline editing
class _OrderItemRow extends StatefulWidget {
  final OrderItem item;
  final Function(OrderItem) onUpdate;
  final VoidCallback onDelete;

  const _OrderItemRow({
    required this.item,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<_OrderItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(2),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(2),
    );
    _discountController = TextEditingController(
      text: widget.item.discount.toStringAsFixed(2),
    );
    _taxController = TextEditingController(
      text: widget.item.taxPercentage.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _updateField() {
    final updatedItem = widget.item.copyWith(
      quantity: double.tryParse(_qtyController.text) ?? widget.item.quantity,
      unitPrice:
          double.tryParse(_priceController.text) ?? widget.item.unitPrice,
      discount:
          double.tryParse(_discountController.text) ?? widget.item.discount,
      taxPercentage:
          double.tryParse(_taxController.text) ?? widget.item.taxPercentage,
    );
    widget.onUpdate(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // Item description
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.itemDescription,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: AppTheme.fontSemibold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.item.itemType == 'SERVICE'
                        ? AppTheme.info.withOpacity(0.1)
                        : AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    widget.item.itemType,
                    style: AppTheme.bodyXSmall.copyWith(
                      color: widget.item.itemType == 'SERVICE'
                          ? AppTheme.info
                          : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Quantity
          SizedBox(
            width: 80,
            child: TextField(
              controller: _qtyController,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => _updateField(),
            ),
          ),
          const SizedBox(width: 12),

          // Unit Price
          SizedBox(
            width: 100,
            child: TextField(
              controller: _priceController,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                prefixText: '₹',
              ),
              onChanged: (_) => _updateField(),
            ),
          ),
          const SizedBox(width: 12),

          // Discount
          SizedBox(
            width: 100,
            child: TextField(
              controller: _discountController,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                prefixText: '₹',
              ),
              onChanged: (_) => _updateField(),
            ),
          ),
          const SizedBox(width: 12),

          // Tax %
          SizedBox(
            width: 80,
            child: TextField(
              controller: _taxController,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                suffixText: '%',
              ),
              onChanged: (_) => _updateField(),
            ),
          ),
          const SizedBox(width: 12),

          // Total
          SizedBox(
            width: 100,
            child: Text(
              '₹${widget.item.totalPrice.toStringAsFixed(2)}',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),

          // Delete button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppTheme.danger,
              onPressed: widget.onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }
}
