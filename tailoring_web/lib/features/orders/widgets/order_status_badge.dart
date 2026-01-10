import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Order Status Badge Widget
/// Displays order status with appropriate color coding
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isDeliveryStatus;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isDeliveryStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeData = _getBadgeData();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeData['bgColor'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeData['label'],
        style: TextStyle(
          color: badgeData['textColor'],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Map<String, dynamic> _getBadgeData() {
    if (isDeliveryStatus) {
      return _getDeliveryStatusData();
    }
    return _getOrderStatusData();
  }

  Map<String, dynamic> _getOrderStatusData() {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return {
          'label': 'Draft',
          'bgColor': AppTheme.textMuted.withOpacity(0.1),
          'textColor': AppTheme.textMuted,
        };
      case 'CONFIRMED':
        return {
          'label': 'Confirmed',
          'bgColor': AppTheme.info.withOpacity(0.1),
          'textColor': AppTheme.info,
        };
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return {
          'label': 'In Progress',
          'bgColor': AppTheme.primaryBlue.withOpacity(0.1),
          'textColor': AppTheme.primaryBlue,
        };
      case 'READY':
        return {
          'label': 'Ready',
          'bgColor': AppTheme.warning.withOpacity(0.1),
          'textColor': AppTheme.warning,
        };
      case 'COMPLETED':
        return {
          'label': 'Completed',
          'bgColor': AppTheme.success.withOpacity(0.1),
          'textColor': AppTheme.success,
        };
      case 'CANCELLED':
        return {
          'label': 'Cancelled',
          'bgColor': AppTheme.danger.withOpacity(0.1),
          'textColor': AppTheme.danger,
        };
      default:
        return {
          'label': status,
          'bgColor': AppTheme.textMuted.withOpacity(0.1),
          'textColor': AppTheme.textMuted,
        };
    }
  }

  Map<String, dynamic> _getDeliveryStatusData() {
    switch (status.toUpperCase()) {
      case 'NOT_STARTED':
      case 'NOTSTARTED':
        return {
          'label': 'Not Started',
          'bgColor': AppTheme.textMuted.withOpacity(0.1),
          'textColor': AppTheme.textMuted,
        };
      case 'PARTIAL':
        return {
          'label': 'Partial',
          'bgColor': AppTheme.warning.withOpacity(0.1),
          'textColor': AppTheme.warning,
        };
      case 'DELIVERED':
        return {
          'label': 'Delivered',
          'bgColor': AppTheme.success.withOpacity(0.1),
          'textColor': AppTheme.success,
        };
      default:
        return {
          'label': status,
          'bgColor': AppTheme.textMuted.withOpacity(0.1),
          'textColor': AppTheme.textMuted,
        };
    }
  }
}
