/// Read-Only Measurement Display Widget
/// Shows measurements organized in sections (like customer detail screen)
/// Location: lib/features/orders/widgets/measurement_display_widget.dart

import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

class MeasurementDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> measurements;
  final String? gender;

  const MeasurementDisplayWidget({
    super.key,
    required this.measurements,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out null and zero values
    final hasValues = measurements.values.any(
      (v) => v != null && v.toString() != '0' && v.toString() != '0.0',
    );

    if (!hasValues) {
      return _buildEmptyState();
    }

    final isFemale = gender == 'FEMALE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Measurements
        if (_hasBasicMeasurements())
          _buildSection(
            icon: Icons.person,
            title: 'Basic Measurements',
            color: AppTheme.primaryBlue,
            children: [
              _buildMeasurementGrid([
                _buildMeasurementItem('Height', measurements['height'], 'cm'),
                _buildMeasurementItem('Weight', measurements['weight'], 'kg'),
                _buildMeasurementItem(
                  isFemale ? 'Bust/Chest' : 'Chest',
                  measurements['bust_chest'],
                  'inch',
                ),
                _buildMeasurementItem('Waist', measurements['waist'], 'inch'),
                _buildMeasurementItem('Hip', measurements['hip'], 'inch'),
                _buildMeasurementItem(
                  'Shoulder Width',
                  measurements['shoulder_width'],
                  'inch',
                ),
              ]),
            ],
          ),

        if (_hasBasicMeasurements()) const SizedBox(height: 20),

        // Upper Body
        if (_hasUpperBodyMeasurements())
          _buildSection(
            icon: Icons.checkroom,
            title: 'Upper Body',
            color: AppTheme.success,
            children: [
              _buildMeasurementGrid([
                _buildMeasurementItem(
                  'Front Neck Depth',
                  measurements['front_neck_depth'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Back Neck Depth',
                  measurements['back_neck_depth'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Shoulder',
                  measurements['shoulder'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Armhole',
                  measurements['armhole'],
                  'inch',
                ),
                _buildMeasurementItem(
                  isFemale ? 'Blouse/Shirt Length' : 'Shirt Length',
                  measurements['blouse_length'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Neck Round',
                  measurements['neck_round'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Stomach Round',
                  measurements['stomach_round'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Yoke Width',
                  measurements['yoke_width'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Front Width',
                  measurements['front_width'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Back Width',
                  measurements['back_width'],
                  'inch',
                ),
              ]),
            ],
          ),

        if (_hasUpperBodyMeasurements()) const SizedBox(height: 20),

        // Sleeves & Arms
        if (_hasSleeveMeasurements())
          _buildSection(
            icon: Icons.gesture,
            title: 'Sleeves & Arms',
            color: AppTheme.warning,
            children: [
              _buildMeasurementGrid([
                _buildMeasurementItem(
                  'Sleeve Length',
                  measurements['sleeve_length'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Upper Arm/Bicep',
                  measurements['upper_arm_bicep'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Elbow Round',
                  measurements['elbow_round'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Wrist Round',
                  measurements['wrist_round'],
                  'inch',
                ),
              ]),
            ],
          ),

        if (_hasSleeveMeasurements()) const SizedBox(height: 20),

        // Lower Body
        if (_hasLowerBodyMeasurements())
          _buildSection(
            icon: Icons.airline_seat_legroom_normal,
            title: 'Lower Body',
            color: AppTheme.primaryBlue,
            children: [
              _buildMeasurementGrid([
                _buildMeasurementItem('Thigh', measurements['thigh'], 'inch'),
                _buildMeasurementItem('Knee', measurements['knee'], 'inch'),
                _buildMeasurementItem('Ankle', measurements['ankle'], 'inch'),
                _buildMeasurementItem('Rise', measurements['rise'], 'inch'),
                _buildMeasurementItem('Inseam', measurements['inseam'], 'inch'),
                _buildMeasurementItem(
                  'Outseam',
                  measurements['outseam'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Trouser Waist',
                  measurements['trouser_waist'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Front Rise',
                  measurements['front_rise'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Back Rise',
                  measurements['back_rise'],
                  'inch',
                ),
                _buildMeasurementItem(
                  'Bottom Opening',
                  measurements['bottom_opening'],
                  'inch',
                ),
              ]),
            ],
          ),

        // Notes
        if (measurements['notes'] != null &&
            measurements['notes'].toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notes,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notes',
                      style: AppTheme.bodySmallBold.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  measurements['notes'].toString(),
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _hasBasicMeasurements() {
    return _hasAnyValue([
      'height',
      'weight',
      'bust_chest',
      'waist',
      'hip',
      'shoulder_width',
    ]);
  }

  bool _hasUpperBodyMeasurements() {
    return _hasAnyValue([
      'front_neck_depth',
      'back_neck_depth',
      'shoulder',
      'armhole',
      'blouse_length',
      'neck_round',
      'stomach_round',
      'yoke_width',
      'front_width',
      'back_width',
    ]);
  }

  bool _hasSleeveMeasurements() {
    return _hasAnyValue([
      'sleeve_length',
      'upper_arm_bicep',
      'elbow_round',
      'wrist_round',
    ]);
  }

  bool _hasLowerBodyMeasurements() {
    return _hasAnyValue([
      'thigh',
      'knee',
      'ankle',
      'rise',
      'inseam',
      'outseam',
      'trouser_waist',
      'front_rise',
      'back_rise',
      'bottom_opening',
    ]);
  }

  bool _hasAnyValue(List<String> keys) {
    return keys.any((key) {
      final value = measurements[key];
      return value != null &&
          value.toString() != '0' &&
          value.toString() != '0.0' &&
          value.toString().isNotEmpty;
    });
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.bodyMediumBold.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMeasurementGrid(List<Widget?> items) {
    // Filter out null items
    final validItems = items.whereType<Widget>().toList();

    return Wrap(spacing: 40, runSpacing: 16, children: validItems);
  }

  Widget? _buildMeasurementItem(String label, dynamic value, String unit) {
    if (value == null ||
        value.toString() == '0' ||
        value.toString() == '0.0' ||
        value.toString().isEmpty) {
      return null;
    }

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toString()} $unit',
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            const Icon(Icons.straighten, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text('No measurements recorded', style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Measurements can be added in the Customers section',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
