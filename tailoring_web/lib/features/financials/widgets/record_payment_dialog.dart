import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:intl/intl.dart';
import '../models/invoice_payment.dart';
import '../models/receipt_voucher.dart';
import '../services/payment_service.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final int? invoiceId;
  final VoidCallback onPaymentRecorded;

  const RecordPaymentDialog({
    super.key,
    required this.orderData,
    this.invoiceId,
    required this.onPaymentRecorded,
  });

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String _paymentMethod = 'CASH';
  DateTime _paymentDate = DateTime.now();

  late double _maxAmount;
  late bool _isInvoicePayment;

  @override
  void initState() {
    super.initState();
    _calculateMaxAmount();
  }

  void _calculateMaxAmount() {
    _isInvoicePayment = widget.invoiceId != null;

    final estimatedTotal = (widget.orderData['estimated_total'] ?? 0)
        .toDouble();
    final totalPaid = (widget.orderData['total_paid'] ?? 0).toDouble();
    _maxAmount = estimatedTotal - totalPaid;

    if (_maxAmount < 0) _maxAmount = 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _quickFill() {
    _amountController.text = _maxAmount.toStringAsFixed(2);
  }

  // Find the _recordPayment() method and update the date formatting:

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount > _maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot exceed maximum amount of ₹${_maxAmount.toStringAsFixed(2)}',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than zero'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: Format date as YYYY-MM-DD string only
      final dateString =
          '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}';

      if (_isInvoicePayment) {
        await _apiClient.post(
          'financials/payments/',
          data: {
            'invoice': widget.invoiceId,
            'amount': amount,
            'payment_mode': _paymentMethod,
            'payment_date': dateString, // ✅ Date string only
            'notes': _notesController.text.isEmpty ? '' : _notesController.text,
          },
        );
      } else {
        await _apiClient.post(
          'financials/receipts/',
          data: {
            'order': widget.orderData['id'],
            'advance_amount': amount,
            'payment_mode': _paymentMethod,
            'receipt_date': dateString, // ✅ Date string only
            'notes': _notesController.text.isEmpty ? '' : _notesController.text,
          },
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentRecorded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isInvoicePayment
                              ? 'Record Invoice Payment'
                              : 'Record Advance Payment',
                          style: AppTheme.heading2,
                        ),
                        Text(
                          _isInvoicePayment
                              ? 'Payment against invoice'
                              : 'Advance payment before invoice',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_maxAmount <= 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isInvoicePayment
                              ? 'Invoice is fully paid'
                              : 'Order is fully paid',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Maximum allowed: ₹${_maxAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cannot accept payment beyond ${_isInvoicePayment ? 'invoice' : 'order'} total. Create new order for additional amounts.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        enabled: _maxAmount > 0,
                        decoration: InputDecoration(
                          labelText: 'Amount *',
                          prefixText: '₹',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: _maxAmount > 0
                              ? AppTheme.backgroundWhite
                              : AppTheme.backgroundGrey,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          final amount = double.tryParse(value!);
                          if (amount == null || amount <= 0)
                            return 'Invalid amount';
                          if (amount > _maxAmount) return 'Exceeds max amount';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _maxAmount > 0 ? _quickFill : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                      child: const Text('Fill Max'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method *',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                    DropdownMenuItem(value: 'CARD', child: Text('Card')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(
                      value: 'BANK_TRANSFER',
                      child: Text('Bank Transfer'),
                    ),
                    DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                  ],
                  onChanged: _maxAmount > 0
                      ? (value) {
                          if (value != null) {
                            setState(() => _paymentMethod = value);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: _maxAmount > 0
                      ? () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _paymentDate = date);
                          }
                        }
                      : null,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Payment Date',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      filled: true,
                      fillColor: _maxAmount > 0
                          ? AppTheme.backgroundWhite
                          : AppTheme.backgroundGrey,
                    ),
                    child: Text(DateFormat('dd-MM-yyyy').format(_paymentDate)),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  enabled: _maxAmount > 0,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: _maxAmount > 0
                        ? AppTheme.backgroundWhite
                        : AppTheme.backgroundGrey,
                  ),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (_isLoading || _maxAmount <= 0)
                        ? null
                        : _recordPayment,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isLoading ? 'Recording...' : 'Record Payment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
