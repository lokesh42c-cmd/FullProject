import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/family_member.dart';
import '../models/item_category.dart';
import '../models/order_item.dart';
import '../providers/order_provider.dart';
import '../providers/create_order_provider.dart';

/// Dialog for adding a service item (stitching, alteration, etc.) to order
class AddServiceItemDialog extends StatefulWidget {
  final List<FamilyMember> familyMembers;
  final int? customerId;

  const AddServiceItemDialog({
    super.key,
    required this.familyMembers,
    this.customerId,
  });

  @override
  State<AddServiceItemDialog> createState() => _AddServiceItemDialogState();
}

class _AddServiceItemDialogState extends State<AddServiceItemDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  FamilyMember? _selectedFamilyMember;
  ItemCategory? _selectedCategory;
  int _quantity = 1;
  double _unitPrice = 0.0;
  double _discountPercentage = 0.0;
  double _taxPercentage = 5.0;
  String _description = '';
  String _notes = '';

  // Calculated values
  double _itemTotal = 0.0;

  @override
  void initState() {
    super.initState();
    // Load service categories when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadServiceCategories();
    });

    // Auto-select family member if only one (and not SELF only)
    if (widget.familyMembers.length == 1) {
      _selectedFamilyMember = widget.familyMembers.first;
    }
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

  void _onCategorySelected(ItemCategory? category) {
    setState(() {
      _selectedCategory = category;
      if (category != null) {
        // Auto-fill price and tax from category
        if (category.defaultPrice != null) {
          _unitPrice = category.defaultPrice!;
        }
        if (category.gstPercentage != null) {
          _taxPercentage = category.gstPercentage!;
        }
        _calculateTotal();
      }
    });
  }

  void _handleAddItem() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }

    // Create order item
    final orderItem = OrderItem(
      familyMember: _selectedFamilyMember?.id,
      familyMemberName: _selectedFamilyMember?.name,
      familyMemberRelationship: _selectedFamilyMember?.relationship,
      category: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      itemType: 'SERVICE',
      itemDescription: _description.isNotEmpty
          ? _description
          : _selectedCategory!.name,
      description: _notes.isNotEmpty ? _notes : null,
      quantity: _quantity,
      unitPrice: _unitPrice,
      itemDiscountPercentage: _discountPercentage,
      taxPercentage: _taxPercentage,
      hsnCode: _selectedCategory!.defaultHsnCode,
      notes: _notes.isNotEmpty ? _notes : null,
      // Measurements snapshot will be added if family member has measurements
      measurementsSnapshot: _selectedFamilyMember?.hasMeasurements == true
          ? {}
          : null,
    );

    // Add to CreateOrderProvider
    context.read<CreateOrderProvider>().addItem(orderItem);

    // Close dialog
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final categories = orderProvider.serviceCategories;
    final isLoadingCategories = orderProvider.isLoadingCategories;

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
                  const Text('Add Service Item', style: AppTheme.heading2),
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
                      // Family Member (conditional)
                      if (showFamilyMemberField) ...[
                        const Text(
                          'For Family Member *',
                          style: AppTheme.bodySmall,
                        ),
                        const SizedBox(height: AppTheme.space2),
                        DropdownButtonFormField<FamilyMember>(
                          value: _selectedFamilyMember,
                          decoration: const InputDecoration(
                            hintText: 'Select family member',
                          ),
                          items: widget.familyMembers.map((member) {
                            return DropdownMenuItem(
                              value: member,
                              child: Row(
                                children: [
                                  Text(
                                    member.displayName,
                                    style: AppTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: AppTheme.space2),
                                  // Measurements indicator
                                  if (member.hasMeasurements)
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: AppTheme.success,
                                    )
                                  else
                                    const Icon(
                                      Icons.warning_amber,
                                      size: 16,
                                      color: AppTheme.warning,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFamilyMember = value;
                            });
                          },
                          validator: (value) {
                            if (value == null && showFamilyMemberField) {
                              return 'Please select a family member';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space4),

                        // Measurements warning
                        if (_selectedFamilyMember != null &&
                            !_selectedFamilyMember!.hasMeasurements)
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
                                    'Measurements not available for ${_selectedFamilyMember!.name}',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppTheme.space4),
                      ],

                      // Service Type
                      const Text('Service Type *', style: AppTheme.bodySmall),
                      const SizedBox(height: AppTheme.space2),
                      isLoadingCategories
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<ItemCategory>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                hintText: 'Select service',
                              ),
                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category.displayWithPrice,
                                    style: AppTheme.bodyMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: _onCategorySelected,
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a service';
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: AppTheme.space4),

                      // Description (optional)
                      const Text(
                        'Description (Optional)',
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.space2),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'e.g., Bridal Blouse - Red Silk',
                        ),
                        maxLines: 2,
                        onChanged: (value) => _description = value,
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Quantity and Price Row
                      Row(
                        children: [
                          // Quantity
                          Expanded(
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
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    _quantity = int.tryParse(value) ?? 1;
                                    _calculateTotal();
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final qty = int.tryParse(value);
                                    if (qty == null || qty < 1) {
                                      return 'Min 1';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.space3),

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
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Discount and Tax Row
                      Row(
                        children: [
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
