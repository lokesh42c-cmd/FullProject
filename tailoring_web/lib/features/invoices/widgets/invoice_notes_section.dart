import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

/// Invoice Notes Section
/// Displays payment terms, bank details, and terms & conditions
/// Used at the bottom of invoice forms
class InvoiceNotesSection extends StatelessWidget {
  final TextEditingController notesController;
  final TextEditingController termsController;
  final bool readOnly;

  const InvoiceNotesSection({
    super.key,
    required this.notesController,
    required this.termsController,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.notes, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Additional Information',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notes Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes / Payment Terms',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      readOnly: readOnly,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Payment due within 15 days\nBank: HDFC Bank\nAccount: 12345678901234\nIFSC: HDFC0001234',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Terms & Conditions Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: termsController,
                      readOnly: readOnly,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            '1. Goods once sold will not be taken back\n2. Interest @18% p.a. will be charged if payment is delayed\n3. Subject to [City] jurisdiction only',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
