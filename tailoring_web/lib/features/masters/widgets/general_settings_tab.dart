import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

/// General Settings Tab
///
/// Shop information and configuration
/// (To be implemented with actual settings)
class GeneralSettingsTab extends StatelessWidget {
  const GeneralSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coming Soon Card
          Container(
            padding: const EdgeInsets.all(AppTheme.space6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 64,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: AppTheme.space4),
                Text('General Settings', style: AppTheme.heading2),
                const SizedBox(height: AppTheme.space2),
                Text(
                  'Shop configuration coming soon',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // Placeholder for future settings
                Container(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Future Settings:', style: AppTheme.bodyMediumBold),
                      const SizedBox(height: AppTheme.space2),
                      _buildSettingItem('Shop Name & Logo'),
                      _buildSettingItem('GST Number & Tax Details'),
                      _buildSettingItem('Address & Contact Information'),
                      _buildSettingItem('Invoice Prefix & Numbering'),
                      _buildSettingItem('Business Hours'),
                      _buildSettingItem('Notification Preferences'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
