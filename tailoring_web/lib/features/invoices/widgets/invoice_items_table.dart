import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/invoices/models/invoice.dart';
import 'package:tailoring_web/features/items/models/item.dart';
import 'package:tailoring_web/features/invoices/widgets/item_autocomplete_invoice.dart';

/// Invoice Items Table - UPDATED
/// With item search, inline editing, and tax-aware calculations
class InvoiceItemsTable extends StatefulWidget {
  final List<InvoiceItem> items;
  final Function(List<InvoiceItem>) onItemsChanged;
  final bool isTaxInclusive;
  final bool readOnly; // For invoices from orders

  const InvoiceItemsTable({
    super.key,
    required this.items,
    required this.onItemsChanged,
    this.isTaxInclusive = false,
    this.readOnly = false,
  });

  @override
  State<InvoiceItemsTable> createState() => _InvoiceItemsTableState();
}

class _InvoiceItemsTableState extends State<InvoiceItemsTable> {
  Key _searchKey = UniqueKey();

  void _onItemSelected(Item? item) {
    if (item == null) return;

    final newItem = InvoiceItem(
      itemType: item.itemType,
      itemDescription: item.name,
      quantity: 1.0,
      unitPrice: item.sellingPrice ?? 0.0,
      gstRate: item.taxPercent,
      discount: 0.0,
      hsnSacCode: item.hsnSacCode,
    );

    widget.onItemsChanged([...widget.items, newItem]);

    // Reset search box
    setState(() {
      _searchKey = UniqueKey();
    });
  }

  void _updateItem(int index, InvoiceItem updatedItem) {
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
          // Search box (only for walk-in invoices)
          if (!widget.readOnly)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: ItemAutocompleteInvoice(
                key: _searchKey,
                onItemSelected: _onItemSelected,
                hintText: 'Search and select item to add...',
              ),
            ),

          // Table Header
          if (widget.items.isNotEmpty) _buildHeader(),

          // Table Rows
          ...widget.items.asMap().entries.map((entry) {
            return _InvoiceItemRow(
              item: entry.value,
              isTaxInclusive: widget.isTaxInclusive,
              readOnly: widget.readOnly,
              onUpdate: (updatedItem) => _updateItem(entry.key, updatedItem),
              onDelete: () {
                final updated = [...widget.items];
                updated.removeAt(entry.key);
                widget.onItemsChanged(updated);
              },
            );
          }).toList(),

          // Empty state
          if (widget.items.isEmpty && !widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Search and add items to create invoice',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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
          Expanded(flex: 5, child: Text('ITEM', style: AppTheme.tableHeader)),
          Expanded(
            flex: 2,
            child: Text(
              'QTY',
              style: AppTheme.tableHeader,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PRICE',
              style: AppTheme.tableHeader,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DISCOUNT',
              style: AppTheme.tableHeader,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TAX %',
              style: AppTheme.tableHeader,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TOTAL',
              style: AppTheme.tableHeader,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _InvoiceItemRow extends StatefulWidget {
  final InvoiceItem item;
  final bool isTaxInclusive;
  final bool readOnly;
  final Function(InvoiceItem) onUpdate;
  final VoidCallback onDelete;

  const _InvoiceItemRow({
    required this.item,
    required this.isTaxInclusive,
    required this.readOnly,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<_InvoiceItemRow> {
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
      text: (widget.item.discount ?? 0.0).toString(),
    );
    _taxController = TextEditingController(
      text: widget.item.gstRate.toString(),
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
      gstRate: double.tryParse(_taxController.text) ?? 0.0,
    );
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total based on tax mode
    double netValue =
        (widget.item.quantity * widget.item.unitPrice) -
        (widget.item.discount ?? 0.0);

    double displayedTotal = widget.isTaxInclusive
        ? netValue
        : netValue + (netValue * (widget.item.gstRate / 100));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(widget.item.itemDescription, style: AppTheme.bodySmall),
          ),
          Expanded(flex: 2, child: _buildField(_qtyController)),
          Expanded(flex: 2, child: _buildField(_priceController, prefix: '₹')),
          Expanded(
            flex: 2,
            child: _buildField(_discountController, prefix: '₹'),
          ),
          Expanded(flex: 2, child: _buildField(_taxController, suffix: '%')),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '₹${displayedTotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: widget.readOnly
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppTheme.danger,
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller, {
    String? prefix,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextField(
        controller: controller,
        readOnly: widget.readOnly,
        onTap: () => _selectAll(controller),
        onChanged: (_) => _update(),
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 13),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          prefixText: prefix,
          suffixText: suffix,
          filled: widget.readOnly,
          fillColor: widget.readOnly ? AppTheme.backgroundGrey : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.primaryBlue),
          ),
        ),
      ),
    );
  }
}
