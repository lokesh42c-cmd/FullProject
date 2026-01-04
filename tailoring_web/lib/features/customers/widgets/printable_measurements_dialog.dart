import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';

/// Printable Measurements Dialog
/// Displays measurements in a print-optimized layout
class PrintableMeasurementsDialog extends StatelessWidget {
  final Customer customer;

  const PrintableMeasurementsDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 800,
        height: 900,
        color: Colors.white,
        child: Column(
          children: [
            _buildPrintHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerInfo(),
                    const SizedBox(height: 32),
                    _buildMeasurementsTable(),
                    if (customer.measurementNotes != null &&
                        customer.measurementNotes!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildNotes(),
                    ],
                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
            _buildPrintActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Text('Print Measurements', style: AppTheme.heading2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MEASUREMENT RECORD',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'Date: ${DateTime.now().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black),
          const SizedBox(height: 16),
          _buildPrintRow('Customer Name:', customer.name, bold: true),
          _buildPrintRow('Phone:', customer.phone),
          if (customer.gender != null)
            _buildPrintRow('Gender:', customer.gender!),
          if (customer.email != null) _buildPrintRow('Email:', customer.email!),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'MEASUREMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'UNIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ..._buildAllMeasurementRows(),
        ],
      ),
    );
  }

  List<Widget> _buildAllMeasurementRows() {
    final rows = <Widget>[];

    // Basic Measurements
    _addMeasurementRow(rows, 'Height', customer.height, 'cm');
    _addMeasurementRow(rows, 'Weight', customer.weight, 'kg');
    _addMeasurementRow(rows, 'Shoulder Width', customer.shoulderWidth, 'inch');
    _addMeasurementRow(rows, 'Bust/Chest', customer.bustChest, 'inch');
    _addMeasurementRow(rows, 'Waist', customer.waist, 'inch');
    _addMeasurementRow(rows, 'Hip', customer.hip, 'inch');

    // Upper Body
    _addMeasurementRow(rows, 'Shoulder', customer.shoulder, 'inch');
    _addMeasurementRow(rows, 'Sleeve Length', customer.sleeveLength, 'inch');
    _addMeasurementRow(rows, 'Armhole', customer.armhole, 'inch');
    _addMeasurementRow(rows, 'Garment Length', customer.garmentLength, 'inch');
    _addMeasurementRow(
      rows,
      'Front Neck Depth',
      customer.frontNeckDepth,
      'inch',
    );
    _addMeasurementRow(rows, 'Back Neck Depth', customer.backNeckDepth, 'inch');

    // Gender-specific
    if (customer.gender == 'FEMALE') {
      _addMeasurementRow(rows, 'Upper Chest', customer.upperChest, 'inch');
      _addMeasurementRow(rows, 'Under Bust', customer.underBust, 'inch');
      _addMeasurementRow(
        rows,
        'Shoulder to Apex',
        customer.shoulderToApex,
        'inch',
      );
      _addMeasurementRow(
        rows,
        'Bust Point Distance',
        customer.bustPointDistance,
        'inch',
      );
      _addMeasurementRow(rows, 'Front Cross', customer.frontCross, 'inch');
      _addMeasurementRow(rows, 'Back Cross', customer.backCross, 'inch');
      _addMeasurementRow(
        rows,
        'Lehenga Length',
        customer.lehengaLength,
        'inch',
      );
      _addMeasurementRow(rows, 'Pant Waist', customer.pantWaist, 'inch');
      _addMeasurementRow(rows, 'Ankle Opening', customer.ankleOpening, 'inch');
    } else {
      _addMeasurementRow(rows, 'Neck Round', customer.neckRound, 'inch');
      _addMeasurementRow(rows, 'Stomach Round', customer.stomachRound, 'inch');
      _addMeasurementRow(rows, 'Yoke Width', customer.yokeWidth, 'inch');
      _addMeasurementRow(rows, 'Front Width', customer.frontWidth, 'inch');
      _addMeasurementRow(rows, 'Back Width', customer.backWidth, 'inch');
      _addMeasurementRow(rows, 'Trouser Waist', customer.trouserWaist, 'inch');
      _addMeasurementRow(rows, 'Front Rise', customer.frontRise, 'inch');
      _addMeasurementRow(rows, 'Back Rise', customer.backRise, 'inch');
      _addMeasurementRow(
        rows,
        'Bottom Opening',
        customer.bottomOpening,
        'inch',
      );
    }

    // Sleeves & Arms
    _addMeasurementRow(rows, 'Upper Arm/Bicep', customer.upperArmBicep, 'inch');
    _addMeasurementRow(rows, 'Sleeve Loose', customer.sleeveLoose, 'inch');
    _addMeasurementRow(rows, 'Wrist Round', customer.wristRound, 'inch');

    // Legs
    _addMeasurementRow(rows, 'Thigh', customer.thigh, 'inch');
    _addMeasurementRow(rows, 'Knee', customer.knee, 'inch');
    _addMeasurementRow(rows, 'Ankle', customer.ankle, 'inch');
    _addMeasurementRow(rows, 'Rise', customer.rise, 'inch');
    _addMeasurementRow(rows, 'Inseam', customer.inseam, 'inch');
    _addMeasurementRow(rows, 'Outseam', customer.outseam, 'inch');

    // Custom Fields
    _addMeasurementRow(rows, 'Custom 1', customer.customField1, 'inch');
    _addMeasurementRow(rows, 'Custom 2', customer.customField2, 'inch');
    _addMeasurementRow(rows, 'Custom 3', customer.customField3, 'inch');
    _addMeasurementRow(rows, 'Custom 4', customer.customField4, 'inch');
    _addMeasurementRow(rows, 'Custom 5', customer.customField5, 'inch');
    _addMeasurementRow(rows, 'Custom 6', customer.customField6, 'inch');
    _addMeasurementRow(rows, 'Custom 7', customer.customField7, 'inch');
    _addMeasurementRow(rows, 'Custom 8', customer.customField8, 'inch');
    _addMeasurementRow(rows, 'Custom 9', customer.customField9, 'inch');
    _addMeasurementRow(rows, 'Custom 10', customer.customField10, 'inch');

    return rows;
  }

  void _addMeasurementRow(
    List<Widget> rows,
    String label,
    double? value,
    String unit,
  ) {
    if (value == null) return;

    rows.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                unit,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            customer.measurementNotes!,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.black, thickness: 2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tailor Signature:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.black),
                ],
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Signature:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrintRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintActions(BuildContext context) {
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
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: const Text('Close'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement print functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print functionality coming soon'),
                  backgroundColor: AppTheme.info,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
          ),
        ],
      ),
    );
  }
}
