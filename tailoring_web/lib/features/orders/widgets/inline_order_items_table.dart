import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/items/models/item.dart';
import 'package:tailoring_web/features/items/providers/item_provider.dart';
import 'package:tailoring_web/features/orders/models/order_item.dart';

/// Inline Editable Order Items Table - COMPLETE FIX
class InlineOrderItemsTable extends StatefulWidget {
  final List<OrderItem> items;
  final Function(List<OrderItem>) onItemsChanged;
  final bool isTaxInclusive;

  const InlineOrderItemsTable({
    super.key,
    required this.items,
    required this.onItemsChanged,
    this.isTaxInclusive = false,
  });

  @override
  State<InlineOrderItemsTable> createState() => _InlineOrderItemsTableState();
}

class _InlineOrderItemsTableState extends State<InlineOrderItemsTable> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItems();
    });
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
          _buildHeader(),
          if (widget.items.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: [
                _buildTableHeader(),
                ...widget.items.asMap().entries.map((entry) {
                  return _buildItemRow(entry.key, entry.value);
                }).toList(),
              ],
            ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_cart,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text('Order Items', style: AppTheme.heading3),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.backgroundGray,
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('ITEM', style: AppTheme.tableHeader)),
          Expanded(child: Text('QTY', style: AppTheme.tableHeader)),
          Expanded(flex: 2, child: Text('RATE', style: AppTheme.tableHeader)),
          Expanded(child: Text('DISC %', style: AppTheme.tableHeader)),
          Expanded(child: Text('TAX', style: AppTheme.tableHeader)),
          Expanded(flex: 2, child: Text('TOTAL', style: AppTheme.tableHeader)),
          SizedBox(width: 40, child: Text('', style: AppTheme.tableHeader)),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, OrderItem item) {
    final itemProvider = context.watch<ItemProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _buildItemAutocomplete(index, item, itemProvider),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildNumberField(
              value: item.quantity.toString(),
              onChanged: (v) => _updateQuantity(index, v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildNumberField(
              key: ValueKey('rate_$index'),
              value: item.unitPrice > 0
                  ? item.unitPrice.toStringAsFixed(0)
                  : '',
              prefix: '₹',
              onChanged: (v) => _updatePrice(index, v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildNumberField(
              key: ValueKey('disc_$index'),
              value: item.itemDiscountPercentage > 0
                  ? item.itemDiscountPercentage.toStringAsFixed(0)
                  : '',
              suffix: '%',
              onChanged: (v) => _updateDiscount(index, v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.taxPercent > 0
                  ? '${item.taxPercent.toStringAsFixed(0)}%'
                  : '-',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              item.total > 0 ? item.formattedTotal : '₹0.00',
              style: AppTheme.bodyMediumBold,
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 18, color: AppTheme.danger),
              onPressed: () => _removeItem(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAutocomplete(
    int index,
    OrderItem item,
    ItemProvider itemProvider,
  ) {
    final hasSelection = item.unitPrice > 0;
    return Autocomplete<Item>(
      initialValue: hasSelection ? TextEditingValue(text: item.itemName) : null,
      optionsBuilder: (tv) => tv.text.isEmpty
          ? const Iterable<Item>.empty()
          : itemProvider.items.where(
              (i) => i.name.toLowerCase().contains(tv.text.toLowerCase()),
            ),
      displayStringForOption: (i) => i.name,
      fieldViewBuilder: (ctx, ctrl, fn, _) => TextField(
        controller: ctrl,
        focusNode: fn,
        decoration: InputDecoration(
          hintText: 'Type to search items...',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: AppTheme.bodySmall,
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 350,
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: opts.length,
              itemBuilder: (c, idx) {
                final i = opts.elementAt(idx);
                return InkWell(
                  onTap: () => onSel(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          i.itemType == 'SERVICE'
                              ? Icons.design_services
                              : Icons.inventory_2,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name, style: AppTheme.bodySmall),
                              Text(
                                '${i.typeDisplay} • ₹${i.price} • Tax: ${i.taxPercent}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: (i) => _changeItem(index, i),
    );
  }

  Widget _buildNumberField({
    Key? key,
    required String value,
    required Function(String) onChanged,
    String? prefix,
    String? suffix,
  }) {
    // Create controller with current value
    final controller = TextEditingController(text: value);

    return TextFormField(
      key: key,
      controller: controller, // ← Use controller instead of initialValue
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: const OutlineInputBorder(),
        prefixText: prefix,
        suffixText: suffix,
        isDense: true,
      ),
      style: AppTheme.bodySmall,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Icon(Icons.shopping_bag_outlined, size: 48, color: AppTheme.textMuted),
        const SizedBox(height: 12),
        Text(
          'No items added yet',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    ),
  );

  Widget _buildAddButton() => Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _addNewRow,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Item'),
      ),
    ),
  );

  void _addNewRow() {
    final ip = context.read<ItemProvider>();
    if (ip.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No items available')));
      return;
    }
    final fi = ip.items.first;
    final bi = OrderItem(
      orderId: 0,
      itemId: 0,
      item: null,
      quantity: 1,
      unitPrice: 0,
      itemDiscountPercentage: 0,
      itemDiscountAmount: 0,
      taxPercentage: 0,
      subtotal: 0,
      taxAmount: 0,
      total: 0,
    );
    final u = List<OrderItem>.from(widget.items)..add(bi);
    widget.onItemsChanged(u);
  }

  void _changeItem(int i, Item si) {
    final ni = OrderItem.fromItem(
      orderId: 0,
      item: si,
      quantity: widget.items[i].quantity,
      itemDiscountPercentage: widget.items[i].itemDiscountPercentage,
      isTaxInclusive: widget.isTaxInclusive,
    );
    print('🔍 Selected Item: ${si.name}');
    print('🔍 Item Price: ${si.price}');
    print('🔍 OrderItem unitPrice: ${ni.unitPrice}');
    print('🔍 OrderItem total: ${ni.total}');
    final u = List<OrderItem>.from(widget.items);
    u[i] = ni;
    widget.onItemsChanged(u);
  }

  void _updateQuantity(int i, String v) {
    final q = double.tryParse(v) ?? 1;
    final ci = widget.items[i];
    if (ci.item == null) return;
    final u = List<OrderItem>.from(widget.items);
    u[i] = ci.recalculate(quantity: q, isTaxInclusive: widget.isTaxInclusive);
    widget.onItemsChanged(u);
  }

  void _updatePrice(int i, String v) {
    final p = double.tryParse(v) ?? 0;
    final ci = widget.items[i];
    if (ci.item == null) return;
    final u = List<OrderItem>.from(widget.items);
    u[i] = ci.recalculate(unitPrice: p, isTaxInclusive: widget.isTaxInclusive);
    widget.onItemsChanged(u);
  }

  void _updateDiscount(int i, String v) {
    final d = double.tryParse(v) ?? 0;
    final ci = widget.items[i];
    if (ci.item == null) return;
    final u = List<OrderItem>.from(widget.items);
    u[i] = ci.recalculate(
      itemDiscountPercentage: d,
      isTaxInclusive: widget.isTaxInclusive,
    );
    widget.onItemsChanged(u);
  }

  void _removeItem(int i) {
    final u = List<OrderItem>.from(widget.items)..removeAt(i);
    widget.onItemsChanged(u);
  }
}
