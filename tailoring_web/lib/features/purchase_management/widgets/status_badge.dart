import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        border: compact ? null : Border.all(color: config.color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        config.label,
        style: AppTheme.bodySmall.copyWith(
          color: config.color,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 10 : 11,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'UNPAID':
        return _StatusConfig(
          label: 'UNPAID',
          color: AppTheme.danger, // ✅ CORRECTED
        );
      case 'PARTIALLY_PAID':
        return _StatusConfig(
          label: 'PARTIAL',
          color: AppTheme.warning, // ✅ CORRECTED
        );
      case 'FULLY_PAID':
        return _StatusConfig(
          label: 'PAID',
          color: AppTheme.success, // ✅ CORRECTED
        );
      case 'ACTIVE':
        return _StatusConfig(
          label: 'ACTIVE',
          color: AppTheme.success, // ✅ CORRECTED
        );
      case 'INACTIVE':
        return _StatusConfig(label: 'INACTIVE', color: AppTheme.textSecondary);
      case 'PENDING':
        return _StatusConfig(
          label: 'PENDING',
          color: AppTheme.warning, // ✅ CORRECTED
        );
      case 'COMPLETED':
        return _StatusConfig(
          label: 'COMPLETED',
          color: AppTheme.success, // ✅ CORRECTED
        );
      case 'CANCELLED':
        return _StatusConfig(
          label: 'CANCELLED',
          color: AppTheme.danger, // ✅ CORRECTED
        );
      default:
        return _StatusConfig(
          label: status.toUpperCase(),
          color: AppTheme.textSecondary,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;

  _StatusConfig({required this.label, required this.color});
}
