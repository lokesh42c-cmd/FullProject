// lib/features/invoices/screens/invoice_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_payment_history_widget.dart';
import 'package:tailoring_web/features/invoices/widgets/dialogs/refund_payment_dialog.dart';
import 'package:tailoring_web/features/invoices/models/invoice.dart';
import 'package:tailoring_web/features/invoices/services/invoice_service.dart';
import 'package:tailoring_web/features/financials/services/payment_service.dart';
import 'package:tailoring_web/features/financials/models/invoice_payment.dart';
import 'package:tailoring_web/features/financials/models/receipt_voucher.dart';
import 'package:tailoring_web/features/financials/models/refund_voucher.dart';
import 'package:tailoring_web/features/financials/models/payment_refund.dart';

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
  final InvoiceService _invoiceService = InvoiceService();
  final PaymentService _paymentService = PaymentService();

  Invoice? _invoice;
  List<dynamic> _allPayments = [];
  bool _isLoading = true;
  String? _errorMessage;
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
      // Load invoice with items from API
      _invoice = await _invoiceService.fetchInvoiceById(widget.invoiceId);

      // Load all payment types
      await _loadAllPayments();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading invoice: ${e.toString()}';
      });
    }
  }

  Future<void> _loadAllPayments() async {
    try {
      List<dynamic> allPayments = [];

      // 1. Load advances (ReceiptVouchers from order)
      if (_invoice!.order != null) {
        try {
          final advances = await _paymentService.getReceiptVouchersByOrder(
            _invoice!.order!,
          );
          allPayments.addAll(
            advances.map(
              (rv) => {
                'type': 'ADVANCE',
                'id': rv.id,
                'number': rv.voucherNumber,
                'date': rv.receiptDate.toIso8601String().split('T')[0],
                'amount': rv.totalAmount,
                'mode': rv.paymentMode,
                'created_by': 'Admin',
                'order_id': _invoice!.order,
              },
            ),
          );
        } catch (e) {
          print('Error loading advances: $e');
        }
      }

      // 2. Load invoice payments
      try {
        final payments = await _paymentService.getInvoicePaymentsByInvoice(
          widget.invoiceId,
        );
        allPayments.addAll(
          payments.map(
            (p) => {
              'type': 'PAYMENT',
              'id': p.id,
              'number': p.paymentNumber,
              'payment_number': p.paymentNumber,
              'date': p.paymentDate,
              'payment_date': p.paymentDate,
              'amount': p.amount,
              'mode': p.paymentMode,
              'created_by': 'Admin',
              'total_refunded': 0.0,
            },
          ),
        );
      } catch (e) {
        print('Error loading payments: $e');
      }

      // 3. Load advance refunds
      if (_invoice!.order != null) {
        try {
          final advRefunds = await _loadAdvanceRefunds();
          allPayments.addAll(advRefunds);
        } catch (e) {
          print('Error loading advance refunds: $e');
        }
      }

      // 4. Load payment refunds
      try {
        final paymentRefunds = await _paymentService.getPaymentRefundsByInvoice(
          widget.invoiceId,
        );
        allPayments.addAll(
          paymentRefunds.map(
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
          ),
        );
      } catch (e) {
        print('Error loading payment refunds: $e');
      }

      // Sort by date
      allPayments.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      setState(() => _allPayments = allPayments);
    } catch (e) {
      print('Error in _loadAllPayments: $e');
      setState(() => _allPayments = []);
    }
  }

  Future<List<dynamic>> _loadAdvanceRefunds() async {
    try {
      final receipts = await _paymentService.getReceiptVouchersByOrder(
        _invoice!.order!,
      );
      List<dynamic> refunds = [];
      for (var receipt in receipts) {
        if (receipt.id != null) {
          try {
            final rvRefunds = await _paymentService.getRefundVouchersByReceipt(
              receipt.id!,
            );
            refunds.addAll(
              rvRefunds.map(
                (rf) => {
                  'type': 'ADVANCE_REFUND',
                  'id': rf.id,
                  'number': rf.refundNumber,
                  'date': rf.refundDate.toIso8601String().split('T')[0],
                  'amount': -rf.totalRefund,
                  'mode': rf.refundMode,
                  'reason': rf.reason,
                  'notes': rf.notes,
                  'created_by': 'Admin',
                  'order_id': _invoice!.order,
                },
              ),
            );
          } catch (e) {
            print('Error loading refunds for receipt ${receipt.id}: $e');
          }
        }
      }
      return refunds;
    } catch (e) {
      return [];
    }
  }

  double _calculateTotalPaid() {
    double total = 0.0;
    for (var payment in _allPayments) {
      // Add positive amounts (advances and payments)
      // Subtract refunds (they're already negative)
      total += (payment['amount'] ?? 0.0);
    }
    return total;
  }

  double _calculateBalanceDue() {
    final totalPaid = _calculateTotalPaid();
    return _calculateGrandTotal() - totalPaid;
  }

  // Calculate CGST/SGST/IGST amounts if backend doesn't provide them
  double _getItemCgst(InvoiceItem item) {
    if (item.cgstAmount != null && item.cgstAmount! > 0) {
      return item.cgstAmount!;
    }
    // Calculate: (quantity * unitPrice - discount) * (gstRate / 2) / 100
    final taxableAmount = (item.quantity * item.unitPrice) - item.discount;
    if (_invoice!.taxType == 'INTRASTATE') {
      return taxableAmount * (item.gstRate / 2) / 100;
    }
    return 0.0;
  }

  double _getItemSgst(InvoiceItem item) {
    if (item.sgstAmount != null && item.sgstAmount! > 0) {
      return item.sgstAmount!;
    }
    final taxableAmount = (item.quantity * item.unitPrice) - item.discount;
    if (_invoice!.taxType == 'INTRASTATE') {
      return taxableAmount * (item.gstRate / 2) / 100;
    }
    return 0.0;
  }

  double _getItemIgst(InvoiceItem item) {
    if (item.igstAmount != null && item.igstAmount! > 0) {
      return item.igstAmount!;
    }
    final taxableAmount = (item.quantity * item.unitPrice) - item.discount;
    if (_invoice!.taxType == 'INTERSTATE') {
      return taxableAmount * item.gstRate / 100;
    }
    return 0.0;
  }

  double _calculateTotalCgst() {
    if (_invoice!.totalCgst > 0) return _invoice!.totalCgst;
    double total = 0.0;
    if (_invoice!.items != null) {
      for (var item in _invoice!.items!) {
        total += _getItemCgst(item);
      }
    }
    return total;
  }

  double _calculateTotalSgst() {
    if (_invoice!.totalSgst > 0) return _invoice!.totalSgst;
    double total = 0.0;
    if (_invoice!.items != null) {
      for (var item in _invoice!.items!) {
        total += _getItemSgst(item);
      }
    }
    return total;
  }

  double _calculateTotalIgst() {
    if (_invoice!.totalIgst > 0) return _invoice!.totalIgst;
    double total = 0.0;
    if (_invoice!.items != null) {
      for (var item in _invoice!.items!) {
        total += _getItemIgst(item);
      }
    }
    return total;
  }

  double _calculateGrandTotal() {
    if (_invoice!.grandTotal > 0) return _invoice!.grandTotal;
    return _invoice!.subtotal +
        _calculateTotalCgst() +
        _calculateTotalSgst() +
        _calculateTotalIgst();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/invoices',
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _invoice?.invoiceNumber ?? 'Invoice',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Record Payment button - Only show if balance due
        if (_invoice != null && _calculateBalanceDue() > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _showRecordPaymentDialog,
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Record Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),

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
          icon: const Icon(Icons.more_vert, color: Colors.black87),
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
          _buildDetailItem('Invoice #', _invoice!.invoiceNumber),
          _buildDetailItem('Invoice Date', _formatDate(_invoice!.invoiceDate)),
          _buildDetailItem('Order #', _invoice!.orderNumber ?? '-'),
          _buildDetailItem('Place of Supply', _invoice!.billingState),
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
            style: const TextStyle(fontSize: 12, color: Colors.black54),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BILL TO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _invoice!.billingName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _invoice!.billingAddress,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              if (_invoice!.billingGstin != null) ...[
                const SizedBox(height: 4),
                Text(
                  'GSTIN: ${_invoice!.billingGstin}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
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
              const Text(
                'SHIP TO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _invoice!.shippingName ?? _invoice!.billingName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _invoice!.shippingAddress ?? _invoice!.billingAddress,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
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
    if (_invoice!.items == null || _invoice!.items!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No items', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

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
        ..._invoice!.items!.asMap().entries.map((e) {
          final i = e.key + 1;
          final item = e.value;
          final cgst = _getItemCgst(item);
          final sgst = _getItemSgst(item);
          final igst = _getItemIgst(item);
          final taxableAmt = (item.quantity * item.unitPrice) - item.discount;
          final totalAmt = taxableAmt + cgst + sgst + igst;

          return TableRow(
            children: [
              _buildTD('$i', center: true),
              _buildTD(item.itemDescription),
              _buildTD(item.hsnSacCode ?? '-', center: true),
              _buildTD('${item.quantity.toInt()}', center: true),
              _buildTD('₹${item.unitPrice.toStringAsFixed(2)}', right: true),
              _buildTD(
                '${(item.gstRate / 2).toStringAsFixed(1)}%',
                center: true,
              ),
              _buildTD('₹${cgst.toStringAsFixed(2)}', right: true),
              _buildTD(
                '${(item.gstRate / 2).toStringAsFixed(1)}%',
                center: true,
              ),
              _buildTD('₹${sgst.toStringAsFixed(2)}', right: true),
              _buildTD(
                '₹${totalAmt.toStringAsFixed(2)}',
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
              const Text(
                'TERMS & CONDITIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _invoice!.termsAndConditions ?? 'Payment due within 15 days.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
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
                _buildSR('Sub Total', _invoice!.subtotal),
                const Divider(height: 20),
                _buildSR('CGST', _invoice!.totalCgst),
                _buildSR('SGST', _invoice!.totalSgst),
                if (_invoice!.totalIgst > 0)
                  _buildSR('IGST', _invoice!.totalIgst),
                const Divider(height: 20),
                _buildSR(
                  'GRAND TOTAL',
                  _invoice!.grandTotal,
                  bold: true,
                  large: true,
                ),
                const Divider(height: 20),
                _buildSR('Total Paid', _calculateTotalPaid(), neg: true),
                _buildSR(
                  'BALANCE DUE',
                  _calculateBalanceDue(),
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
              color: highlight ? AppTheme.danger : Colors.black87,
            ),
          ),
          Text(
            '${neg ? '-' : ''}₹${amt.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: large ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: highlight ? AppTheme.danger : Colors.black87,
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

  void _showRecordPaymentDialog() {
    final balanceDue = _calculateBalanceDue();

    showDialog(
      context: context,
      builder: (context) => _RecordPaymentDialog(
        invoiceId: widget.invoiceId,
        invoiceNumber: _invoice!.invoiceNumber,
        customerId: _invoice!.customer,
        balanceDue: balanceDue,
        onSuccess: _loadInvoiceData,
      ),
    );
  }

  void _showRefundDialog(dynamic payment) {
    showDialog(
      context: context,
      builder: (context) => RefundPaymentDialog(
        payment: payment,
        invoiceId: widget.invoiceId,
        customerId: _invoice!.customer,
        onSuccess: _loadInvoiceData,
      ),
    );
  }

  Future<void> _deletePayment(dynamic payment) async {
    try {
      await _paymentService.deleteInvoicePayment(payment['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment deleted successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      await _loadInvoiceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting payment: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
}

/// Record Payment Dialog for Invoice
class _RecordPaymentDialog extends StatefulWidget {
  final int invoiceId;
  final String invoiceNumber;
  final int customerId;
  final double balanceDue;
  final VoidCallback onSuccess;

  const _RecordPaymentDialog({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.balanceDue,
    required this.onSuccess,
  });

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMode = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _depositedToBank = false;
  DateTime? _depositDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with balance due
    _amountController.text = widget.balanceDue.toStringAsFixed(2);
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
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payment, color: AppTheme.success),
          ),
          const SizedBox(width: 12),
          const Text('Record Payment'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Invoice: ${widget.invoiceNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Balance: ₹${widget.balanceDue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.danger,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'Invalid amount';
                    if (amount > widget.balanceDue)
                      return 'Cannot exceed balance';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Payment date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _paymentDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_paymentDate.day.toString().padLeft(2, '0')}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.year}',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Payment mode
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode *',
                    border: OutlineInputBorder(),
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
                  onChanged: (value) => setState(() => _paymentMode = value!),
                ),

                const SizedBox(height: 16),

                // Transaction reference
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Reference',
                    hintText: 'UPI ID, Cheque No, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Deposited to bank
                if (_paymentMode == 'CASH')
                  CheckboxListTile(
                    title: const Text('Deposited to Bank'),
                    value: _depositedToBank,
                    onChanged: (value) => setState(() {
                      _depositedToBank = value!;
                      if (!value) _depositDate = null;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),

                if (_depositedToBank) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _depositDate ?? _paymentDate,
                        firstDate: _paymentDate,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _depositDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Deposit Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _depositDate != null
                            ? '${_depositDate!.day.toString().padLeft(2, '0')}-${_depositDate!.month.toString().padLeft(2, '0')}-${_depositDate!.year}'
                            : 'Select date',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitPayment,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_isSubmitting ? 'Recording...' : 'Record Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payment = {
        'invoice': widget.invoiceId,
        'payment_date': _paymentDate.toIso8601String().split('T')[0],
        'amount': double.parse(_amountController.text),
        'payment_mode': _paymentMode,
        'deposited_to_bank': _depositedToBank,
        if (_depositDate != null)
          'deposit_date': _depositDate!.toIso8601String().split('T')[0],
        if (_referenceController.text.isNotEmpty)
          'transaction_reference': _referenceController.text,
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
      };

      // TODO: Call actual API to record payment
      // final created = await _paymentService.createInvoicePayment(payment);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ₹${_amountController.text} recorded successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording payment: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}
