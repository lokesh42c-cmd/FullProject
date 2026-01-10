import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order_item.dart';

class OrderSummaryPanel extends StatelessWidget {
  final List<OrderItem> items;
  final bool isTaxInclusive;
  final Function(bool) onTaxModeChanged;
  final VoidCallback onCreateOrder;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool canCreate;
  final bool showTaxToggle;

  const OrderSummaryPanel({
    super.key,
    required this.items,
    required this.isTaxInclusive,
    required this.onTaxModeChanged,
    required this.onCreateOrder,
    required this.onCancel,
    this.isLoading = false,
    this.canCreate = false,
    this.showTaxToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    // Standardized Variables
    double itemsGross = 0.0;
    double totalDiscount = 0.0;
    double totalTaxableValue = 0.0;
    double totalTaxAmount = 0.0;
    double grandTotal = 0.0;

    // Correct Mathematical Logic for both scenarios
    for (var item in items) {
      double lineGross = item.quantity * item.unitPrice;
      double lineNet = lineGross - item.discount;

      itemsGross += lineGross;
      totalDiscount += item.discount;

      if (isTaxInclusive) {
        // INCLUSIVE: Total is fixed. Taxable = Total / (1 + Rate)
        double taxable = lineNet / (1 + (item.taxPercentage / 100));
        totalTaxableValue += taxable;
        totalTaxAmount += (lineNet - taxable);
        grandTotal += lineNet;
      } else {
        // EXCLUSIVE: Base is fixed. Tax = Base * Rate
        double tax = lineNet * (item.taxPercentage / 100);
        totalTaxableValue += lineNet;
        totalTaxAmount += tax;
        grandTotal += (lineNet + tax);
      }
    }

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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER SUMMARY',
                    style: AppTheme.tableHeader.copyWith(
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (items.isNotEmpty) _buildItemBadge(items.length),

                  const SizedBox(height: 20),

                  // Fixed Labels as per your requirement
                  _summaryRow(
                    'Items Total (Gross)',
                    '₹${itemsGross.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),

                  if (totalDiscount > 0) ...[
                    _summaryRow(
                      'Total Discount',
                      '-₹${totalDiscount.toStringAsFixed(2)}',
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 8),
                  ],

                  const Divider(height: 24, thickness: 1),

                  // This label now correctly reflects the logic for both modes
                  _summaryRow(
                    'Taxable Value',
                    '₹${totalTaxableValue.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),

                  _summaryRow(
                    'Tax (GST)',
                    '₹${totalTaxAmount.toStringAsFixed(2)}',
                  ),

                  const Divider(height: 32, thickness: 2),

                  // Grand Total Section
                  _buildGrandTotal(grandTotal),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildItemBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count ${count == 1 ? "Item" : "Items"}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildGrandTotal(double total) {
    return Container(
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
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
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
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              child: const Text('Cancel'),
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
