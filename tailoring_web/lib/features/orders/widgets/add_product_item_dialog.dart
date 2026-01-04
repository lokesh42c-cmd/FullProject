import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/family_member.dart';
import '../models/inventory_item.dart';
import '../models/order_item.dart';
import '../providers/order_provider.dart';
import '../providers/create_order_provider.dart';

/// Dialog for adding a product/fabric item from inventory to order
class AddProductItemDialog extends StatefulWidget {
  final List<FamilyMember> familyMembers;
  final int? customerId;

  const AddProductItemDialog({
    super.key,
    required this.familyMembers,
    this.customerId,
  });

  @override
  State<AddProductItemDialog> createState() => _AddProductItemDialogState();
}

class _AddProductItemDialogState extends State<AddProductItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  // Form fields
  FamilyMember? _selectedFamilyMember;
  InventoryItem? _selectedProduct;
  double _quantity = 1.0;
  double _unitPrice = 0.0;
  double _discountPercentage = 0.0;
  double _taxPercentage = 5.0;
  String _notes = '';

  // Calculated values
  double _itemTotal = 0.0;

  @override
  void initState() {
    super.initState();
    // Load inventory items when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadInventoryItems();
    });

    // Auto-select family member if only one (and not SELF only)
    if (widget.familyMembers.length == 1) {
      _selectedFamilyMember = widget.familyMembers.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final subtotal = _unitPrice * _quantity;
    final discount = subtotal * (_discountPercentage / 100);
    final afterDiscount = subtotal - discount;
    final tax = afterDiscount * (_taxPercentage / 100);
    final total = afterDiscount + tax;

    setState(() {
      _itemTotal = total;
    });
  }

  void _onProductSelected(InventoryItem? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        // Auto-fill price, tax, and unit from product
        _unitPrice = product.sellingPrice;
        if (product.gstPercentage != null) {
          _taxPercentage = product.gstPercentage!;
        }
        _calculateTotal();
      }
    });
  }

  void _handleAddItem() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    // Check stock availability
    if (!_selectedProduct!.hasStock(_quantity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient stock. Available: ${_selectedProduct!.currentStock}${_selectedProduct!.unitDisplay}',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // Create order item
    final orderItem = OrderItem(
      familyMember: _selectedFamilyMember?.id,
      familyMemberName: _selectedFamilyMember?.name,
      familyMemberRelationship: _selectedFamilyMember?.relationship,
      category: _selectedProduct!.category ?? 0, // Will be set by backend
      categoryName: _selectedProduct!.categoryName,
      itemType: 'PRODUCT',
      itemDescription: _selectedProduct!.name,
      description: _notes.isNotEmpty ? _notes : null,
      inventoryItem: _selectedProduct!.id,
      inventoryItemName: _selectedProduct!.name,
      quantity: _quantity.toInt(),
      unit: _selectedProduct!.unit,
      unitPrice: _unitPrice,
      itemDiscountPercentage: _discountPercentage,
      taxPercentage: _taxPercentage,
      hsnCode: _selectedProduct!.hsnCode,
      notes: _notes.isNotEmpty ? _notes : null,
    );

    // Add to CreateOrderProvider
    context.read<CreateOrderProvider>().addItem(orderItem);

    // Close dialog
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final products = orderProvider.inventoryItems;
    final isLoadingProducts = orderProvider.isLoadingInventory;

    // Check if we should show family member dropdown
    final showFamilyMemberField =
        widget.familyMembers.length > 1 ||
        (widget.familyMembers.length == 1 &&
            widget.familyMembers.first.relationship != 'SELF');

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  const Text('Add Product/Fabric', style: AppTheme.heading2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space5),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Product
                      const Text('Search Product *', style: AppTheme.bodySmall),
                      const SizedBox(height: AppTheme.space2),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by name or SKU...',
                          prefixIcon: Icon(Icons.search, size: 18),
                        ),
                        onChanged: (value) {
                          // Search with debounce would be better, but for now:
                          if (value.length >= 2) {
                            context.read<OrderProvider>().searchInventoryItems(
                              value,
                            );
                          } else if (value.isEmpty) {
                            context.read<OrderProvider>().loadInventoryItems();
                          }
                        },
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Product Dropdown
                      const Text('Select Product *', style: AppTheme.bodySmall),
                      const SizedBox(height: AppTheme.space2),
                      isLoadingProducts
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<InventoryItem>(
                              value: _selectedProduct,
                              decoration: const InputDecoration(
                                hintText: 'Select from inventory',
                              ),
                              items: products.map((product) {
                                return DropdownMenuItem(
                                  value: product,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.name,
                                        style: AppTheme.bodyMedium,
                                      ),
                                      Text(
                                        '₹${product.sellingPrice.toStringAsFixed(0)}/${product.unitDisplay} • Stock: ${product.currentStock.toStringAsFixed(0)}${product.unitDisplay}',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: product.isLowStock
                                              ? AppTheme.warning
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: _onProductSelected,
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a product';
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: AppTheme.space4),

                      // Stock warning
                      if (_selectedProduct != null &&
                          _selectedProduct!.isLowStock)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space3),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.1),
                            border: Border.all(
                              color: AppTheme.warning.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                size: 16,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: AppTheme.space2),
                              Expanded(
                                child: Text(
                                  'Low stock: ${_selectedProduct!.currentStock.toStringAsFixed(0)}${_selectedProduct!.unitDisplay} available',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_selectedProduct != null &&
                          _selectedProduct!.isLowStock)
                        const SizedBox(height: AppTheme.space4),

                      // Family Member (conditional)
                      if (showFamilyMemberField) ...[
                        const Text(
                          'For Family Member',
                          style: AppTheme.bodySmall,
                        ),
                        const SizedBox(height: AppTheme.space2),
                        DropdownButtonFormField<FamilyMember>(
                          value: _selectedFamilyMember,
                          decoration: const InputDecoration(
                            hintText: 'Optional - select if applicable',
                          ),
                          items: widget.familyMembers.map((member) {
                            return DropdownMenuItem(
                              value: member,
                              child: Text(
                                member.displayName,
                                style: AppTheme.bodyMedium,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFamilyMember = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppTheme.space4),
                      ],

                      // Quantity and Unit Row
                      Row(
                        children: [
                          // Quantity
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quantity *',
                                  style: AppTheme.bodySmall,
                                ),
                                const SizedBox(height: AppTheme.space2),
                                TextFormField(
                                  initialValue: '1',
                                  decoration: const InputDecoration(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _quantity = double.tryParse(value) ?? 1.0;
                                    _calculateTotal();
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final qty = double.tryParse(value);
                                    if (qty == null || qty <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.space3),

                          // Unit (read-only)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Unit', style: AppTheme.bodySmall),
                                const SizedBox(height: AppTheme.space2),
                                Container(
                                  height: AppTheme.inputHeight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundGrey,
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _selectedProduct?.unitDisplay ?? '-',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Price Row
                      Row(
                        children: [
                          // Unit Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unit Price (₹) *',
                                  style: AppTheme.bodySmall,
                                ),
                                const SizedBox(height: AppTheme.space2),
                                TextFormField(
                                  initialValue: _unitPrice.toString(),
                                  decoration: const InputDecoration(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _unitPrice = double.tryParse(value) ?? 0.0;
                                    _calculateTotal();
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final price = double.tryParse(value);
                                    if (price == null || price < 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.space3),

                          // Discount %
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Discount (%)',
                                  style: AppTheme.bodySmall,
                                ),
                                const SizedBox(height: AppTheme.space2),
                                TextFormField(
                                  initialValue: '0',
                                  decoration: const InputDecoration(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _discountPercentage =
                                        double.tryParse(value) ?? 0.0;
                                    _calculateTotal();
                                  },
                                  validator: (value) {
                                    final discount = double.tryParse(
                                      value ?? '0',
                                    );
                                    if (discount != null &&
                                        (discount < 0 || discount > 100)) {
                                      return '0-100';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: AppTheme.space3),

                          // Tax %
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tax/GST (%)',
                                  style: AppTheme.bodySmall,
                                ),
                                const SizedBox(height: AppTheme.space2),
                                TextFormField(
                                  initialValue: _taxPercentage.toString(),
                                  decoration: const InputDecoration(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _taxPercentage =
                                        double.tryParse(value) ?? 0.0;
                                    _calculateTotal();
                                  },
                                  validator: (value) {
                                    final tax = double.tryParse(value ?? '0');
                                    if (tax != null && (tax < 0 || tax > 100)) {
                                      return '0-100';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Item Total
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space3),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Item Total:', style: AppTheme.bodyMediumBold),
                            Text(
                              '₹${_itemTotal.toStringAsFixed(2)}',
                              style: AppTheme.heading3.copyWith(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Notes
                      const Text('Special Notes', style: AppTheme.bodySmall),
                      const SizedBox(height: AppTheme.space2),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Any special instructions...',
                        ),
                        maxLines: 3,
                        onChanged: (value) => _notes = value,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.space3),
                  ElevatedButton(
                    onPressed: _handleAddItem,
                    child: const Text('Add Item'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
