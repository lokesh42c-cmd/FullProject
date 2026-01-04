import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

/// Simple Measurements Card
///
/// Shows measurement status for the customer
class MeasurementsCard extends StatelessWidget {
  final bool hasMeasurements;
  final DateTime? lastUpdated;
  final VoidCallback onView;
  final VoidCallback onAdd;

  const MeasurementsCard({
    super.key,
    required this.hasMeasurements,
    this.lastUpdated,
    required this.onView,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasMeasurements
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.straighten,
                  color: hasMeasurements ? AppTheme.success : AppTheme.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Measurements', style: AppTheme.headingSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          hasMeasurements
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: hasMeasurements
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasMeasurements ? 'Available' : 'Not Available',
                          style: AppTheme.bodySmall.copyWith(
                            color: hasMeasurements
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space4),

          // Last Updated (if has measurements)
          if (hasMeasurements && lastUpdated != null) ...[
            Text(
              'Last updated: ${_getTimeAgo(lastUpdated!)}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: AppTheme.space4),
          ],

          // Actions
          Row(
            children: [
              if (hasMeasurements) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onView, // Opens in edit mode
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Measurements'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return 'Just now';
    }
  }
}
