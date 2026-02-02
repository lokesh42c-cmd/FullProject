import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/auth/providers/auth_provider.dart';

/// Company Details Header Widget
/// Displays company information from tenant data
/// Used at the top of invoice forms and detail screens
class CompanyDetailsHeader extends StatelessWidget {
  const CompanyDetailsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final tenant = authProvider.tenant;

    // If no tenant data, show placeholder
    if (tenant == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 12),
            Text(
              'Company details will appear here',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Name
          Text(
            tenant.name,
            style: AppTheme.heading3.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: 4),

          // Address
          Text(
            tenant.singleLineAddress,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),

          // Contact & GST Info Row
          Row(
            children: [
              // Phone
              if (tenant.phoneNumber.isNotEmpty) ...[
                Icon(Icons.phone, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  tenant.phoneNumber,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Email
              if (tenant.email.isNotEmpty) ...[
                Icon(Icons.email, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  tenant.email,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // GSTIN
              if (tenant.gstin != null && tenant.gstin!.isNotEmpty) ...[
                Icon(Icons.receipt_long, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'GSTIN: ${tenant.gstin}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: AppTheme.fontSemibold,
                  ),
                ),
              ],
            ],
          ),

          // Settings Link (if no GSTIN)
          if (tenant.gstin == null || tenant.gstin!.isEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // Navigate to settings
                Navigator.pushNamed(context, '/settings');
              },
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GSTIN not configured',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.warning),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• Configure in Settings',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
