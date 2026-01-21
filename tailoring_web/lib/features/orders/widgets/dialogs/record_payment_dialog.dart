import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final Function(Map<String, dynamic>) onPaymentRecorded;

  const RecordPaymentDialog({
    Key? key,
    required this.orderData,
    required this.onPaymentRecorded,
  }) : super(key: key);

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  String _selectedMode = 'CASH';
  bool _isCalculating = false;
  Map<String, dynamic>? _taxBreakdown;

  final List<Map<String, String>> _paymentModes = [
    {'value': 'CASH', 'label': 'Cash'},
    {'value': 'CARD', 'label': 'Card'},
    {'value': 'UPI', 'label': 'UPI'},
    {'value': 'BANK_TRANSFER', 'label': 'Bank Transfer'},
    {'value': 'CHEQUE', 'label': 'Cheque'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _calculateTax(String amountText) async {
    if (amountText.isEmpty) {
      setState(() => _taxBreakdown = null);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _taxBreakdown = null);
      return;
    }

    setState(() => _isCalculating = true);

    try {
      // TODO: Replace with actual API call
      // final response = await dio.post(
      //   '/api/orders/${widget.orderData['id']}/calculate-advance-tax/',
      //   data: {'amount': amount},
      // );
      // _taxBreakdown = response.data;

      // Mock calculation for now
      await Future.delayed(const Duration(milliseconds: 300));

      final breakdown = _calculateWeightedAverageTax(amount);

      setState(() {
        _taxBreakdown = breakdown;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _taxBreakdown = null;
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to calculate tax: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _calculateWeightedAverageTax(double amount) {
    // Get tenant GST setting
    final gstEnabled = widget.orderData['tenant']?['gst_enabled'] ?? true;

    if (!gstEnabled) {
      return {
        'total_amount': amount,
        'base_amount': amount,
        'tax_percent': 0.0,
        'gst_amount': 0.0,
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': 0.0,
        'tax_type': 'ZERO',
      };
    }

    // Calculate weighted average from order items
    final items = (widget.orderData['items'] as List?) ?? [];
    if (items.isEmpty) {
      return {
        'total_amount': amount,
        'base_amount': amount,
        'tax_percent': 0.0,
        'gst_amount': 0.0,
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': 0.0,
        'tax_type': 'ZERO',
      };
    }

    // Calculate total order value
    double totalOrderValue = 0.0;
    for (var item in items) {
      totalOrderValue += (item['total_amount'] ?? 0.0) as double;
    }

    if (totalOrderValue == 0) {
      return {
        'total_amount': amount,
        'base_amount': amount,
        'tax_percent': 0.0,
        'gst_amount': 0.0,
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': 0.0,
        'tax_type': 'ZERO',
      };
    }

    // Calculate weighted average tax rate
    double weightedTaxRate = 0.0;
    for (var item in items) {
      final itemAmount = (item['total_amount'] ?? 0.0) as double;
      final taxPercent = (item['tax_percent'] ?? 0.0) as double;
      final weight = itemAmount / totalOrderValue;
      weightedTaxRate += weight * taxPercent;
    }

    // Round to nearest standard GST rate
    final standardRates = [0.0, 5.0, 12.0, 18.0, 28.0];
    double roundedRate = standardRates.reduce((curr, next) {
      return (curr - weightedTaxRate).abs() < (next - weightedTaxRate).abs()
          ? curr
          : next;
    });

    // Reverse calculate base amount from inclusive total
    final divisor = 1 + (roundedRate / 100);
    final baseAmount = amount / divisor;
    final gstAmount = amount - baseAmount;

    // Determine tax type (CGST+SGST or IGST)
    final tenantState = widget.orderData['tenant']?['state'];
    final customerState = widget.orderData['customer']?['state'];
    final isIntrastate = tenantState == customerState;

    return {
      'total_amount': amount,
      'base_amount': baseAmount,
      'tax_percent': roundedRate,
      'gst_amount': gstAmount,
      'cgst': isIntrastate ? gstAmount / 2 : 0.0,
      'sgst': isIntrastate ? gstAmount / 2 : 0.0,
      'igst': !isIntrastate ? gstAmount : 0.0,
      'tax_type': isIntrastate ? 'INTRASTATE' : 'INTERSTATE',
    };
  }

  Future<void> _onRecordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_taxBreakdown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // TODO: Replace with actual API call
      // final response = await dio.post(
      //   '/api/orders/${widget.orderData['id']}/receipt-vouchers/',
      //   data: {
      //     'advance_amount': _taxBreakdown!['base_amount'],
      //     'cgst': _taxBreakdown!['cgst'],
      //     'sgst': _taxBreakdown!['sgst'],
      //     'igst': _taxBreakdown!['igst'],
      //     'total_amount': _taxBreakdown!['total_amount'],
      //     'payment_mode': _selectedMode,
      //     'transaction_reference': _referenceController.text.trim(),
      //   },
      // );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentRecorded(_taxBreakdown!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gstEnabled = widget.orderData['tenant']?['gst_enabled'] ?? true;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record Advance Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: gstEnabled
                          ? 'Amount Received (incl. GST)'
                          : 'Amount Received',
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                      helperText: gstEnabled
                          ? 'Enter total amount including tax'
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                    onChanged: _calculateTax,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: _paymentModes.map((mode) {
                      return DropdownMenuItem(
                        value: mode['value'],
                        child: Text(mode['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Reference (Optional)',
                      border: OutlineInputBorder(),
                      helperText: 'UPI ID, transaction ID, cheque number, etc.',
                    ),
                  ),
                  if (_taxBreakdown != null || _isCalculating) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildTaxBreakdown(context),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _onRecordPayment,
                        child: const Text('Record Payment'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaxBreakdown(BuildContext context) {
    if (_isCalculating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_taxBreakdown == null) return const SizedBox.shrink();

    final gstEnabled = widget.orderData['tenant']?['gst_enabled'] ?? true;
    final totalAmount = _taxBreakdown!['total_amount'];
    final baseAmount = _taxBreakdown!['base_amount'];
    final gstAmount = _taxBreakdown!['gst_amount'];
    final taxPercent = _taxBreakdown!['tax_percent'];
    final cgst = _taxBreakdown!['cgst'];
    final sgst = _taxBreakdown!['sgst'];
    final igst = _taxBreakdown!['igst'];
    final taxType = _taxBreakdown!['tax_type'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                gstEnabled ? 'Tax Breakdown' : 'Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow('Total Received', totalAmount),
          if (gstEnabled) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildBreakdownRow('Base Amount', baseAmount),
            const SizedBox(height: 8),
            _buildBreakdownRow(
              'GST @ ${taxPercent.toStringAsFixed(1)}%',
              gstAmount,
            ),
            if (taxType == 'INTRASTATE') ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: [
                    _buildBreakdownRow(
                      '├─ CGST (${(taxPercent / 2).toStringAsFixed(1)}%)',
                      cgst,
                      isSubItem: true,
                    ),
                    const SizedBox(height: 4),
                    _buildBreakdownRow(
                      '└─ SGST (${(taxPercent / 2).toStringAsFixed(1)}%)',
                      sgst,
                      isSubItem: true,
                    ),
                  ],
                ),
              ),
            ] else if (taxType == 'INTERSTATE') ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildBreakdownRow(
                  '└─ IGST (${taxPercent.toStringAsFixed(1)}%)',
                  igst,
                  isSubItem: true,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Tax rate calculated proportionally based on order items',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount, {
    bool isSubItem = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSubItem ? 12 : 13,
              color: isSubItem ? Colors.grey.shade700 : Colors.grey.shade800,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isSubItem ? 12 : 13,
            fontWeight: isSubItem ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
