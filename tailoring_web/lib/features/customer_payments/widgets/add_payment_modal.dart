/// Add Payment Modal
/// Location: lib/features/customer_payments/widgets/add_payment_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customer_payments/models/payment.dart';
import 'package:tailoring_web/features/customer_payments/providers/payment_provider.dart';

class AddPaymentModal extends StatefulWidget {
  final int? orderId;

  const AddPaymentModal({Key? key, this.orderId}) : super(key: key);

  @override
  State<AddPaymentModal> createState() => _AddPaymentModalState();
}

class _AddPaymentModalState extends State<AddPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _bankNameController = TextEditingController();

  String _paymentMethod = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                  const Text('Add Payment', style: AppTheme.heading2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Amount required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method *',
                ),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('💵 Cash')),
                  DropdownMenuItem(value: 'UPI', child: Text('📱 UPI')),
                  DropdownMenuItem(value: 'CARD', child: Text('💳 Card')),
                  DropdownMenuItem(
                    value: 'BANK_TRANSFER',
                    child: Text('🏦 Bank Transfer'),
                  ),
                  DropdownMenuItem(value: 'CHEQUE', child: Text('📝 Cheque')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank/Account Name',
                  hintText: 'e.g., HDFC Bank, Cash Box',
                ),
              ),
              const SizedBox(height: 16),

              if (_paymentMethod != 'CASH')
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText:
                        'Reference Number ${_requiresReference ? "*" : ""}',
                    hintText: 'Transaction ID, Cheque No, etc.',
                  ),
                  validator: _requiresReference
                      ? (v) => v == null || v.isEmpty ? 'Required' : null
                      : null,
                ),
              if (_paymentMethod != 'CASH') const SizedBox(height: 16),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Payment Date'),
                  child: Text(
                    '${_paymentDate.day.toString().padLeft(2, '0')}/'
                    '${_paymentDate.month.toString().padLeft(2, '0')}/'
                    '${_paymentDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
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
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Payment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _requiresReference =>
      ['UPI', 'BANK_TRANSFER', 'CHEQUE'].contains(_paymentMethod);

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.orderId == null) return;

    setState(() => _isSubmitting = true);

    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final success = await provider.createPayment(
      orderId: widget.orderId!,
      amount: double.parse(_amountController.text),
      paymentMethod: _paymentMethod,
      paymentDate: _paymentDate,
      referenceNumber: _referenceController.text.isNotEmpty
          ? _referenceController.text
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      bankName: _bankNameController.text.isNotEmpty
          ? _bankNameController.text
          : null,
    );

    if (mounted) {
      if (success) {
        // Reload data before closing
        provider.setOrderFilter(widget.orderId);
        await provider.loadSummary(orderId: widget.orderId);

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to add payment')),
        );
      }
    }
  }
}
