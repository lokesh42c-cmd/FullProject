import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

class MeasurementsTab extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const MeasurementsTab({Key? key, required this.orderData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final customerId = orderData['customer'];
    final customerName = orderData['customer_name'] ?? 'Customer';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Showing measurements for $customerName',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to customer detail
                    Navigator.pushNamed(context, '/customers/$customerId');
                  },
                  child: const Text('View Customer Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMeasurementsPlaceholder(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMeasurementsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.straighten, size: 64, color: AppTheme.borderLight),
            const SizedBox(height: 16),
            Text(
              'Measurements Feature',
              style: AppTheme.heading2.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer measurements will be displayed here',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This will show all measurement sets from the customer profile',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
