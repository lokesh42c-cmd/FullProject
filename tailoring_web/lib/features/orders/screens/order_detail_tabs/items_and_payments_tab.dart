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

  Map<String, double> _calculateFinancials() {
    final items = widget.orderData['items'] as List<dynamic>? ?? [];

    double subtotal = 0.0;
    double totalDiscount = 0.0;
    double totalTax = 0.0;
    double grandTotal = 0.0;

    for (var item in items) {
      subtotal += _parseDouble(item['subtotal']);
      totalDiscount += _parseDouble(item['discount_amount']);
      totalTax += _parseDouble(item['tax_amount']);
      grandTotal += _parseDouble(item['total_price']);
    }

    double totalPaid = 0.0;
    for (var receipt in _receiptVouchers) {
      totalPaid += receipt.totalAmount;
    }
    for (var payment in _invoicePayments) {
      totalPaid += payment.amount;
    }

    double totalRefunds = 0.0;
    for (var refund in _refundVouchers) {
      totalRefunds += refund.totalRefund;
    }

    final balance = grandTotal - totalPaid + totalRefunds;

    return {
      'subtotal': subtotal,
      'discount': totalDiscount,
      'tax': totalTax,
      'grandTotal': grandTotal,
      'totalPaid': totalPaid,
      'totalRefunds': totalRefunds,
      'balance': balance,
    };
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemsSection(),
          const SizedBox(height: AppTheme.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPaymentHistorySection()),
              const SizedBox(width: AppTheme.space4),
              _buildFinancialSummary(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    final items = widget.orderData['items'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundGrey,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: const Text('Order Items', style: AppTheme.heading3),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space5),
              child: Center(
                child: Text(
                  'No items added yet',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 400,
                ),
                child: DataTable(
                  border: TableBorder.all(color: AppTheme.borderLight),
                  headingRowColor: MaterialStateProperty.all(
                    AppTheme.backgroundGrey,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text('Service', style: AppTheme.tableHeader),
                    ),
                    DataColumn(
                      label: Text('Quantity', style: AppTheme.tableHeader),
                    ),
                    DataColumn(
                      label: Text('Unit Price', style: AppTheme.tableHeader),
                    ),
                    DataColumn(
                      label: Text('Discount', style: AppTheme.tableHeader),
                    ),
                    DataColumn(label: Text('Tax', style: AppTheme.tableHeader)),
                    DataColumn(
                      label: Text('Total', style: AppTheme.tableHeader),
                    ),
                  ],
                  rows: items.map<DataRow>((item) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item['item_description'] ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['quantity']?.toString() ?? '0',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            '₹${_parseDouble(item['unit_price']).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            '₹${_parseDouble(item['discount_amount']).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            '₹${_parseDouble(item['tax_amount']).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            '₹${_parseDouble(item['total_price']).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    List<Map<String, dynamic>> allPayments = [];

    for (var receipt in _receiptVouchers) {
      allPayments.add({
        'type': 'RECEIPT',
        'date': receipt.formattedReceiptDate,
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
        'date': refund.formattedRefundDate,
        'number': refund.refundNumber,
        'mode': refund.refundModeDisplay ?? refund.refundMode,
        'amount': refund.totalRefund,
        'data': refund,
      });
    }

    allPayments.sort((a, b) {
      try {
        final dateA = a['date'] is DateTime
            ? a['date'] as DateTime
            : DateTime.parse(a['date'] as String);
        final dateB = b['date'] is DateTime
            ? b['date'] as DateTime
            : DateTime.parse(b['date'] as String);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundGrey,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Text('Payment History', style: AppTheme.heading3),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _onRecordPayment,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Record Payment',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _isLoadingPayments
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : allPayments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No payments recorded yet',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    headingRowHeight: 40,
                    dataRowHeight: 48,
                    border: TableBorder.all(
                      color: AppTheme.borderLight,
                      width: 0.5,
                    ),
                    headingRowColor: MaterialStateProperty.all(
                      AppTheme.backgroundGrey,
                    ),
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 80,
                          child: Text(
                            'Type',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 75,
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 110,
                          child: Text(
                            'Number',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 50,
                          child: Text(
                            'Mode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 70,
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: allPayments.map<DataRow>((payment) {
                      return DataRow(
                        cells: [
                          DataCell(_buildTypeBadge(payment['type'])),
                          DataCell(
                            Text(
                              _formatCompactDate(payment['date']),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              payment['number'],
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            Text(
                              _getCompactMode(payment['mode']),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹${payment['amount'].toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: payment['type'] == 'REFUND'
                                    ? AppTheme.danger
                                    : AppTheme.success,
                              ),
                            ),
                          ),
                          DataCell(_buildActionCell(payment)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  String _formatCompactDate(dynamic date) {
    try {
      DateTime dateTime;

      // Handle different date formats
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        // Try parsing various formats
        if (date.contains('T')) {
          // ISO format: 2026-01-27T10:30:00
          dateTime = DateTime.parse(date);
        } else if (date.contains('-')) {
          // Date format: 2026-01-27 or 27-01-2026
          final parts = date.split('-');
          if (parts[0].length == 4) {
            // Format: 2026-01-27 (yyyy-mm-dd)
            dateTime = DateTime.parse(date);
          } else {
            // Format: 27-01-2026 (dd-mm-yyyy) - already correct
            return date;
          }
        } else {
          dateTime = DateTime.parse(date);
        }
      } else {
        return date.toString();
      }

      // ✅ Always return dd-mm-yyyy format (4-digit year)
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      print('Date parsing error: $e for date: $date');
      return date.toString();
    }
  }

  String _getCompactMode(String mode) {
    // ✅ FIXED: Removed duplicate 'UPI' key
    final modeMap = {
      'Cash': 'Cash',
      'Card': 'Card',
      'UPI': 'UPI',
      'Bank Transfer': 'Bank',
      'Cheque': 'Chq',
      'CASH': 'Cash',
      'CARD': 'Card',
      'BANK_TRANSFER': 'Bank',
      'CHEQUE': 'Chq',
    };
    return modeMap[mode] ?? (mode.length > 4 ? mode.substring(0, 4) : mode);
  }

  Widget _buildTypeBadge(String type) {
    String label;
    Color color;
    IconData icon;

    switch (type) {
      case 'RECEIPT':
        label = 'Adv';
        color = AppTheme.success;
        icon = Icons.attach_money;
        break;
      case 'PAYMENT':
        label = 'Pay';
        color = AppTheme.primaryBlue;
        icon = Icons.payment;
        break;
      case 'REFUND':
        label = 'Ref';
        color = AppTheme.danger;
        icon = Icons.keyboard_return;
        break;
      default:
        label = type;
        color = AppTheme.textSecondary;
        icon = Icons.money;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
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

  Widget _buildActionCell(Map<String, dynamic> payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (payment['type'] == 'RECEIPT')
          IconButton(
            icon: const Icon(Icons.keyboard_return, size: 14),
            tooltip: 'Refund',
            onPressed: () => _onIssueRefund(payment['data']),
            color: AppTheme.danger,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 14),
          tooltip: 'Delete',
          onPressed: () => _onDeletePayment(payment),
          color: AppTheme.danger,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    final financials = _calculateFinancials();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundGrey,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: const Text(
              'Financial Summary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _summaryRow('Subtotal', financials['subtotal']!),
                _summaryRow('Tax', financials['tax']!),
                const Divider(height: 16),
                _summaryRow('Total', financials['grandTotal']!, isBold: true),
                const SizedBox(height: 8),
                _summaryRow(
                  'Paid',
                  financials['totalPaid']!,
                  color: AppTheme.success,
                ),
                if (financials['totalRefunds']! > 0)
                  _summaryRow(
                    'Refunds',
                    financials['totalRefunds']!,
                    isNegative: true,
                    color: AppTheme.danger,
                  ),
                const Divider(height: 16),
                _summaryRow(
                  'Balance',
                  financials['balance']!,
                  isBold: true,
                  color: financials['balance']! > 0
                      ? AppTheme.warning
                      : AppTheme.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isNegative = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
              color:
                  color ??
                  (isNegative ? AppTheme.success : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
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
    final type = payment['type'];
    final data = payment['data'];

    if (type == 'REFUND') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Refunds cannot be deleted. Please contact support if needed.',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${type == 'RECEIPT' ? 'Advance Payment' : 'Invoice Payment'}?',
        ),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (type == 'RECEIPT') {
        await _paymentService.deleteReceiptVoucher(data.id!);
      } else if (type == 'PAYMENT') {
        await _paymentService.deleteInvoicePayment(data.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment deleted successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadPayments();
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete payment: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}
