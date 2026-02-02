import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/invoices/models/invoice.dart';

/// Invoice Summary Panel - UPDATED
/// Displays financial summary with tax calculations (Exclusive/Inclusive)
/// Exact same logic as Order screen
class InvoiceSummaryPanel extends StatelessWidget {
  final List<InvoiceItem> items;
  final bool isTaxInclusive;
  final double? advanceAdjusted;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSaveDraft;
  final VoidCallback? onIssueInvoice;

  const InvoiceSummaryPanel({
    super.key,
    required this.items,
    required this.isTaxInclusive,
    this.advanceAdjusted,
    this.isSaving = false,
    required this.onCancel,
    required this.onSaveDraft,
    this.onIssueInvoice,
  });

  @override
  Widget build(BuildContext context) {
    // Exact same calculation logic as Order screen
    double itemsGross = 0.0;
    double totalDiscount = 0.0;
    double totalTaxableValue = 0.0;
    double totalTaxAmount = 0.0;
    double grandTotal = 0.0;

    for (var item in items) {
      double lineGross = item.quantity * item.unitPrice;
      double lineNet = lineGross - (item.discount ?? 0.0);

      itemsGross += lineGross;
      totalDiscount += (item.discount ?? 0.0);

      if (isTaxInclusive) {
        // INCLUSIVE: Total is fixed. Taxable = Total / (1 + Rate)
        double taxable = lineNet / (1 + (item.gstRate / 100));
        totalTaxableValue += taxable;
        totalTaxAmount += (lineNet - taxable);
        grandTotal += lineNet;
      } else {
        // EXCLUSIVE: Base is fixed. Tax = Base * Rate
        double tax = lineNet * (item.gstRate / 100);
        totalTaxableValue += lineNet;
        totalTaxAmount += tax;
        grandTotal += (lineNet + tax);
      }
    }

    final balanceDue = grandTotal - (advanceAdjusted ?? 0.0);

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
                    'INVOICE SUMMARY',
                    style: AppTheme.tableHeader.copyWith(
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Item count badge
                  if (items.isNotEmpty) _buildItemBadge(items.length),
                  const SizedBox(height: 20),

                  // Financial breakdown
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

                  // Grand Total
                  _buildGrandTotal(grandTotal),

                  // Advance & Balance Due
                  if (advanceAdjusted != null && advanceAdjusted! > 0) ...[
                    const SizedBox(height: 16),
                    _summaryRow(
                      'Advance Adjusted',
                      '-₹${advanceAdjusted!.toStringAsFixed(2)}',
                      color: AppTheme.success,
                    ),
                    const Divider(height: 24, thickness: 1),
                    _summaryRow(
                      'Balance Due',
                      '₹${balanceDue.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
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
          // Issue Invoice Button (primary)
          if (onIssueInvoice != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onIssueInvoice,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 18),
                label: Text(isSaving ? 'Issuing...' : 'Issue Invoice'),
              ),
            ),

          if (onIssueInvoice != null) const SizedBox(height: 8),

          // Save Draft Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onSaveDraft,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save as Draft'),
            ),
          ),
          const SizedBox(height: 8),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: color ?? AppTheme.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: color ?? AppTheme.textPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
