import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';

import 'package:tailoring_web/features/invoices/models/invoice.dart';
import 'package:tailoring_web/features/invoices/providers/invoice_provider.dart';
import 'package:intl/intl.dart';

/// Invoice Detail Screen
/// Displays complete invoice details with actions
class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    final provider = context.read<InvoiceProvider>();
    final invoice = await provider.fetchInvoiceById(widget.invoiceId);
    setState(() {
      _invoice = invoice;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/invoices',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _invoice == null
            ? _buildError()
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildInvoiceContent(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text('Invoice not found', style: AppTheme.heading3),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_invoice!.invoiceNumber, style: AppTheme.heading2),
              Text(
                _invoice!.customerName ?? 'Unknown Customer',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Issue Button (if DRAFT)
        if (_invoice!.status == 'DRAFT')
          ElevatedButton.icon(
            onPressed: _handleIssue,
            icon: const Icon(Icons.check_circle),
            label: const Text('Issue Invoice'),
          ),

        const SizedBox(width: 12),

        // Cancel Button (if not PAID or CANCELLED)
        if (_invoice!.status != 'PAID' && _invoice!.status != 'CANCELLED')
          OutlinedButton.icon(
            onPressed: _handleCancel,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
          ),

        const SizedBox(width: 12),

        // Print Button
        OutlinedButton.icon(
          onPressed: _handlePrint,
          icon: const Icon(Icons.print),
          label: const Text('Print'),
        ),
      ],
    );
  }

  Widget _buildInvoiceContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Banner
          _buildStatusBanner(),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Info Row
                _buildInvoiceInfo(),
                const Divider(height: 32),

                // Addresses Row
                _buildAddresses(),
                const Divider(height: 32),

                // Items Table
                _buildItemsTable(),
                const Divider(height: 32),

                // Financial Summary
                _buildFinancialSummary(),

                // Notes
                if (_invoice!.notes != null && _invoice!.notes!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildNotes(),
                ],

                // Terms
                if (_invoice!.termsAndConditions != null &&
                    _invoice!.termsAndConditions!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildTerms(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(_invoice!.status).withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusSmall),
          topRight: Radius.circular(AppTheme.radiusSmall),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_invoice!.status),
            color: _getStatusColor(_invoice!.status),
          ),
          const SizedBox(width: 12),
          Text(
            'Status: ${_invoice!.statusDisplay ?? _invoice!.status}',
            style: AppTheme.bodyMedium.copyWith(
              color: _getStatusColor(_invoice!.status),
              fontWeight: AppTheme.fontSemibold,
            ),
          ),
          const SizedBox(width: 24),
          Icon(
            Icons.payments,
            color: _getPaymentStatusColor(_invoice!.paymentStatus),
          ),
          const SizedBox(width: 8),
          Text(
            'Payment: ${_invoice!.paymentStatusDisplay ?? _invoice!.paymentStatus}',
            style: AppTheme.bodyMedium.copyWith(
              color: _getPaymentStatusColor(_invoice!.paymentStatus),
              fontWeight: AppTheme.fontSemibold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice Number', style: _labelStyle),
              Text(_invoice!.invoiceNumber, style: _valueStyle),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice Date', style: _labelStyle),
              Text(_formatDate(_invoice!.invoiceDate), style: _valueStyle),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tax Type', style: _labelStyle),
              Text(
                _invoice!.taxTypeDisplay ?? _invoice!.taxType,
                style: _valueStyle,
              ),
            ],
          ),
        ),
        if (_invoice!.orderNumber != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Reference', style: _labelStyle),
                Text(_invoice!.orderNumber!, style: _valueStyle),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddresses() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Billing Address', style: AppTheme.heading3),
              const SizedBox(height: 12),
              Text(_invoice!.billingName, style: _valueStyle),
              const SizedBox(height: 4),
              Text(_invoice!.billingAddress, style: _secondaryStyle),
              if (_invoice!.billingCity != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_invoice!.billingCity}, ${_invoice!.billingState}${_invoice!.billingPincode != null ? " - ${_invoice!.billingPincode}" : ""}',
                  style: _secondaryStyle,
                ),
              ],
              if (_invoice!.billingGstin != null) ...[
                const SizedBox(height: 4),
                Text(
                  'GSTIN: ${_invoice!.billingGstin}',
                  style: _secondaryStyle,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shipping Address', style: AppTheme.heading3),
              const SizedBox(height: 12),
              if (_invoice!.shippingName != null &&
                  _invoice!.shippingName!.isNotEmpty) ...[
                Text(_invoice!.shippingName!, style: _valueStyle),
                const SizedBox(height: 4),
                if (_invoice!.shippingAddress != null)
                  Text(_invoice!.shippingAddress!, style: _secondaryStyle),
                if (_invoice!.shippingCity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_invoice!.shippingCity}, ${_invoice!.shippingState}${_invoice!.shippingPincode != null ? " - ${_invoice!.shippingPincode}" : ""}',
                    style: _secondaryStyle,
                  ),
                ],
              ] else ...[
                Text(
                  'Same as billing address',
                  style: _secondaryStyle.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invoice Items', style: AppTheme.heading3),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: AppTheme.borderLight),
          columnWidths: const {
            0: FlexColumnWidth(0.5),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1.5),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: AppTheme.backgroundGray),
              children: [
                _buildTableHeader('#'),
                _buildTableHeader('Description'),
                _buildTableHeader('HSN/SAC'),
                _buildTableHeader('Qty'),
                _buildTableHeader('Price'),
                _buildTableHeader('GST %'),
                _buildTableHeader('Total'),
              ],
            ),
            // Items
            ...(_invoice!.items ?? []).asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return TableRow(
                children: [
                  _buildTableCell('${index + 1}'),
                  _buildTableCell(item.itemDescription),
                  _buildTableCell(item.hsnSacCode ?? '-'),
                  _buildTableCell(item.quantity.toString()),
                  _buildTableCell('₹${item.unitPrice.toStringAsFixed(2)}'),
                  _buildTableCell('${item.gstRate.toStringAsFixed(0)}%'),
                  _buildTableCell(
                    '₹${(item.totalAmount ?? item.calculateTotalAmount(_invoice!.taxType)).toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return Row(
      children: [
        const Spacer(),
        Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Subtotal', _invoice!.subtotal),
              if (_invoice!.taxType == 'INTRASTATE') ...[
                _buildSummaryRow(
                  'CGST',
                  _invoice!.totalCgst,
                  isSecondary: true,
                ),
                _buildSummaryRow(
                  'SGST',
                  _invoice!.totalSgst,
                  isSecondary: true,
                ),
              ] else if (_invoice!.taxType == 'INTERSTATE') ...[
                _buildSummaryRow(
                  'IGST',
                  _invoice!.totalIgst,
                  isSecondary: true,
                ),
              ],
              const Divider(),
              _buildSummaryRow(
                'Grand Total',
                _invoice!.grandTotal,
                isBold: true,
                isLarge: true,
              ),
              if (_invoice!.totalAdvanceAdjusted > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Advance Adjusted',
                  _invoice!.totalAdvanceAdjusted,
                  isSecondary: true,
                  isNegative: true,
                ),
                const Divider(),
                _buildSummaryRow(
                  'Balance Due',
                  _invoice!.balanceDue,
                  isBold: true,
                ),
              ],
              if (_invoice!.totalPaid > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Total Paid',
                  _invoice!.totalPaid,
                  isSecondary: true,
                  isNegative: true,
                ),
                _buildSummaryRow(
                  'Remaining Balance',
                  _invoice!.remainingBalance,
                  isBold: true,
                  color: _invoice!.remainingBalance > 0
                      ? AppTheme.error
                      : AppTheme.success,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: AppTheme.heading3),
        const SizedBox(height: 8),
        Text(_invoice!.notes!, style: _secondaryStyle),
      ],
    );
  }

  Widget _buildTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Terms & Conditions', style: AppTheme.heading3),
        const SizedBox(height: 8),
        Text(_invoice!.termsAndConditions!, style: _secondaryStyle),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(fontWeight: AppTheme.fontSemibold),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: isBold ? AppTheme.fontSemibold : AppTheme.fontRegular,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
    bool isSecondary = false,
    bool isNegative = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isLarge ? AppTheme.bodyLarge : AppTheme.bodyMedium)
                .copyWith(
                  fontWeight: isBold ? AppTheme.fontBold : AppTheme.fontRegular,
                  color: isSecondary
                      ? AppTheme.textSecondary
                      : AppTheme.textPrimary,
                ),
          ),
          Text(
            '${isNegative ? '- ' : ''}₹${amount.toStringAsFixed(2)}',
            style: (isLarge ? AppTheme.bodyLarge : AppTheme.bodyMedium)
                .copyWith(
                  fontWeight: isBold ? AppTheme.fontBold : AppTheme.fontRegular,
                  color:
                      color ??
                      (isSecondary
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleIssue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Invoice'),
        content: const Text('Are you sure you want to issue this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Issue'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<InvoiceProvider>();
      final success = await provider.issueInvoice(_invoice!.id!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice issued successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadInvoice();
      }
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: const Text('Are you sure you want to cancel this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<InvoiceProvider>();
      final success = await provider.cancelInvoice(_invoice!.id!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice cancelled'),
            backgroundColor: AppTheme.warning,
          ),
        );
        _loadInvoice();
      }
    }
  }

  void _handlePrint() {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon')),
    );
  }

  TextStyle get _labelStyle =>
      AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary);

  TextStyle get _valueStyle =>
      AppTheme.bodyMedium.copyWith(fontWeight: AppTheme.fontSemibold);

  TextStyle get _secondaryStyle =>
      AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return AppTheme.textMuted;
      case 'ISSUED':
        return AppTheme.primaryBlue;
      case 'PAID':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'DRAFT':
        return Icons.edit;
      case 'ISSUED':
        return Icons.send;
      case 'PAID':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'UNPAID':
        return AppTheme.error;
      case 'PARTIAL':
        return AppTheme.warning;
      case 'PAID':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
