import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order_item.dart';
import '../../items/models/item.dart';
import 'item_autocomplete.dart';

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
  // Key used to force reset the ItemAutocomplete after selection
  Key _searchKey = UniqueKey();

  void _onItemSelected(Item? item) {
    if (item == null) return;

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

    widget.onItemsChanged([...widget.items, newItem]);

    // Force the search box to become blank for the next item
    setState(() {
      _searchKey = UniqueKey();
    });
  }

  void _updateItem(int index, OrderItem updatedItem) {
    final updatedItems = [...widget.items];
    updatedItems[index] = updatedItem;
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundGrey,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: ItemAutocomplete(
              key: _searchKey, // Resets the search field
              onItemSelected: _onItemSelected,
              hintText: 'Search and select item to add...',
            ),
          ),
          if (widget.items.isNotEmpty) _buildHeader(),
          ...widget.items.asMap().entries.map((entry) {
            return _OrderItemRow(
              item: entry.value,
              isTaxInclusive: widget.isTaxInclusive,
              onUpdate: (updatedItem) => _updateItem(entry.key, updatedItem),
              onDelete: () {
                final updated = [...widget.items];
                updated.removeAt(entry.key);
                widget.onItemsChanged(updated);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: AppTheme.backgroundGrey),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('ITEM', style: AppTheme.tableHeader)),
          SizedBox(width: 80, child: Text('QTY', style: AppTheme.tableHeader)),
          SizedBox(
            width: 100,
            child: Text('PRICE', style: AppTheme.tableHeader),
          ),
          SizedBox(
            width: 100,
            child: Text('DISCOUNT', style: AppTheme.tableHeader),
          ),
          SizedBox(
            width: 80,
            child: Text('TAX %', style: AppTheme.tableHeader),
          ),
          SizedBox(
            width: 100,
            child: Text('TOTAL', style: AppTheme.tableHeader),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatefulWidget {
  final OrderItem item;
  final bool isTaxInclusive;
  final Function(OrderItem) onUpdate;
  final VoidCallback onDelete;

  const _OrderItemRow({
    required this.item,
    required this.isTaxInclusive,
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
      text: widget.item.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice.toString(),
    );
    _discountController = TextEditingController(
      text: widget.item.discount.toString(),
    );
    _taxController = TextEditingController(
      text: widget.item.taxPercentage.toString(),
    );
  }

  // Common function to select all text when clicking a field
  void _selectAll(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _update() {
    final updated = widget.item.copyWith(
      quantity: double.tryParse(_qtyController.text) ?? 0.0,
      unitPrice: double.tryParse(_priceController.text) ?? 0.0,
      discount: double.tryParse(_discountController.text) ?? 0.0,
      taxPercentage: double.tryParse(_taxController.text) ?? 0.0,
    );
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    // Correctly calculate the displayed total based on Tax Mode
    double netValue =
        (widget.item.quantity * widget.item.unitPrice) - widget.item.discount;
    double displayedTotal = widget.isTaxInclusive
        ? netValue
        : netValue + (netValue * (widget.item.taxPercentage / 100));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(widget.item.itemDescription, style: AppTheme.bodySmall),
          ),
          _buildField(_qtyController, 80),
          _buildField(_priceController, 100, prefix: '₹'),
          _buildField(_discountController, 100, prefix: '₹'),
          _buildField(_taxController, 80, suffix: '%'),
          SizedBox(
            width: 100,
            child: Text(
              '₹${displayedTotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.danger,
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    double width, {
    String? prefix,
    String? suffix,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: TextField(
          controller: controller,
          onTap: () => _selectAll(controller), // Fixes the 50/5 zero issue
          onChanged: (_) => _update(),
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(8),
            prefixText: prefix,
            suffixText: suffix,
          ),
        ),
      ),
    );
  }
}
