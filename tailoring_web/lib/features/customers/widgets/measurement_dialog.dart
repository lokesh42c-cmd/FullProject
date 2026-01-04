import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';

class MeasurementDialog extends StatefulWidget {
  final Customer customer;

  const MeasurementDialog({super.key, required this.customer});

  @override
  State<MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<MeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  bool _isLoading = false;

  // Controllers for all measurement fields
  final Map<String, TextEditingController> _controllers = {};
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Basic & Common Measurements
    _createController('height', widget.customer.height);
    _createController('weight', widget.customer.weight);
    _createController('shoulder_width', widget.customer.shoulderWidth);
    _createController('bust_chest', widget.customer.bustChest);
    _createController('waist', widget.customer.waist);
    _createController('hip', widget.customer.hip);
    _createController('shoulder', widget.customer.shoulder);
    _createController('sleeve_length', widget.customer.sleeveLength);
    _createController('armhole', widget.customer.armhole);
    _createController('garment_length', widget.customer.garmentLength);

    // Women-Specific
    _createController('front_neck_depth', widget.customer.frontNeckDepth);
    _createController('back_neck_depth', widget.customer.backNeckDepth);
    _createController('upper_chest', widget.customer.upperChest);
    _createController('under_bust', widget.customer.underBust);
    _createController('shoulder_to_apex', widget.customer.shoulderToApex);
    _createController('bust_point_distance', widget.customer.bustPointDistance);
    _createController('front_cross', widget.customer.frontCross);
    _createController('back_cross', widget.customer.backCross);
    _createController('lehenga_length', widget.customer.lehengaLength);
    _createController('pant_waist', widget.customer.pantWaist);
    _createController('ankle_opening', widget.customer.ankleOpening);

    // Men-Specific
    _createController('neck_round', widget.customer.neckRound);
    _createController('stomach_round', widget.customer.stomachRound);
    _createController('yoke_width', widget.customer.yokeWidth);
    _createController('front_width', widget.customer.frontWidth);
    _createController('back_width', widget.customer.backWidth);
    _createController('trouser_waist', widget.customer.trouserWaist);
    _createController('front_rise', widget.customer.frontRise);
    _createController('back_rise', widget.customer.backRise);
    _createController('bottom_opening', widget.customer.bottomOpening);

    // Sleeves & Legs
    _createController('upper_arm_bicep', widget.customer.upperArmBicep);
    _createController('sleeve_loose', widget.customer.sleeveLoose);
    _createController('wrist_round', widget.customer.wristRound);
    _createController('thigh', widget.customer.thigh);
    _createController('knee', widget.customer.knee);
    _createController('ankle', widget.customer.ankle);
    _createController('rise', widget.customer.rise);
    _createController('inseam', widget.customer.inseam);
    _createController('outseam', widget.customer.outseam);

    // Custom Fields
    _createController('custom_field_1', widget.customer.customField1);
    _createController('custom_field_2', widget.customer.customField2);
    _createController('custom_field_3', widget.customer.customField3);
    _createController('custom_field_4', widget.customer.customField4);
    _createController('custom_field_5', widget.customer.customField5);
    _createController('custom_field_6', widget.customer.customField6);
    _createController('custom_field_7', widget.customer.customField7);
    _createController('custom_field_8', widget.customer.customField8);
    _createController('custom_field_9', widget.customer.customField9);
    _createController('custom_field_10', widget.customer.customField10);

    _notesController.text = widget.customer.measurementNotes ?? '';
  }

  void _createController(String key, double? value) {
    _controllers[key] = TextEditingController(text: value?.toString() ?? '');
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 1000,
        height: 700,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
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
                      const SizedBox(height: 24),
                      _buildCustomSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              Text(
                'Measurements - ${widget.customer.name}',
                style: AppTheme.heading2,
              ),
              Text(
                widget.customer.gender ?? 'Not specified',
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
        _MeasurementField('Height', 'height', 'cm'),
        _MeasurementField('Weight', 'weight', 'kg'),
        _MeasurementField('Bust/Chest', 'bust_chest', 'inch'),
        _MeasurementField('Waist', 'waist', 'inch'),
        _MeasurementField('Hip', 'hip', 'inch'),
        _MeasurementField('Shoulder Width', 'shoulder_width', 'inch'),
      ],
    );
  }

  Widget _buildUpperBodySection() {
    final commonFields = [
      _MeasurementField('Front Neck Depth', 'front_neck_depth', 'inch'),
      _MeasurementField('Back Neck Depth', 'back_neck_depth', 'inch'),
      _MeasurementField('Shoulder', 'shoulder', 'inch'),
      _MeasurementField('Armhole', 'armhole', 'inch'),
      _MeasurementField('Garment Length', 'garment_length', 'inch'),
    ];

    final genderSpecific = widget.customer.gender == 'FEMALE'
        ? [
            _MeasurementField('Upper Chest', 'upper_chest', 'inch'),
            _MeasurementField('Under Bust', 'under_bust', 'inch'),
            _MeasurementField('Shoulder to Apex', 'shoulder_to_apex', 'inch'),
            _MeasurementField(
              'Bust Point Distance',
              'bust_point_distance',
              'inch',
            ),
            _MeasurementField('Front Cross', 'front_cross', 'inch'),
            _MeasurementField('Back Cross', 'back_cross', 'inch'),
          ]
        : [
            _MeasurementField('Neck Round', 'neck_round', 'inch'),
            _MeasurementField('Stomach Round', 'stomach_round', 'inch'),
            _MeasurementField('Yoke Width', 'yoke_width', 'inch'),
            _MeasurementField('Front Width', 'front_width', 'inch'),
            _MeasurementField('Back Width', 'back_width', 'inch'),
          ];

    return _buildSection(
      title: '👕 Upper Body',
      fields: [...commonFields, ...genderSpecific],
    );
  }

  Widget _buildLowerBodySection() {
    final commonFields = [
      _MeasurementField('Thigh', 'thigh', 'inch'),
      _MeasurementField('Knee', 'knee', 'inch'),
      _MeasurementField('Ankle', 'ankle', 'inch'),
      _MeasurementField('Rise', 'rise', 'inch'),
      _MeasurementField('Inseam', 'inseam', 'inch'),
      _MeasurementField('Outseam', 'outseam', 'inch'),
    ];

    final genderSpecific = widget.customer.gender == 'FEMALE'
        ? [
            _MeasurementField('Lehenga Length', 'lehenga_length', 'inch'),
            _MeasurementField('Pant Waist', 'pant_waist', 'inch'),
            _MeasurementField('Ankle Opening', 'ankle_opening', 'inch'),
          ]
        : [
            _MeasurementField('Trouser Waist', 'trouser_waist', 'inch'),
            _MeasurementField('Front Rise', 'front_rise', 'inch'),
            _MeasurementField('Back Rise', 'back_rise', 'inch'),
            _MeasurementField('Bottom Opening', 'bottom_opening', 'inch'),
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
        _MeasurementField('Sleeve Length', 'sleeve_length', 'inch'),
        _MeasurementField('Upper Arm/Bicep', 'upper_arm_bicep', 'inch'),
        _MeasurementField('Sleeve Loose', 'sleeve_loose', 'inch'),
        _MeasurementField('Wrist Round', 'wrist_round', 'inch'),
      ],
    );
  }

  Widget _buildCustomSection() {
    return _buildSection(
      title: '⚙️ Custom Fields',
      fields: [
        _MeasurementField('Custom 1', 'custom_field_1', 'inch'),
        _MeasurementField('Custom 2', 'custom_field_2', 'inch'),
        _MeasurementField('Custom 3', 'custom_field_3', 'inch'),
        _MeasurementField('Custom 4', 'custom_field_4', 'inch'),
        _MeasurementField('Custom 5', 'custom_field_5', 'inch'),
        _MeasurementField('Custom 6', 'custom_field_6', 'inch'),
        _MeasurementField('Custom 7', 'custom_field_7', 'inch'),
        _MeasurementField('Custom 8', 'custom_field_8', 'inch'),
        _MeasurementField('Custom 9', 'custom_field_9', 'inch'),
        _MeasurementField('Custom 10', 'custom_field_10', 'inch'),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📝 Notes', style: AppTheme.heading3),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add any special notes or instructions...',
          ),
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MeasurementField> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              children: fields
                  .map((field) => _buildMeasurementField(field))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementField(_MeasurementField field) {
    return SizedBox(
      width: 180,
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controllers[field.key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.0',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: AppTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildFooter() {
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
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveMeasurements,
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Measurements'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeasurements() async {
    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{};

      // Add all measurements
      _controllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          data[key] = double.tryParse(controller.text);
        }
      });

      // Add notes
      if (_notesController.text.isNotEmpty) {
        data['measurement_notes'] = _notesController.text.trim();
      }

      await _apiClient.patch(
        'orders/customers/${widget.customer.id}/',
        data: data,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurements saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _MeasurementField {
  final String label;
  final String key;
  final String unit;

  _MeasurementField(this.label, this.key, this.unit);
}
