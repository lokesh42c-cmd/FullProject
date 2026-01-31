import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../models/payment_transaction.dart';

class UpdateDepositDialog extends StatelessWidget {
  final PaymentTransaction transaction;
  final bool isUpdating;
  final VoidCallback onConfirm;

  const UpdateDepositDialog({
    super.key,
    required this.transaction,
    required this.onConfirm,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance,
                color: AppTheme.success,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Confirm Bank Deposit', style: AppTheme.heading2),
            const SizedBox(height: 8),
            Text(
              'Are you moving this cash amount to the bank?',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Transaction Details Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  _detailRow('Transaction', transaction.transactionNumber),
                  const Divider(height: 24),
                  _detailRow('Customer', transaction.customerName),
                  const Divider(height: 24),
                  _detailRow(
                    'Amount',
                    transaction.formattedAmount,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isUpdating ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Deposit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
