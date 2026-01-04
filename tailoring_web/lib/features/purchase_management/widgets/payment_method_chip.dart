import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

class PaymentMethodChip extends StatelessWidget {
  final String method;
  final bool compact;
  final bool selectable;
  final bool isSelected;
  final VoidCallback? onTap;

  const PaymentMethodChip({
    super.key,
    required this.method,
    this.compact = false,
    this.selectable = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getMethodConfig(method);

    if (selectable) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? config.color.withOpacity(0.15)
                : config.color.withOpacity(0.05),
            border: Border.all(
              color: isSelected ? config.color : AppTheme.borderLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                config.icon,
                size: 24,
                color: isSelected ? config.color : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                config.label,
                style: AppTheme.bodySmall.copyWith(
                  color: isSelected ? config.color : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: compact ? 12 : 14, color: config.color),
          SizedBox(width: compact ? 2 : 4),
          Text(
            config.label,
            style: AppTheme.bodySmall.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  _MethodConfig _getMethodConfig(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return _MethodConfig(
          label: 'Cash',
          icon: Icons.money,
          color: AppTheme.success,
        );
      case 'UPI':
        return _MethodConfig(
          label: 'UPI',
          icon: Icons.phone_android,
          color: AppTheme.primaryBlue,
        );
      case 'BANK_TRANSFER':
        return _MethodConfig(
          label: 'Bank',
          icon: Icons.account_balance,
          color: AppTheme.primaryBlue,
        );
      case 'CARD':
        return _MethodConfig(
          label: 'Card',
          icon: Icons.credit_card,
          color: AppTheme.warning,
        );
      case 'CHEQUE':
        return _MethodConfig(
          label: 'Cheque',
          icon: Icons.receipt,
          color: AppTheme.textSecondary,
        );
      default:
        return _MethodConfig(
          label: method,
          icon: Icons.payment,
          color: AppTheme.textSecondary,
        );
    }
  }
}

class _MethodConfig {
  final String label;
  final IconData icon;
  final Color color;

  _MethodConfig({required this.label, required this.icon, required this.color});
}

/// Payment method selector widget (for forms)
class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final methods = ['CASH', 'UPI', 'BANK_TRANSFER', 'CARD', 'CHEQUE'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((method) {
        return PaymentMethodChip(
          method: method,
          selectable: true,
          isSelected: selectedMethod == method,
          onTap: () => onMethodSelected(method),
        );
      }).toList(),
    );
  }
}
