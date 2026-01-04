import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/models/expense.dart';
import 'package:tailoring_web/features/purchase_management/widgets/status_badge.dart';
import 'package:intl/intl.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onPayNow;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space3),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category and status
            Row(
              children: [
                _getCategoryIcon(expense.category),
                const SizedBox(width: AppTheme.space2),
                Expanded(
                  child: Text(
                    expense.categoryDisplay ?? expense.category,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(status: expense.paymentStatus, compact: true),
              ],
            ),
            const SizedBox(height: AppTheme.space2),

            // Date and description
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(expense.expenseDate),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (expense.description != null &&
                expense.description!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space2),
              Text(
                expense.description!,
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppTheme.space3),

            // Amount display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  currencyFormat.format(expense.expenseAmountDouble),
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (expense.balanceAmountDouble > 0) ...[
              const SizedBox(height: AppTheme.space1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    currencyFormat.format(expense.balanceAmountDouble),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Pay button
            if (expense.balanceAmountDouble > 0 && onPayNow != null) ...[
              const SizedBox(height: AppTheme.space3),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPayNow,
                  icon: const Icon(Icons.payment, size: 14),
                  label: const Text('Pay Now'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;

    switch (category.toUpperCase()) {
      case 'RENT':
        icon = Icons.home;
        color = AppTheme.primaryBlue;
        break;
      case 'ELECTRICITY':
        icon = Icons.bolt;
        color = AppTheme.warning;
        break;
      case 'WATER':
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'TEA_SNACKS':
        icon = Icons.coffee;
        color = Colors.brown;
        break;
      case 'TRANSPORT':
        icon = Icons.directions_car;
        color = Colors.teal;
        break;
      case 'REPAIRS':
        icon = Icons.build;
        color = Colors.orange;
        break;
      case 'SUPPLIES':
        icon = Icons.inventory;
        color = Colors.purple;
        break;
      case 'MARKETING':
        icon = Icons.campaign;
        color = Colors.pink;
        break;
      default:
        icon = Icons.receipt;
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

/// Compact expense card for lists
class ExpenseCardCompact extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCardCompact({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: AppTheme.space2,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            _getCategoryIcon(expense.category),
            const SizedBox(width: AppTheme.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        expense.categoryDisplay ?? expense.category,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space2),
                      StatusBadge(status: expense.paymentStatus, compact: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${expense.description ?? 'No description'} • ${dateFormat.format(expense.expenseDate)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.space2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(expense.expenseAmountDouble),
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expense.balanceAmountDouble > 0)
                  Text(
                    'Bal: ${currencyFormat.format(expense.balanceAmountDouble)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.danger,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;

    switch (category.toUpperCase()) {
      case 'RENT':
        icon = Icons.home;
        color = AppTheme.primaryBlue;
        break;
      case 'ELECTRICITY':
        icon = Icons.bolt;
        color = AppTheme.warning;
        break;
      case 'WATER':
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'TEA_SNACKS':
        icon = Icons.coffee;
        color = Colors.brown;
        break;
      case 'TRANSPORT':
        icon = Icons.directions_car;
        color = Colors.teal;
        break;
      case 'REPAIRS':
        icon = Icons.build;
        color = Colors.orange;
        break;
      default:
        icon = Icons.receipt;
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
