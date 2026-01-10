import 'package:flutter/material.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../widgets/general_settings_tab.dart';
import '../widgets/item_unit_settings.dart';

/// Settings Screen - Shop configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/settings',
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.space6),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Settings', style: AppTheme.heading1),
                      const SizedBox(height: AppTheme.space1),
                      Text(
                        'Configure your shop information and preferences',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Item Units Section
                  ItemUnitSettings(),
                  const SizedBox(height: 24),

                  // General Settings
                  const GeneralSettingsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
