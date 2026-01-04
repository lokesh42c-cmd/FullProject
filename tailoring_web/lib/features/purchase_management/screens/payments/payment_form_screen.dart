import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/models/purchase_bill.dart';
import 'package:tailoring_web/features/purchase_management/models/expense.dart';
import 'package:tailoring_web/features/purchase_management/models/payment.dart';
import 'package:tailoring_web/features/purchase_management/providers/payment_provider.dart';
import 'package:tailoring_web/features/purchase_management/widgets/payment_method_chip.dart';

class PaymentFormScreen extends StatefulWidget {
  final PurchaseBill? bill;
  final Expense? expense;

  const PaymentFormScreen({super.key, this.bill, this.expense});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'CASH';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill amount with balance
    if (widget.bill != null) {
      _amountController.text = widget.bill!.balanceAmount;
    } else if (widget.expense != null) {
      _amountController.text = widget.expense!.balanceAmount;
    }
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
    final balance =
        widget.bill?.balanceAmountDouble ??
        widget.expense?.balanceAmountDouble ??
        0.0;

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  const Text('Record Payment', style: AppTheme.heading3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment info banner
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.bill != null
                                      ? Icons.receipt_long
                                      : Icons.payment,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.bill != null
                                        ? 'Bill: ${widget.bill!.billNumber}'
                                        : 'Expense: ${widget.expense!.categoryDisplay ?? widget.expense!.category}',
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.bill?.vendorName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Vendor: ${widget.bill!.vendorName}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance Due',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  '₹${balance.toStringAsFixed(2)}',
                                  style: AppTheme.heading3.copyWith(
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Payment Date
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date *',
                            prefixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _formatDate(_paymentDate),
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Payment Amount
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee, size: 18),
                          hintText: '0.00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter payment amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          if (amount > balance) {
                            return 'Amount cannot exceed balance of ₹${balance.toStringAsFixed(2)}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space2),

                      // Quick amount buttons
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _amountController.text = balance.toStringAsFixed(
                                2,
                              );
                            },
                            child: const Text('Pay Full Amount'),
                          ),
                          if (balance >= 1000)
                            OutlinedButton(
                              onPressed: () {
                                final half = balance / 2;
                                _amountController.text = half.toStringAsFixed(
                                  2,
                                );
                              },
                              child: const Text('Pay Half'),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Payment Method
                      const Text(
                        'Payment Method *',
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.space2),
                      PaymentMethodSelector(
                        selectedMethod: _paymentMethod,
                        onMethodSelected: (method) {
                          setState(() {
                            _paymentMethod = method;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // Reference Number
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference Number',
                          prefixIcon: Icon(Icons.tag, size: 18),
                          hintText: 'e.g., UPI123456789, Cheque #12345',
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          prefixIcon: Icon(Icons.note, size: 18),
                          hintText: 'Additional payment details...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSave,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: Text(_isLoading ? 'Recording...' : 'Record Payment'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payment = Payment(
        paymentNumber: '', // Auto-generated by backend
        paymentDate: _paymentDate,
        paymentType: widget.bill != null ? 'PURCHASE_BILL' : 'EXPENSE',
        amount: _amountController.text,
        paymentMethod: _paymentMethod,
        referenceNumber: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        purchaseBill: widget.bill?.id,
        expense: widget.expense?.id,
      );

      final provider = context.read<PaymentProvider>();
      final success = await provider.createPayment(payment);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success),
                  const SizedBox(width: 8),
                  const Text('Payment recorded successfully'),
                ],
              ),
              backgroundColor: AppTheme.success.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: AppTheme.danger),
                  const SizedBox(width: 8),
                  Text(provider.errorMessage ?? 'Failed to record payment'),
                ],
              ),
              backgroundColor: AppTheme.danger.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}
