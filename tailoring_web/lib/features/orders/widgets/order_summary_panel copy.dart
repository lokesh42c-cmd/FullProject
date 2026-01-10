import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order_item.dart';

/// Order Summary Panel Widget
/// Right-side fixed panel showing order calculations and actions
class OrderSummaryPanel extends StatelessWidget {
  final List<OrderItem> items;
  final bool isTaxInclusive;
  final Function(bool) onTaxModeChanged;
  final VoidCallback onCreateOrder;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool canCreate;
  final bool showTaxToggle; // New parameter

  const OrderSummaryPanel({
    super.key,
    required this.items,
    required this.isTaxInclusive,
    required this.onTaxModeChanged,
    required this.onCreateOrder,
    required this.onCancel,
    this.isLoading = false,
    this.canCreate = false,
    this.showTaxToggle = true, // Default to true for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final itemsSubtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );

    final itemDiscounts = items.fold<double>(
      0.0,
      (sum, item) => sum + item.discount,
    );

    final taxableValue = itemsSubtotal - itemDiscounts;

    final totalTax = items.fold<double>(
      0.0,
      (sum, item) => sum + item.taxAmount,
    );

    final grandTotal = isTaxInclusive
        ? taxableValue
        : (taxableValue + totalTax);

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: const Border(left: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Scrollable summary section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'ORDER SUMMARY',
                    style: AppTheme.tableHeader.copyWith(
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Item count badge
                  if (items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length} ${items.length == 1 ? "Item" : "Items"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Subtotal
                  _summaryRow(
                    'Subtotal',
                    '₹${itemsSubtotal.toStringAsFixed(2)}',
                  ),

                  // Item discounts
                  if (itemDiscounts > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(
                      'Item Discounts',
                      '-₹${itemDiscounts.toStringAsFixed(2)}',
                      color: AppTheme.success,
                    ),
                  ],

                  const Divider(height: 32, thickness: 1),

                  // Tax mode toggle - only show if enabled
                  if (showTaxToggle)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tax Inclusive',
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: AppTheme.fontSemibold,
                              ),
                            ),
                          ),
                          Switch(
                            value: isTaxInclusive,
                            onChanged: onTaxModeChanged,
                            activeColor: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                    ),

                  if (showTaxToggle) const SizedBox(height: 16),

                  // Taxable value
                  _summaryRow(
                    isTaxInclusive ? 'Taxable Value' : 'After Discount',
                    '₹${taxableValue.toStringAsFixed(2)}',
                  ),

                  const SizedBox(height: 8),

                  // Tax amount
                  _summaryRow('Tax (GST)', '₹${totalTax.toStringAsFixed(2)}'),

                  const Divider(height: 32, thickness: 2),

                  // Grand total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryBlue, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GRAND TOTAL',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canCreate && !isLoading ? onCreateOrder : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(isLoading ? 'Creating...' : 'Create Order'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: color ?? AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: color ?? AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
