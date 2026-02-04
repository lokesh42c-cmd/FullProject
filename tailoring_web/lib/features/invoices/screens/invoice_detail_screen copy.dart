// lib/features/invoices/screens/invoice_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_payment_history_widget.dart';
import 'package:tailoring_web/features/invoices/widgets/dialogs/refund_payment_dialog.dart';
import 'package:tailoring_web/features/financials/services/payment_service.dart';

/// Invoice Detail Screen - Zoho Books Style
///
/// Complete GST-compliant invoice display with:
/// - Professional Zoho-style layout
/// - Company details + TAX INVOICE header
/// - Invoice details, Bill To/Ship To
/// - Items table with HSN, CGST, SGST
/// - Terms & Financial Summary
/// - Collapsible payment history (NOT printed)
/// - Print dialog (Original/Duplicate/Triplicate)
class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final PaymentService _paymentService = PaymentService();

  // Invoice data
  Map<String, dynamic>? _invoice;
  List<dynamic> _invoiceItems = [];
  List<dynamic> _allPayments = [];

  // Loading states
  bool _isLoading = true;
  String? _errorMessage;

  // Print boundary key
  final GlobalKey _printKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load invoice, items, and all payments
      await Future.wait([
        _loadInvoice(),
        _loadInvoiceItems(),
        _loadAllPayments(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading invoice: ${e.toString()}';
      });
    }
  }

  Future<void> _loadInvoice() async {
    // TODO: Replace with actual API call
    // Example: final invoice = await invoiceService.getInvoiceById(widget.invoiceId);

    _invoice = {
      'id': widget.invoiceId,
      'invoice_number': 'INV2526-155',
      'invoice_date': '2026-02-04',
      'due_date': '2026-02-19',
      'place_of_supply': 'Karnataka',
      'order_number': 'ORD-001',

      'customer': {
        'id': 1,
        'name': 'Priya Sharma',
        'phone': '+91 98765 43210',
        'email': 'priya@example.com',
        'billing_address': '123, MG Road, Vijayapura, Karnataka - 586101',
        'shipping_address': '123, MG Road, Vijayapura, Karnataka - 586101',
        'gstin': '29ABCDE1234F1Z5',
      },

      'subtotal': 500.00,
      'discount': 50.00,
      'taxable_amount': 450.00,
      'cgst_amount': 40.50,
      'sgst_amount': 40.50,
      'igst_amount': 0.00,
      'grand_total': 531.00,
      'total_paid': 100.00,
      'balance_due': 431.00,

      'notes': 'Thank you for your business!',
      'terms_conditions':
          'Payment due within 15 days.\nNo returns after 7 days.',
      'status': 'PARTIALLY_PAID',
    };
  }

  Future<void> _loadInvoiceItems() async {
    // TODO: Replace with actual API call
    _invoiceItems = [
      {
        'id': 1,
        'item_name': 'Blouse Stitching',
        'hsn_code': '998599',
        'quantity': 2,
        'unit': 'Pcs',
        'rate': 200.00,
        'discount': 20.00,
        'cgst_rate': 9.0,
        'sgst_rate': 9.0,
        'cgst_amount': 16.20,
        'sgst_amount': 16.20,
        'amount': 212.40,
      },
      {
        'id': 2,
        'item_name': 'Embroidery Work',
        'hsn_code': '998599',
        'quantity': 1,
        'unit': 'Pcs',
        'rate': 300.00,
        'discount': 30.00,
        'cgst_rate': 9.0,
        'sgst_rate': 9.0,
        'cgst_amount': 24.30,
        'sgst_amount': 24.30,
        'amount': 318.60,
      },
    ];
  }

  Future<void> _loadAllPayments() async {
    try {
      final advances = await _loadAdvances();
      final payments = await _loadInvoicePayments();
      final advanceRefunds = await _loadAdvanceRefunds();
      final paymentRefunds = await _loadPaymentRefunds();

      _allPayments =
          [...advances, ...payments, ...advanceRefunds, ...paymentRefunds]
            ..sort((a, b) {
              final dateA = DateTime.parse(a['date'] ?? '2000-01-01');
              final dateB = DateTime.parse(b['date'] ?? '2000-01-01');
              return dateB.compareTo(dateA);
            });
    } catch (e) {
      print('Error loading payments: $e');
      _allPayments = [];
    }
  }

  Future<List<dynamic>> _loadAdvances() async {
    // TODO: Load advances from order
    return [
      {
        'type': 'ADVANCE',
        'id': 1,
        'number': 'RV-202602-001',
        'date': '2026-02-02',
        'amount': 100.0,
        'mode': 'CASH',
        'created_by': 'Admin',
        'order_id': 123,
      },
    ];
  }

  Future<List<dynamic>> _loadInvoicePayments() async {
    // TODO: Load via API
    return [];
  }

  Future<List<dynamic>> _loadAdvanceRefunds() async {
    // TODO: Load via API
    return [];
  }

  Future<List<dynamic>> _loadPaymentRefunds() async {
    try {
      final refunds = await _paymentService.getPaymentRefundsByInvoice(
        widget.invoiceId,
      );
      return refunds
          .map(
            (r) => {
              'type': 'PAYMENT_REFUND',
              'id': r.id,
              'number': r.refundNumber,
              'date': r.refundDate,
              'amount': -r.refundAmount,
              'mode': r.refundMode,
              'reason': r.reason,
              'notes': r.notes,
              'created_by': r.createdByName ?? 'Admin',
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _invoice?['invoice_number'] ?? 'Invoice',
        style: const TextStyle(
          color: AppTheme.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
          onPressed: () {},
          tooltip: 'Edit',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.send_outlined, color: AppTheme.primaryBlue),
          tooltip: 'Send',
          onSelected: (value) {},
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'email', child: Text('Email')),
            const PopupMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppTheme.primaryBlue),
          onPressed: () {},
          tooltip: 'Share',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.print_outlined, color: AppTheme.primaryBlue),
          tooltip: 'Print/PDF',
          onSelected: (value) => value == 'print' ? _showPrintDialog() : null,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'print', child: Text('Print')),
            const PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textDark),
          onSelected: (value) {},
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: AppTheme.danger)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInvoiceData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: RepaintBoundary(
              key: _printKey,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInvoiceHeader(),
                    const SizedBox(height: 32),
                    _buildInvoiceDetails(),
                    const SizedBox(height: 24),
                    _buildBillToShipTo(),
                    const SizedBox(height: 24),
                    _buildItemsTable(),
                    const SizedBox(height: 24),
                    _buildTermsAndSummary(),
                  ],
                ),
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: InvoicePaymentHistoryWidget(
              invoiceId: widget.invoiceId,
              allPayments: _allPayments,
              onRefresh: _loadInvoiceData,
              onRefundPayment: _showRefundDialog,
              onDeletePayment: _deletePayment,
              onNavigateToOrder: (orderId) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TAILORPRO',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '123, Main Street\nVijayapura, Karnataka - 586101\nGSTIN: 29XXXXX1234X1Z5',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TAX INVOICE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'ORIGINAL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          _buildDetailItem('Invoice #', _invoice!['invoice_number']),
          _buildDetailItem(
            'Invoice Date',
            _formatDate(_invoice!['invoice_date']),
          ),
          _buildDetailItem('Due Date', _formatDate(_invoice!['due_date'])),
          _buildDetailItem('Place of Supply', _invoice!['place_of_supply']),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBillToShipTo() {
    final customer = _invoice!['customer'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BILL TO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer['name'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customer['billing_address'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
              if (customer['gstin'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'GSTIN: ${customer['gstin']}',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
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
              Text(
                'SHIP TO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer['name'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customer['shipping_address'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Table(
      border: TableBorder.all(color: AppTheme.borderLight),
      columnWidths: const {
        0: FixedColumnWidth(40),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(60),
        4: FixedColumnWidth(80),
        5: FixedColumnWidth(60),
        6: FixedColumnWidth(80),
        7: FixedColumnWidth(60),
        8: FixedColumnWidth(80),
        9: FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _buildTH('S.No'),
            _buildTH('Item'),
            _buildTH('HSN'),
            _buildTH('Qty'),
            _buildTH('Rate'),
            _buildTH('CGST%'),
            _buildTH('CGST'),
            _buildTH('SGST%'),
            _buildTH('SGST'),
            _buildTH('Amount'),
          ],
        ),
        ..._invoiceItems.asMap().entries.map((e) {
          final i = e.key + 1;
          final item = e.value;
          return TableRow(
            children: [
              _buildTD('$i', center: true),
              _buildTD(item['item_name']),
              _buildTD(item['hsn_code'], center: true),
              _buildTD('${item['quantity']} ${item['unit']}', center: true),
              _buildTD('₹${item['rate'].toStringAsFixed(2)}', right: true),
              _buildTD('${item['cgst_rate']}%', center: true),
              _buildTD(
                '₹${item['cgst_amount'].toStringAsFixed(2)}',
                right: true,
              ),
              _buildTD('${item['sgst_rate']}%', center: true),
              _buildTD(
                '₹${item['sgst_amount'].toStringAsFixed(2)}',
                right: true,
              ),
              _buildTD(
                '₹${item['amount'].toStringAsFixed(2)}',
                right: true,
                bold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTH(String text) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildTD(
    String text, {
    bool center = false,
    bool right = false,
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: center
          ? TextAlign.center
          : right
          ? TextAlign.right
          : TextAlign.left,
    ),
  );

  Widget _buildTermsAndSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TERMS & CONDITIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _invoice!['terms_conditions'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                _buildSR('Sub Total', _invoice!['subtotal']),
                if (_invoice!['discount'] > 0)
                  _buildSR('Discount', _invoice!['discount'], neg: true),
                const Divider(height: 20),
                _buildSR('Taxable Amount', _invoice!['taxable_amount']),
                _buildSR('CGST', _invoice!['cgst_amount']),
                _buildSR('SGST', _invoice!['sgst_amount']),
                const Divider(height: 20),
                _buildSR(
                  'GRAND TOTAL',
                  _invoice!['grand_total'],
                  bold: true,
                  large: true,
                ),
                const Divider(height: 20),
                _buildSR(
                  'Advance Adjusted',
                  _invoice!['total_paid'],
                  neg: true,
                ),
                _buildSR(
                  'BALANCE DUE',
                  _invoice!['balance_due'],
                  bold: true,
                  highlight: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSR(
    String label,
    double amt, {
    bool neg = false,
    bool bold = false,
    bool large = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 15 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: highlight ? AppTheme.danger : AppTheme.textDark,
            ),
          ),
          Text(
            '${neg ? '-' : ''}₹${amt.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: large ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: highlight ? AppTheme.danger : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String d) {
    try {
      final date = DateTime.parse(d);
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day.toString().padLeft(2, '0')} ${m[date.month - 1]} ${date.year}';
    } catch (e) {
      return d;
    }
  }

  void _showPrintDialog() {
    String copyType = 'ORIGINAL';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Print Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('Original'),
                value: 'ORIGINAL',
                groupValue: copyType,
                onChanged: (v) => setState(() => copyType = v!),
              ),
              RadioListTile(
                title: const Text('Duplicate'),
                value: 'DUPLICATE',
                groupValue: copyType,
                onChanged: (v) => setState(() => copyType = v!),
              ),
              RadioListTile(
                title: const Text('Triplicate'),
                value: 'TRIPLICATE',
                groupValue: copyType,
                onChanged: (v) => setState(() => copyType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.print),
              label: const Text('Print'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRefundDialog(dynamic payment) {
    showDialog(
      context: context,
      builder: (context) => RefundPaymentDialog(
        payment: payment,
        invoiceId: widget.invoiceId,
        customerId: _invoice!['customer']['id'],
        onSuccess: _loadInvoiceData,
      ),
    );
  }

  Future<void> _deletePayment(dynamic payment) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment deleted'),
        backgroundColor: AppTheme.success,
      ),
    );
    await _loadInvoiceData();
  }
}
