import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../models/receipt_voucher.dart';
import '../models/invoice_payment.dart';
import '../services/payment_service.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final int?
  invoiceId; // If provided, creates InvoicePayment; otherwise ReceiptVoucher
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
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isRecording = false;
  String _paymentDate = '';
  String _paymentMode = 'CASH';
  double _gstRate = 0.0;
  bool _applyGst = false;

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now().toIso8601String().split('T')[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is an invoice payment or advance payment
    final bool isInvoicePayment = widget.invoiceId != null;
    final String title = isInvoicePayment
        ? 'Record Payment'
        : 'Record Advance Payment';
    final String buttonText = isInvoicePayment
        ? 'Record Payment'
        : 'Record Advance';

    final double balanceDue = _calculateBalanceDue();

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Icon(
                    isInvoicePayment ? Icons.payment : Icons.money,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isInvoicePayment
                              ? 'Payment against Invoice'
                              : 'Advance payment (before invoice)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Summary
                      _buildBalanceSummary(balanceDue),

                      const SizedBox(height: 20),

                      // Payment Date
                      TextFormField(
                        initialValue: _paymentDate,
                        decoration: const InputDecoration(
                          labelText: 'Payment Date *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _paymentDate = date.toIso8601String().split(
                                'T',
                              )[0];
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Payment Amount
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: isInvoicePayment
                              ? 'Payment Amount *'
                              : 'Advance Amount *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.currency_rupee),
                          helperText: 'Max: ₹${balanceDue.toStringAsFixed(2)}',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter valid amount';
                          }
                          if (amount > balanceDue) {
                            return 'Amount cannot exceed balance due';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Payment Mode
                      DropdownButtonFormField<String>(
                        value: _paymentMode,
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                          DropdownMenuItem(value: 'CARD', child: Text('Card')),
                          DropdownMenuItem(
                            value: 'BANK_TRANSFER',
                            child: Text('Bank Transfer'),
                          ),
                          DropdownMenuItem(
                            value: 'CHEQUE',
                            child: Text('Cheque'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _paymentMode = value!);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Transaction Reference (for digital payments)
                      if (_paymentMode != 'CASH')
                        TextFormField(
                          controller: _referenceController,
                          decoration: InputDecoration(
                            labelText: _paymentMode == 'UPI'
                                ? 'UPI Transaction ID'
                                : _paymentMode == 'CARD'
                                ? 'Last 4 Digits'
                                : _paymentMode == 'CHEQUE'
                                ? 'Cheque Number'
                                : 'Transaction Reference',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.receipt),
                          ),
                        ),

                      if (_paymentMode != 'CASH') const SizedBox(height: 16),

                      // GST Toggle (only for advance payments)
                      if (!isInvoicePayment) ...[
                        SwitchListTile(
                          title: const Text('Apply GST on Advance'),
                          subtitle: Text(
                            _applyGst
                                ? 'GST will be calculated at ${_gstRate.toStringAsFixed(0)}%'
                                : 'No GST on this advance',
                          ),
                          value: _applyGst,
                          onChanged: (value) {
                            setState(() => _applyGst = value);
                          },
                        ),

                        if (_applyGst) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<double>(
                            value: _gstRate,
                            decoration: const InputDecoration(
                              labelText: 'GST Rate *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.percent),
                            ),
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text('0%')),
                              DropdownMenuItem(value: 5.0, child: Text('5%')),
                              DropdownMenuItem(value: 12.0, child: Text('12%')),
                              DropdownMenuItem(value: 18.0, child: Text('18%')),
                              DropdownMenuItem(value: 28.0, child: Text('28%')),
                            ],
                            onChanged: (value) {
                              setState(() => _gstRate = value!);
                            },
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 2,
                      ),

                      // GST Calculation Preview (for advances)
                      if (!isInvoicePayment && _applyGst) ...[
                        const SizedBox(height: 20),
                        _buildGstPreview(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isRecording
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isRecording ? null : _recordPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isRecording
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(buttonText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(double balanceDue) {
    final double grandTotal = _getDoubleValue(widget.orderData['grand_total']);
    final double advanceReceived = _getDoubleValue(
      widget.orderData['advance_received'],
    );

    return Card(
      elevation: 0,
      color: AppTheme.primaryBlue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('Order Total', '₹${grandTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _summaryRow(
              'Advance Paid',
              '₹${advanceReceived.toStringAsFixed(2)}',
              valueColor: AppTheme.success,
            ),
            const Divider(height: 20),
            _summaryRow(
              'Balance Due',
              '₹${balanceDue.toStringAsFixed(2)}',
              isBold: true,
              valueColor: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: valueColor,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGstPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return const SizedBox.shrink();

    final cgst = (amount * _gstRate / 2) / 100;
    final sgst = (amount * _gstRate / 2) / 100;
    final total = amount + cgst + sgst;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GST Calculation',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _gstRow('Advance Amount', amount),
            _gstRow('CGST (${(_gstRate / 2).toStringAsFixed(1)}%)', cgst),
            _gstRow('SGST (${(_gstRate / 2).toStringAsFixed(1)}%)', sgst),
            const Divider(height: 16),
            _gstRow('Total Amount', total, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _gstRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBalanceDue() {
    final double grandTotal = _getDoubleValue(widget.orderData['grand_total']);
    final double advanceReceived = _getDoubleValue(
      widget.orderData['advance_received'],
    );
    return grandTotal - advanceReceived;
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRecording = true);

    try {
      final double amount = double.parse(_amountController.text);
      final bool isInvoicePayment = widget.invoiceId != null;

      if (isInvoicePayment) {
        // Create InvoicePayment (against invoice)
        final invoicePayment = InvoicePayment(
          paymentNumber: '', // Auto-generated
          paymentDate: _paymentDate,
          invoice: widget.invoiceId!,
          amount: amount,
          paymentMode: _paymentMode,
          transactionReference: _referenceController.text.isNotEmpty
              ? _referenceController.text
              : null,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

        await _paymentService.createInvoicePayment(invoicePayment);
      } else {
        // Create Receipt Voucher (advance)
        final receiptVoucher = ReceiptVoucher(
          voucherNumber: '', // Auto-generated
          receiptDate: _paymentDate,
          customer: widget.orderData['customer'],
          order: widget.orderData['id'],
          advanceAmount: amount,
          gstRate: _applyGst ? _gstRate : 0.0,
          paymentMode: _paymentMode,
          transactionReference: _referenceController.text.isNotEmpty
              ? _referenceController.text
              : null,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

        await _paymentService.createReceiptVoucher(receiptVoucher);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInvoicePayment
                  ? 'Payment recorded successfully'
                  : 'Advance payment recorded successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onPaymentRecorded();
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
            content: Text('Failed to record payment: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecording = false);
      }
    }
  }

  double _getDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
