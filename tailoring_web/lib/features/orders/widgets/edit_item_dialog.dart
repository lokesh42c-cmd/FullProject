import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/orders/models/order_item.dart';

/// Edit Item Dialog
///
/// Edit quantity, price, and discount for order item
class EditItemDialog extends StatefulWidget {
  final OrderItem orderItem;

  const EditItemDialog({super.key, required this.orderItem});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;

  late double _quantity;
  late double _unitPrice;
  late double _discountPercent;

  @override
  void initState() {
    super.initState();
    _quantity = widget.orderItem.quantity;
    _unitPrice = widget.orderItem.unitPrice;
    _discountPercent = widget.orderItem.itemDiscountPercentage;

    _quantityController = TextEditingController(text: _quantity.toString());
    _priceController = TextEditingController(text: _unitPrice.toString());
    _discountController = TextEditingController(
      text: _discountPercent.toString(),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseAmount = _quantity * _unitPrice;
    final discountAmount = baseAmount * (_discountPercent / 100);
    final afterDiscount = baseAmount - discountAmount;
    final taxAmount = afterDiscount * (widget.orderItem.taxPercent / 100);
    final total = afterDiscount + taxAmount;

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                const Text('Edit Item', style: AppTheme.heading2),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Item name (read-only)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.orderItem.item?.itemType == 'SERVICE'
                        ? Icons.design_services
                        : Icons.inventory_2,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.orderItem.itemName,
                          style: AppTheme.bodyMediumBold,
                        ),
                        Text(
                          widget.orderItem.item?.typeDisplay ?? '',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quantity
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _quantity = double.tryParse(value) ?? 1;
                });
              },
            ),
            const SizedBox(height: 16),

            // Unit Price
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _unitPrice = double.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),

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
                  _discountPercent = double.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 24),

            // Calculation breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                children: [
                  _calculationRow('Base Amount', baseAmount),
                  if (discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _calculationRow(
                      'Discount',
                      discountAmount,
                      isNegative: true,
                      color: AppTheme.success,
                    ),
                  ],
                  const Divider(height: 24),
                  _calculationRow('After Discount', afterDiscount),
                  const SizedBox(height: 8),
                  _calculationRow(
                    'Tax (${widget.orderItem.taxPercent}%)',
                    taxAmount,
                  ),
                  const Divider(height: 24, thickness: 2),
                  _calculationRow('Total', total, bold: true, large: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Update Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calculationRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool bold = false,
    bool large = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: large
              ? AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)
              : bold
              ? AppTheme.bodyMediumBold
              : AppTheme.bodyMedium,
        ),
        Text(
          '${isNegative ? '-' : ''}₹${amount.toStringAsFixed(2)}',
          style: large
              ? AppTheme.heading3.copyWith(color: color ?? AppTheme.primaryBlue)
              : bold
              ? AppTheme.bodyMediumBold.copyWith(color: color)
              : AppTheme.bodyMedium.copyWith(color: color),
        ),
      ],
    );
  }

  void _save() {
    final updated = widget.orderItem.recalculate(
      newQuantity: _quantity,
      newUnitPrice: _unitPrice,
      newDiscountPercentage: _discountPercent,
    );

    Navigator.pop(context, updated);
  }
}
