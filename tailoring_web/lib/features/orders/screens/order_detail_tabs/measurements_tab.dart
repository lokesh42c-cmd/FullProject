import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/customers/widgets/view_measurements_dialog.dart';
import 'package:tailoring_web/features/customers/widgets/measurement_dialog.dart';
import 'package:tailoring_web/features/customers/widgets/printable_measurements_dialog.dart';

class MeasurementsTab extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const MeasurementsTab({super.key, required this.orderData});

  @override
  State<MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends State<MeasurementsTab> {
  final _apiClient = ApiClient();
  Customer? _customer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customerId = widget.orderData['customer'];
      final response = await _apiClient.get('orders/customers/$customerId/');
      setState(() {
        _customer = Customer.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load customer measurements: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCustomer,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_customer!.hasMeasurements) {
      return _buildNoMeasurements();
    }

    return _buildMeasurements();
  }

  Widget _buildNoMeasurements() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.straighten, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'No Measurements Available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Customer ${_customer!.name} does not have measurements recorded yet.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onAddMeasurements,
              icon: const Icon(Icons.add),
              label: const Text('Add Measurements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurements() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildBasicSection(),
          const SizedBox(height: 16),
          _buildUpperBodySection(),
          const SizedBox(height: 16),
          _buildLowerBodySection(),
          const SizedBox(height: 16),
          _buildSleevesSection(),
          if (_hasCustomFields()) ...[
            const SizedBox(height: 16),
            _buildCustomSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.straighten,
                    color: AppTheme.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Measurements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Linked to: ${_customer!.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_customer!.gender != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _customer!.gender == 'FEMALE'
                                ? Colors.pink.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _customer!.gender == 'FEMALE' ? 'Female' : 'Male',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _customer!.gender == 'FEMALE'
                                  ? Colors.pink.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_customer!.updatedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: ${_formatDate(_customer!.updatedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _onViewFullDetails,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Full Details'),
                ),
                ElevatedButton.icon(
                  onPressed: _onEditMeasurements,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Measurements'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _onPrintMeasurements,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    final fields = [
      _MeasurementField('Height', _customer!.height, 'cm'),
      _MeasurementField('Weight', _customer!.weight, 'kg'),
      _MeasurementField('Bust/Chest', _customer!.bustChest, 'inch'),
      _MeasurementField('Waist', _customer!.waist, 'inch'),
      _MeasurementField('Hip', _customer!.hip, 'inch'),
      _MeasurementField('Shoulder Width', _customer!.shoulderWidth, 'inch'),
    ];

    return _buildSection(
      title: '📏 Basic Measurements',
      fields: fields,
      color: Colors.blue,
    );
  }

  Widget _buildUpperBodySection() {
    final commonFields = [
      _MeasurementField('Front Neck Depth', _customer!.frontNeckDepth, 'inch'),
      _MeasurementField('Back Neck Depth', _customer!.backNeckDepth, 'inch'),
      _MeasurementField('Shoulder', _customer!.shoulder, 'inch'),
      _MeasurementField('Armhole', _customer!.armhole, 'inch'),
      _MeasurementField('Garment Length', _customer!.garmentLength, 'inch'),
    ];

    final genderSpecific = _customer!.gender == 'FEMALE'
        ? [
            _MeasurementField('Upper Chest', _customer!.upperChest, 'inch'),
            _MeasurementField('Under Bust', _customer!.underBust, 'inch'),
            _MeasurementField(
              'Shoulder to Apex',
              _customer!.shoulderToApex,
              'inch',
            ),
            _MeasurementField(
              'Bust Point Distance',
              _customer!.bustPointDistance,
              'inch',
            ),
            _MeasurementField('Front Cross', _customer!.frontCross, 'inch'),
            _MeasurementField('Back Cross', _customer!.backCross, 'inch'),
          ]
        : [
            _MeasurementField('Neck Round', _customer!.neckRound, 'inch'),
            _MeasurementField('Stomach Round', _customer!.stomachRound, 'inch'),
            _MeasurementField('Yoke Width', _customer!.yokeWidth, 'inch'),
            _MeasurementField('Front Width', _customer!.frontWidth, 'inch'),
            _MeasurementField('Back Width', _customer!.backWidth, 'inch'),
          ];

    return _buildSection(
      title: '👕 Upper Body',
      fields: [...commonFields, ...genderSpecific],
      color: Colors.green,
    );
  }

  Widget _buildLowerBodySection() {
    final commonFields = [
      _MeasurementField('Thigh', _customer!.thigh, 'inch'),
      _MeasurementField('Knee', _customer!.knee, 'inch'),
      _MeasurementField('Ankle', _customer!.ankle, 'inch'),
      _MeasurementField('Rise', _customer!.rise, 'inch'),
      _MeasurementField('Inseam', _customer!.inseam, 'inch'),
      _MeasurementField('Outseam', _customer!.outseam, 'inch'),
    ];

    final genderSpecific = _customer!.gender == 'FEMALE'
        ? [
            _MeasurementField(
              'Lehenga Length',
              _customer!.lehengaLength,
              'inch',
            ),
            _MeasurementField('Pant Waist', _customer!.pantWaist, 'inch'),
            _MeasurementField('Ankle Opening', _customer!.ankleOpening, 'inch'),
          ]
        : [
            _MeasurementField('Trouser Waist', _customer!.trouserWaist, 'inch'),
            _MeasurementField('Front Rise', _customer!.frontRise, 'inch'),
            _MeasurementField('Back Rise', _customer!.backRise, 'inch'),
            _MeasurementField(
              'Bottom Opening',
              _customer!.bottomOpening,
              'inch',
            ),
          ];

    return _buildSection(
      title: '👖 Lower Body',
      fields: [...commonFields, ...genderSpecific],
      color: Colors.orange,
    );
  }

  Widget _buildSleevesSection() {
    final fields = [
      _MeasurementField('Sleeve Length', _customer!.sleeveLength, 'inch'),
      _MeasurementField('Upper Arm/Bicep', _customer!.upperArmBicep, 'inch'),
      _MeasurementField('Sleeve Loose', _customer!.sleeveLoose, 'inch'),
      _MeasurementField('Wrist Round', _customer!.wristRound, 'inch'),
    ];

    return _buildSection(
      title: '💪 Sleeves & Arms',
      fields: fields,
      color: Colors.purple,
    );
  }

  Widget _buildCustomSection() {
    final fields = <_MeasurementField>[];
    if (_customer!.customField1 != null)
      fields.add(
        _MeasurementField('Custom 1', _customer!.customField1, 'inch'),
      );
    if (_customer!.customField2 != null)
      fields.add(
        _MeasurementField('Custom 2', _customer!.customField2, 'inch'),
      );
    if (_customer!.customField3 != null)
      fields.add(
        _MeasurementField('Custom 3', _customer!.customField3, 'inch'),
      );
    if (_customer!.customField4 != null)
      fields.add(
        _MeasurementField('Custom 4', _customer!.customField4, 'inch'),
      );
    if (_customer!.customField5 != null)
      fields.add(
        _MeasurementField('Custom 5', _customer!.customField5, 'inch'),
      );

    return _buildSection(
      title: '⚙️ Custom Fields',
      fields: fields,
      color: Colors.grey,
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MeasurementField> fields,
    required Color color,
  }) {
    final nonEmptyFields = fields.where((f) => f.value != null).toList();
    if (nonEmptyFields.isEmpty) return const SizedBox.shrink();

    final titleColor = color == Colors.blue
        ? Colors.blue.shade800
        : color == Colors.green
        ? Colors.green.shade800
        : color == Colors.orange
        ? Colors.orange.shade800
        : color == Colors.purple
        ? Colors.purple.shade800
        : Colors.grey.shade800;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${nonEmptyFields.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              children: nonEmptyFields
                  .map((field) => _buildMeasurementCard(field))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(_MeasurementField field) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                field.value!.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  field.unit,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasCustomFields() {
    return _customer!.customField1 != null ||
        _customer!.customField2 != null ||
        _customer!.customField3 != null ||
        _customer!.customField4 != null ||
        _customer!.customField5 != null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _onViewFullDetails() {
    showDialog(
      context: context,
      builder: (context) => ViewMeasurementsDialog(customer: _customer!),
    );
  }

  void _onEditMeasurements() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MeasurementDialog(customer: _customer!),
    );

    if (result == true) {
      _loadCustomer();
    }
  }

  void _onAddMeasurements() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MeasurementDialog(customer: _customer!),
    );

    if (result == true) {
      _loadCustomer();
    }
  }

  void _onPrintMeasurements() {
    showDialog(
      context: context,
      builder: (context) => PrintableMeasurementsDialog(customer: _customer!),
    );
  }
}

class _MeasurementField {
  final String label;
  final double? value;
  final String unit;

  _MeasurementField(this.label, this.value, this.unit);
}
