import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';

/// Read-only measurements view dialog
class ViewMeasurementsDialog extends StatelessWidget {
  final Customer customer;

  const ViewMeasurementsDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 900,
        height: 700,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicSection(),
                    const SizedBox(height: 24),
                    _buildUpperBodySection(),
                    const SizedBox(height: 24),
                    _buildLowerBodySection(),
                    const SizedBox(height: 24),
                    _buildSleevesSection(),
                    if (_hasCustomFields()) ...[
                      const SizedBox(height: 24),
                      _buildCustomSection(),
                    ],
                    if (customer.measurementNotes != null &&
                        customer.measurementNotes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Measurements - ${customer.name}', style: AppTheme.heading2),
              Text(
                customer.gender ?? 'Not specified',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSection() {
    return _buildSection(
      title: '📏 Basic Measurements',
      fields: [
        _ViewField('Height', customer.height, 'cm'),
        _ViewField('Weight', customer.weight, 'kg'),
        _ViewField('Bust/Chest', customer.bustChest, 'inch'),
        _ViewField('Waist', customer.waist, 'inch'),
        _ViewField('Hip', customer.hip, 'inch'),
        _ViewField('Shoulder Width', customer.shoulderWidth, 'inch'),
      ],
    );
  }

  Widget _buildUpperBodySection() {
    final commonFields = [
      _ViewField('Front Neck Depth', customer.frontNeckDepth, 'inch'),
      _ViewField('Back Neck Depth', customer.backNeckDepth, 'inch'),
      _ViewField('Shoulder', customer.shoulder, 'inch'),
      _ViewField('Armhole', customer.armhole, 'inch'),
      _ViewField('Garment Length', customer.garmentLength, 'inch'),
    ];

    final genderSpecific = customer.gender == 'FEMALE'
        ? [
            _ViewField('Upper Chest', customer.upperChest, 'inch'),
            _ViewField('Under Bust', customer.underBust, 'inch'),
            _ViewField('Shoulder to Apex', customer.shoulderToApex, 'inch'),
            _ViewField(
              'Bust Point Distance',
              customer.bustPointDistance,
              'inch',
            ),
            _ViewField('Front Cross', customer.frontCross, 'inch'),
            _ViewField('Back Cross', customer.backCross, 'inch'),
          ]
        : [
            _ViewField('Neck Round', customer.neckRound, 'inch'),
            _ViewField('Stomach Round', customer.stomachRound, 'inch'),
            _ViewField('Yoke Width', customer.yokeWidth, 'inch'),
            _ViewField('Front Width', customer.frontWidth, 'inch'),
            _ViewField('Back Width', customer.backWidth, 'inch'),
          ];

    return _buildSection(
      title: '👕 Upper Body',
      fields: [...commonFields, ...genderSpecific],
    );
  }

  Widget _buildLowerBodySection() {
    final commonFields = [
      _ViewField('Thigh', customer.thigh, 'inch'),
      _ViewField('Knee', customer.knee, 'inch'),
      _ViewField('Ankle', customer.ankle, 'inch'),
      _ViewField('Rise', customer.rise, 'inch'),
      _ViewField('Inseam', customer.inseam, 'inch'),
      _ViewField('Outseam', customer.outseam, 'inch'),
    ];

    final genderSpecific = customer.gender == 'FEMALE'
        ? [
            _ViewField('Lehenga Length', customer.lehengaLength, 'inch'),
            _ViewField('Pant Waist', customer.pantWaist, 'inch'),
            _ViewField('Ankle Opening', customer.ankleOpening, 'inch'),
          ]
        : [
            _ViewField('Trouser Waist', customer.trouserWaist, 'inch'),
            _ViewField('Front Rise', customer.frontRise, 'inch'),
            _ViewField('Back Rise', customer.backRise, 'inch'),
            _ViewField('Bottom Opening', customer.bottomOpening, 'inch'),
          ];

    return _buildSection(
      title: '👖 Lower Body',
      fields: [...commonFields, ...genderSpecific],
    );
  }

  Widget _buildSleevesSection() {
    return _buildSection(
      title: '💪 Sleeves & Arms',
      fields: [
        _ViewField('Sleeve Length', customer.sleeveLength, 'inch'),
        _ViewField('Upper Arm/Bicep', customer.upperArmBicep, 'inch'),
        _ViewField('Sleeve Loose', customer.sleeveLoose, 'inch'),
        _ViewField('Wrist Round', customer.wristRound, 'inch'),
      ],
    );
  }

  Widget _buildCustomSection() {
    final fields = <_ViewField>[];
    if (customer.customField1 != null)
      fields.add(_ViewField('Custom 1', customer.customField1, 'inch'));
    if (customer.customField2 != null)
      fields.add(_ViewField('Custom 2', customer.customField2, 'inch'));
    if (customer.customField3 != null)
      fields.add(_ViewField('Custom 3', customer.customField3, 'inch'));
    if (customer.customField4 != null)
      fields.add(_ViewField('Custom 4', customer.customField4, 'inch'));
    if (customer.customField5 != null)
      fields.add(_ViewField('Custom 5', customer.customField5, 'inch'));
    if (customer.customField6 != null)
      fields.add(_ViewField('Custom 6', customer.customField6, 'inch'));
    if (customer.customField7 != null)
      fields.add(_ViewField('Custom 7', customer.customField7, 'inch'));
    if (customer.customField8 != null)
      fields.add(_ViewField('Custom 8', customer.customField8, 'inch'));
    if (customer.customField9 != null)
      fields.add(_ViewField('Custom 9', customer.customField9, 'inch'));
    if (customer.customField10 != null)
      fields.add(_ViewField('Custom 10', customer.customField10, 'inch'));

    return _buildSection(title: '⚙️ Custom Fields', fields: fields);
  }

  Widget _buildNotesSection() {
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
          const Text('📝 Notes', style: AppTheme.heading3),
          const SizedBox(height: 8),
          Text(customer.measurementNotes!, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_ViewField> fields,
  }) {
    // Filter out fields with no values
    final nonEmptyFields = fields.where((f) => f.value != null).toList();

    if (nonEmptyFields.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundGray,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusSmall),
                topRight: Radius.circular(AppTheme.radiusSmall),
              ),
            ),
            child: Text(title, style: AppTheme.heading3),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              children: nonEmptyFields
                  .map((field) => _buildViewField(field))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewField(_ViewField field) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                field.value?.toString() ?? '-',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                field.unit,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: const Text('Close'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop(context, true), // Return true = open edit
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Measurements'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 40)),
          ),
        ],
      ),
    );
  }

  bool _hasCustomFields() {
    return customer.customField1 != null ||
        customer.customField2 != null ||
        customer.customField3 != null ||
        customer.customField4 != null ||
        customer.customField5 != null ||
        customer.customField6 != null ||
        customer.customField7 != null ||
        customer.customField8 != null ||
        customer.customField9 != null ||
        customer.customField10 != null;
  }
}

class _ViewField {
  final String label;
  final double? value;
  final String unit;

  _ViewField(this.label, this.value, this.unit);
}
