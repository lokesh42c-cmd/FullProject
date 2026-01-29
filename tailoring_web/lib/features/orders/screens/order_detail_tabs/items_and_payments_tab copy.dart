import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/financials/models/receipt_voucher.dart';
import 'package:tailoring_web/features/financials/models/refund_voucher.dart';
import 'package:tailoring_web/features/financials/models/invoice_payment.dart';
import 'package:tailoring_web/features/financials/services/payment_service.dart';
import 'package:tailoring_web/features/financials/widgets/record_payment_dialog.dart';
import 'package:tailoring_web/features/financials/widgets/issue_refund_dialog.dart';

class ItemsAndPaymentsTab extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onUpdate;

  const ItemsAndPaymentsTab({
    super.key,
    required this.orderData,
    required this.onUpdate,
  });

  @override
  State<ItemsAndPaymentsTab> createState() => _ItemsAndPaymentsTabState();
}

class _ItemsAndPaymentsTabState extends State<ItemsAndPaymentsTab> {
  final PaymentService _paymentService = PaymentService();

  List<ReceiptVoucher> _receiptVouchers = [];
  List<InvoicePayment> _invoicePayments = [];
  List<RefundVoucher> _refundVouchers = [];
  bool _isLoadingPayments = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void didUpdateWidget(ItemsAndPaymentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orderData['id'] != oldWidget.orderData['id']) {
      _loadPayments();
    }
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoadingPayments = true);

    try {
      final orderId = widget.orderData['id'];

      final receipts = await _paymentService.getReceiptVouchersByOrder(orderId);

      List<InvoicePayment> invoicePayments = [];
      if (widget.orderData['invoice_id'] != null) {
        invoicePayments = await _paymentService.getInvoicePaymentsByInvoice(
          widget.orderData['invoice_id'],
        );
      }

      List<RefundVoucher> allRefunds = [];
      for (var receipt in receipts) {
        try {
          final refunds = await _paymentService.getRefundVouchersByReceipt(
            receipt.id!,
          );
          allRefunds.addAll(refunds);
        } catch (e) {
          // Skip if no refunds for this receipt
        }
      }

      if (mounted) {
        setState(() {
          _receiptVouchers = receipts;
          _invoicePayments = invoicePayments;
          _refundVouchers = allRefunds;
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      print('Error loading payments: $e');
      if (mounted) {
        setState(() => _isLoadingPayments = false);
      }
    }
  }

  // Calculate totals using BACKEND calculated fields
  Map<String, double> _calculateFinancials() {
    final items = widget.orderData['items'] as List<dynamic>? ?? [];

    double subtotal = 0.0;
    double totalDiscount = 0.0;
    double totalTax = 0.0;
    double grandTotal = 0.0;

    for (var item in items) {
      // Use backend calculated fields
      subtotal += _parseDouble(item['subtotal']);
      totalDiscount += _parseDouble(item['discount']);
      totalTax += _parseDouble(item['tax_amount']);
      grandTotal += _parseDouble(item['total_price']);
    }

    return {
      'subtotal': subtotal,
      'discount': totalDiscount,
      'tax': totalTax,
      'grandTotal': grandTotal,
    };
  }

  double _calculateTotalPaid() {
    double total = 0.0;
    for (var receipt in _receiptVouchers) {
      total += receipt.totalAmount;
    }
    for (var payment in _invoicePayments) {
      total += payment.amount;
    }
    return total;
  }

  double _calculateTotalRefunds() {
    double total = 0.0;
    for (var refund in _refundVouchers) {
      total += refund.totalRefund;
    }
    return total;
  }

  int _getItemCount() {
    final items = widget.orderData['items'] as List<dynamic>? ?? [];
    return items.length;
  }

  double _getTotalQuantity() {
    final items = widget.orderData['items'] as List<dynamic>? ?? [];
    double total = 0.0;
    for (var item in items) {
      total += _parseDouble(item['quantity']);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderItemsSection(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildFinancialSummary()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildPaymentHistorySection()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    final items = widget.orderData['items'] as List<dynamic>? ?? [];
    final itemCount = _getItemCount();
    final totalQty = _getTotalQuantity();

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
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$itemCount items • Qty: ${totalQty.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No items in this order')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 300,
                  ),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FixedColumnWidth(180), // Item Name
                      1: FixedColumnWidth(100), // Item Code
                      2: FixedColumnWidth(150), // Description
                      3: FixedColumnWidth(80), // Type
                      4: FixedColumnWidth(60), // Qty
                      5: FixedColumnWidth(90), // Price
                      6: FixedColumnWidth(80), // Discount
                      7: FixedColumnWidth(70), // Tax %
                      8: FixedColumnWidth(100), // Total
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        children: [
                          _tableHeader('Item Name'),
                          _tableHeader('Item Code'),
                          _tableHeader('Description'),
                          _tableHeader('Type'),
                          _tableHeader('Qty'),
                          _tableHeader('Price'),
                          _tableHeader('Discount'),
                          _tableHeader('Tax %'),
                          _tableHeader('Total'),
                        ],
                      ),
                      ...items.map((item) {
                        return TableRow(
                          children: [
                            _tableCell(item['item_name'] ?? 'Unknown'),
                            _tableCell(item['item_barcode'] ?? '-'),
                            _tableCell(item['item_description'] ?? '-'),
                            _tableCell(_getItemType(item['item_type'])),
                            _tableCell(
                              _parseDouble(item['quantity']).toStringAsFixed(0),
                            ),
                            _tableCell('₹${_formatAmount(item['unit_price'])}'),
                            _tableCell(
                              _parseDouble(item['discount']) > 0
                                  ? '₹${_formatAmount(item['discount'])}'
                                  : '-',
                            ),
                            _tableCell(
                              '${_parseDouble(item['tax_percentage']).toStringAsFixed(0)}%',
                            ),
                            _tableCell(
                              '₹${_formatAmount(item['total_price'])}',
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getItemType(String? type) {
    if (type == 'SERVICE') return 'Service';
    if (type == 'PRODUCT') return 'Product';
    return type ?? '-';
  }

  Widget _buildFinancialSummary() {
    final financials = _calculateFinancials();
    final totalPaid = _calculateTotalPaid();
    final totalRefunds = _calculateTotalRefunds();
    final grandTotal = financials['grandTotal']!;
    final netPaid = totalPaid - totalRefunds;
    final balanceDue = grandTotal - netPaid;

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

            _summaryRow('Subtotal', financials['subtotal']!),
            const SizedBox(height: 8),

            if (financials['discount']! > 0) ...[
              _summaryRow(
                'Discount',
                financials['discount']!,
                color: AppTheme.success,
              ),
              const SizedBox(height: 8),
            ],

            _summaryRow('Tax', financials['tax']!),
            const Divider(height: 20),

            _summaryRow('Grand Total', grandTotal, isBold: true, isLarge: true),
            const SizedBox(height: 16),

            _summaryRow('Paid', totalPaid, color: AppTheme.success),
            const SizedBox(height: 8),

            _summaryRow('Refunds', totalRefunds, color: AppTheme.danger),
            const SizedBox(height: 8),

            _summaryRow(
              'Balance',
              balanceDue,
              isBold: true,
              color: balanceDue > 0 ? AppTheme.danger : AppTheme.success,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                fontSize: isLarge ? 17 : 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              fontSize: isLarge ? 17 : 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
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
                const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _onRecordPayment,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Record Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingPayments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_receiptVouchers.isEmpty &&
                _invoicePayments.isEmpty &&
                _refundVouchers.isEmpty)
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
              _buildPaymentTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTable() {
    List<Map<String, dynamic>> allPayments = [];

    for (var receipt in _receiptVouchers) {
      allPayments.add({
        'type': 'RECEIPT',
        'date': receipt.receiptDate.toIso8601String().split('T')[0],
        'number': receipt.voucherNumber,
        'mode': receipt.paymentModeDisplay ?? receipt.paymentMode,
        'amount': receipt.totalAmount,
        'data': receipt,
      });
    }

    for (var payment in _invoicePayments) {
      allPayments.add({
        'type': 'PAYMENT',
        'date': payment.paymentDate,
        'number': payment.paymentNumber,
        'mode': payment.paymentModeDisplay ?? payment.paymentMode,
        'amount': payment.amount,
        'data': payment,
      });
    }

    for (var refund in _refundVouchers) {
      allPayments.add({
        'type': 'REFUND',
        'date': refund.refundDate.toIso8601String().split('T')[0],
        'number': refund.refundNumber,
        'mode': refund.refundModeDisplay ?? refund.refundMode,
        'amount': refund.totalRefund,
        'data': refund,
      });
    }

    allPayments.sort((a, b) => b['date'].compareTo(a['date']));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.4,
        ),
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {
            0: FixedColumnWidth(110),
            1: FixedColumnWidth(110),
            2: FixedColumnWidth(160),
            3: FixedColumnWidth(100),
            4: FixedColumnWidth(110),
            5: FixedColumnWidth(90),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: [
                _tableHeader('Type'),
                _tableHeader('Date'),
                _tableHeader('Number'),
                _tableHeader('Mode'),
                _tableHeader('Amount'),
                _tableHeader('Actions'),
              ],
            ),
            ...allPayments.map((payment) {
              return TableRow(
                children: [
                  _tableCellWidget(_buildTypeBadge(payment['type'])),
                  _tableCell(payment['date']),
                  _tableCell(payment['number']),
                  _tableCell(payment['mode']),
                  _tableCell(
                    payment['type'] == 'REFUND'
                        ? '- ₹${_formatAmount(payment['amount'])}'
                        : '₹${_formatAmount(payment['amount'])}',
                    color: payment['type'] == 'REFUND'
                        ? AppTheme.danger
                        : AppTheme.success,
                  ),
                  _tableCellWidget(_actionCell(payment)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color;
    String label;
    IconData icon;

    switch (type) {
      case 'RECEIPT':
        color = AppTheme.success;
        label = 'Advance';
        icon = Icons.money;
        break;
      case 'PAYMENT':
        color = AppTheme.primaryBlue;
        label = 'Payment';
        icon = Icons.payment;
        break;
      case 'REFUND':
        color = AppTheme.danger;
        label = 'Refund';
        icon = Icons.keyboard_return;
        break;
      default:
        color = Colors.grey;
        label = type;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _tableCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCellWidget(Widget widget) {
    return Padding(padding: const EdgeInsets.all(6), child: widget);
  }

  Widget _actionCell(Map<String, dynamic> payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (payment['type'] == 'RECEIPT')
          IconButton(
            icon: const Icon(Icons.keyboard_return, size: 16),
            tooltip: 'Refund',
            onPressed: () => _onIssueRefund(payment['data']),
            color: AppTheme.danger,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        if (payment['type'] == 'RECEIPT') const SizedBox(width: 2),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16),
          tooltip: 'Delete',
          onPressed: () => _onDeletePayment(payment),
          color: AppTheme.danger,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  void _onRecordPayment() {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        orderData: widget.orderData,
        invoiceId: widget.orderData['invoice_id'],
        onPaymentRecorded: () {
          _loadPayments();
          widget.onUpdate();
        },
      ),
    );
  }

  void _onIssueRefund(ReceiptVoucher receipt) {
    showDialog(
      context: context,
      builder: (context) => IssueRefundDialog(
        receiptVoucher: receipt,
        onRefundIssued: () {
          _loadPayments();
          widget.onUpdate();
        },
      ),
    );
  }

  Future<void> _onDeletePayment(Map<String, dynamic> payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment?'),
        content: Text(
          'Are you sure you want to delete this ${payment['type'].toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      switch (payment['type']) {
        case 'RECEIPT':
          await _paymentService.deleteReceiptVoucher(payment['data'].id);
          break;
        case 'PAYMENT':
          await _paymentService.deleteInvoicePayment(payment['data'].id);
          break;
        case 'REFUND':
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refunds cannot be deleted'),
                backgroundColor: AppTheme.warning,
              ),
            );
          }
          return;
      }

      _loadPayments();
      widget.onUpdate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${payment['type']} deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatAmount(dynamic amount) {
    return _parseDouble(amount).toStringAsFixed(2);
  }
}
