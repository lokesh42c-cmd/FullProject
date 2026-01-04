import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/items/models/item.dart';
import 'package:tailoring_web/features/items/providers/item_provider.dart';
import 'package:tailoring_web/features/orders/models/order_item.dart';

/// Add Item Dialog
///
/// Search and select items to add to order
class AddItemDialog extends StatefulWidget {
  final int orderId;

  const AddItemDialog({super.key, required this.orderId});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  Item? _selectedItem;
  double _quantity = 1.0;
  double? _customPrice;
  double _discountPercent = 0.0;

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
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();

    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        child: Column(
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
                  const Icon(
                    Icons.add_shopping_cart,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: AppTheme.space3),
                  const Text('Add Item', style: AppTheme.heading2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search and filters
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => provider.setSearchQuery(value),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Container(
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
                          DropdownMenuItem(
                            value: null,
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
                        onChanged: (value) => provider.setFilterType(value),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Items list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items found',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.filteredItems.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space4,
                      ),
                      itemBuilder: (context, index) {
                        final item = provider.filteredItems[index];
                        return _buildItemCard(item);
                      },
                    ),
            ),

            // Selected item details
            if (_selectedItem != null) ...[
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(AppTheme.space5),
                color: AppTheme.backgroundGray,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected: ${_selectedItem!.name}',
                                style: AppTheme.bodyMediumBold,
                              ),
                              Text(
                                'Base Price: ${_selectedItem!.formattedPrice}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedItem = null;
                              _priceController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Row(
                      children: [
                        // Quantity
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: Icon(Icons.format_list_numbered),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _quantity = double.tryParse(value) ?? 1.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.space3),
                        // Custom Price (optional)
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Custom Price (Optional)',
                              prefixIcon: const Icon(Icons.currency_rupee),
                              hintText: _selectedItem!.formattedPrice,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _customPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space3),
                    // Discount
                    TextField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Discount %',
                        prefixIcon: Icon(Icons.discount),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _discountPercent = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: AppTheme.space4),
                    // Calculated total
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: AppTheme.bodyMedium),
                          Text(
                            _calculateTotal(),
                            style: AppTheme.heading3.copyWith(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Order'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final isSelected = _selectedItem?.id == item.id;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedItem = item;
            _priceController.text = item.price.toString();
            _customPrice = null;
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Row(
            children: [
              // Item icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.itemType == 'SERVICE'
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.itemType == 'SERVICE'
                      ? Icons.design_services
                      : Icons.inventory_2,
                  color: item.itemType == 'SERVICE'
                      ? AppTheme.primaryBlue
                      : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space3),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTheme.bodyMediumBold),
                    const SizedBox(height: 2),
                    Text(
                      item.typeDisplay,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.formattedPrice,
                    style: AppTheme.bodyMediumBold.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    '+ ${item.taxPercent}% tax',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppTheme.space3),

              // Selection indicator
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateTotal() {
    if (_selectedItem == null) return '₹0.00';

    final price = _customPrice ?? _selectedItem!.price;
    final baseAmount = _quantity * price;
    final discount = baseAmount * (_discountPercent / 100);
    final afterDiscount = baseAmount - discount;
    final tax = afterDiscount * (_selectedItem!.taxPercent / 100);
    final total = afterDiscount + tax;

    return '₹${total.toStringAsFixed(2)}';
  }

  void _addItem() {
    if (_selectedItem == null) return;

    final orderItem = OrderItem.fromItem(
      orderId: widget.orderId,
      item: _selectedItem!,
      quantity: _quantity,
      customPrice: _customPrice,
      discountPercentage: _discountPercent,
    );

    Navigator.pop(context, orderItem);
  }
}
