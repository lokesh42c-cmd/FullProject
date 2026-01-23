import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import 'package:tailoring_web/features/financials/models/invoice_payment.dart';
import 'package:tailoring_web/features/financials/services/payment_service.dart';
import 'package:tailoring_web/features/financials/widgets/record_payment_dialog.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final PaymentService _paymentService = PaymentService();

  Invoice? _invoice;
  List<InvoicePayment> _payments = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);

    try {
      final invoice = await _invoiceService.getInvoiceById(widget.invoiceId);
      final payments = await _paymentService.getInvoicePaymentsByInvoice(
        widget.invoiceId,
      );

      setState(() {
        _invoice = invoice;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading invoice: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_invoice?.invoiceNumber ?? 'Invoice Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoice == null
          ? _buildErrorState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Status and Actions
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Customer & Billing Info
                  _buildCustomerCard(),
                  const SizedBox(height: 20),

                  // Items Table
                  _buildItemsCard(),
                  const SizedBox(height: 20),

                  // Financial Summary
                  _buildSummaryCard(),
                  const SizedBox(height: 20),

                  // Payment History
                  _buildPaymentHistoryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Invoice not found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _invoice!.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusBadge(_invoice!.status),
                          const SizedBox(width: 8),
                          _buildPaymentStatusBadge(_invoice!.paymentStatus),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _invoice!.invoiceDate,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_invoice!.status == 'DRAFT')
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _onIssueInvoice,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Issue Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                  ),
                if (_invoice!.paymentStatus != 'PAID')
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _onRecordPayment,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Record Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _onPrintInvoice,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                  ),
                ),
                if (_invoice!.status != 'CANCELLED' &&
                    _invoice!.status != 'PAID')
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _onCancelInvoice,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
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
            const Text(
              'Customer & Billing Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _invoice!.customerName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_invoice!.orderNumber != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Order',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _invoice!.orderNumber!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Billing Address',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _invoice!.billingName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _invoice!.billingAddress,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        [
                          _invoice!.billingCity,
                          _invoice!.billingState,
                          _invoice!.billingPincode,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_invoice!.billingGstin != null &&
                          _invoice!.billingGstin!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'GSTIN: ${_invoice!.billingGstin}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
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
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1.5),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: [
                    _tableHeader('Description'),
                    _tableHeader('Qty'),
                    _tableHeader('Rate'),
                    _tableHeader('GST%'),
                    _tableHeader('Amount'),
                  ],
                ),
                // Items
                ...(_invoice!.items ?? []).map((item) {
                  return TableRow(
                    children: [
                      _tableCell(item.itemDescription),
                      _tableCell(item.quantity.toString()),
                      _tableCell('₹${item.unitPrice.toStringAsFixed(2)}'),
                      _tableCell('${item.gstRate.toStringAsFixed(0)}%'),
                      _tableCell(
                        '₹${(item.calculateSubtotal() + item.calculateCgst(_invoice!.taxType) + item.calculateSgst(_invoice!.taxType) + item.calculateIgst(_invoice!.taxType)).toStringAsFixed(2)}',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 0,
      color: AppTheme.primaryBlue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _summaryRow('Subtotal', _invoice!.subtotal),
            const SizedBox(height: 8),
            if (_invoice!.taxType == 'INTRASTATE') ...[
              _summaryRow('CGST', _invoice!.cgst),
              _summaryRow('SGST', _invoice!.sgst),
            ] else ...[
              _summaryRow('IGST', _invoice!.igst),
            ],
            const Divider(height: 24),
            _summaryRow(
              'Grand Total',
              _invoice!.grandTotal,
              isBold: true,
              isLarge: true,
            ),
            if (_invoice!.totalAdvanceAdjusted > 0) ...[
              const SizedBox(height: 8),
              _summaryRow(
                'Advance Adjusted',
                _invoice!.totalAdvanceAdjusted,
                color: AppTheme.success,
              ),
            ],
            if (_invoice!.totalPaid > 0) ...[
              const SizedBox(height: 8),
              _summaryRow(
                'Total Paid',
                _invoice!.totalPaid,
                color: AppTheme.success,
              ),
            ],
            const Divider(height: 24),
            _summaryRow(
              'Remaining Balance',
              _invoice!.remainingBalance,
              isBold: true,
              color: _invoice!.remainingBalance > 0
                  ? AppTheme.danger
                  : AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            fontSize: isLarge ? 18 : 14,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            fontSize: isLarge ? 18 : 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryCard() {
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
            const Text(
              'Payment History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_payments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.payment,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No payments recorded yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade50),
                    children: [
                      _tableHeader('Date'),
                      _tableHeader('Payment #'),
                      _tableHeader('Mode'),
                      _tableHeader('Amount'),
                    ],
                  ),
                  // Payments
                  ..._payments.map((payment) {
                    return TableRow(
                      children: [
                        _tableCell(payment.paymentDate),
                        _tableCell(payment.paymentNumber),
                        _tableCell(
                          payment.paymentModeDisplay ?? payment.paymentMode,
                        ),
                        _tableCell('₹${payment.amount.toStringAsFixed(2)}'),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'DRAFT':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'ISSUED':
        color = AppTheme.primaryBlue;
        label = 'Issued';
        break;
      case 'PAID':
        color = AppTheme.success;
        label = 'Paid';
        break;
      case 'CANCELLED':
        color = AppTheme.danger;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String paymentStatus) {
    Color color;
    String label;

    switch (paymentStatus) {
      case 'UNPAID':
        color = AppTheme.danger;
        label = 'Unpaid';
        break;
      case 'PARTIAL':
        color = AppTheme.warning;
        label = 'Partial';
        break;
      case 'PAID':
        color = AppTheme.success;
        label = 'Paid';
        break;
      default:
        color = Colors.grey;
        label = paymentStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _onIssueInvoice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Invoice?'),
        content: const Text(
          'Once issued, the invoice cannot be edited. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Issue'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _invoiceService.issueInvoice(widget.invoiceId);
      await _loadInvoice();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice issued successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to issue invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _onRecordPayment() {
    // Build order data from invoice
    final orderData = {
      'id': _invoice!.order ?? 0,
      'order_number': _invoice!.orderNumber,
      'customer': _invoice!.customer,
      'grand_total': _invoice!.grandTotal,
      'advance_received': _invoice!.totalAdvanceAdjusted + _invoice!.totalPaid,
    };

    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        orderData: orderData,
        invoiceId: widget.invoiceId,
        onPaymentRecorded: _loadInvoice,
      ),
    );
  }

  void _onPrintInvoice() {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality coming soon'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Future<void> _onCancelInvoice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice?'),
        content: const Text('This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _invoiceService.cancelInvoice(widget.invoiceId);
      await _loadInvoice();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice cancelled'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
