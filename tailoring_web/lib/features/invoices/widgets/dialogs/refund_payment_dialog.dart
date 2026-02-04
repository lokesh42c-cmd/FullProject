// lib/features/invoices/widgets/dialogs/refund_payment_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/financials/models/payment_refund.dart';
import 'package:tailoring_web/features/financials/services/payment_service.dart';

/// Dialog to refund an invoice payment
///
/// Features:
/// - Shows original payment details
/// - Validates refundable amount
/// - Requires reason (min 10 chars)
/// - Supports all payment modes
/// - Real-time validation
class RefundPaymentDialog extends StatefulWidget {
  final dynamic payment; // Original InvoicePayment
  final int invoiceId;
  final int customerId;
  final VoidCallback? onSuccess;

  const RefundPaymentDialog({
    super.key,
    required this.payment,
    required this.invoiceId,
    required this.customerId,
    this.onSuccess,
  });

  @override
  State<RefundPaymentDialog> createState() => _RefundPaymentDialogState();
}

class _RefundPaymentDialogState extends State<RefundPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  final PaymentService _paymentService = PaymentService();

  String _selectedMode = 'CASH';
  bool _isLoading = false;
  double _maxRefundable = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateMaxRefundable();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _calculateMaxRefundable() {
    final paymentAmount = (widget.payment['amount'] ?? 0.0);
    final totalRefunded = (widget.payment['total_refunded'] ?? 0.0);
    _maxRefundable = paymentAmount - totalRefunded;

    // Pre-fill with max amount
    _amountController.text = _maxRefundable.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOriginalPaymentInfo(),
                      const SizedBox(height: 24),
                      _buildRefundAmountField(),
                      const SizedBox(height: 16),
                      _buildRefundModeField(),
                      const SizedBox(height: 16),
                      _buildTransactionReferenceField(),
                      const SizedBox(height: 16),
                      _buildReasonField(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.warning,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusMedium),
          topRight: Radius.circular(AppTheme.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.refresh, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Process refund for invoice payment',
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalPaymentInfo() {
    final paymentAmount = (widget.payment['amount'] ?? 0.0);
    final totalRefunded = (widget.payment['total_refunded'] ?? 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'Original Payment Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Payment Number:',
            widget.payment['payment_number'] ?? '-',
          ),
          _buildInfoRow(
            'Payment Date:',
            _formatDate(widget.payment['payment_date'] ?? ''),
          ),
          _buildInfoRow('Amount Paid:', '₹${paymentAmount.toStringAsFixed(2)}'),
          _buildInfoRow(
            'Total Refunded:',
            '₹${totalRefunded.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Refundable Amount:',
            '₹${_maxRefundable.toStringAsFixed(2)}',
            valueColor: AppTheme.success,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppTheme.textDark,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Refund Amount *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Enter refund amount',
            prefixIcon: const Icon(Icons.currency_rupee, size: 18),
            suffixText: 'Max: ₹${_maxRefundable.toStringAsFixed(2)}',
            suffixStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Refund amount is required';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Enter a valid amount greater than 0';
            }
            if (amount > _maxRefundable) {
              return 'Amount exceeds refundable amount of ₹${_maxRefundable.toStringAsFixed(2)}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRefundModeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Refund Mode *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMode,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.payment, size: 18),
          ),
          items: const [
            DropdownMenuItem(value: 'CASH', child: Text('Cash')),
            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
            DropdownMenuItem(value: 'CARD', child: Text('Card')),
            DropdownMenuItem(
              value: 'BANK_TRANSFER',
              child: Text('Bank Transfer'),
            ),
            DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedMode = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTransactionReferenceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Reference',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _referenceController,
          decoration: const InputDecoration(
            hintText: 'Transaction ID, cheque number, etc.',
            prefixIcon: Icon(Icons.tag, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for Refund *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter reason for refund (min 10 characters)',
            prefixIcon: Icon(Icons.edit_note, size: 18),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Reason is required';
            }
            if (value.trim().length < 10) {
              return 'Reason must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Any additional notes (optional)',
            prefixIcon: Icon(Icons.notes, size: 18),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Warning message
          Expanded(
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Action buttons
          Row(
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleRefund,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 18),
                label: Text(_isLoading ? 'Processing...' : 'Process Refund'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _handleRefund() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final refund = PaymentRefund(
        refundNumber: '', // Auto-generated by backend
        payment: widget.payment['id'],
        invoice: widget.invoiceId,
        customer: widget.customerId,
        refundDate: DateTime.now().toIso8601String().split('T')[0],
        refundAmount: double.parse(_amountController.text),
        refundMode: _selectedMode,
        transactionReference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final created = await _paymentService.createPaymentRefund(refund);

      if (created != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Refund Processed Successfully',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Refund ${created.refundNumber} created',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );

        // Close dialog
        Navigator.pop(context);

        // Call success callback
        widget.onSuccess?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing refund: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
