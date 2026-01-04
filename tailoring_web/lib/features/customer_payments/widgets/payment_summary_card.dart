import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customer_payments/models/payment.dart';

class PaymentSummaryCard extends StatelessWidget {
  final PaymentSummary summary;

  const PaymentSummaryCard({Key? key, required this.summary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: AppTheme.heading3),
          const SizedBox(height: 16),
          // Total amount the customer was quoted
          _buildRow('Order Total', summary.totalAmount, AppTheme.textPrimary),
          const SizedBox(height: 8),

          // Actual payments received
          _buildRow('Paid', summary.totalPaid, AppTheme.success),

          if (summary.totalRefunded > 0) ...[
            const SizedBox(height: 8),
            // Subtraction from the paid amount
            _buildRow('Refunded', summary.totalRefunded, AppTheme.error),
          ],
          const Divider(height: 24),

          // Current status: Red if balance > 0, Green if 0 or less
          _buildRow(
            'Balance',
            summary.balance,
            summary.balance > 0 ? AppTheme.error : AppTheme.success,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: AppTheme.bodyMedium.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
