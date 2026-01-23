import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

import 'package:tailoring_web/features/financials/models/receipt_voucher.dart';
import 'package:tailoring_web/features/financials/models/refund_voucher.dart';
import 'package:tailoring_web/features/financials/services/payment_service.dart';
import 'package:tailoring_web/features/financials/widgets/record_payment_dialog.dart';
import 'package:tailoring_web/features/financials/widgets/issue_refund_dialog.dart';

class PaymentHistoryItem {
  final bool isRefund;
  final DateTime date;
  final String number;
  final double amount;
  final String mode;
  final String? notes;
  final ReceiptVoucher? receipt;
  final RefundVoucher? refund;

  PaymentHistoryItem({
    required this.isRefund,
    required this.date,
    required this.number,
    required this.amount,
    required this.mode,
    this.notes,
    this.receipt,
    this.refund,
  });

  factory PaymentHistoryItem.fromReceipt(ReceiptVoucher receipt) {
    return PaymentHistoryItem(
      isRefund: false,
      date: receipt.receiptDate,
      number: receipt.voucherNumber,
      amount: receipt.totalAmount,
      mode: receipt.paymentMode,
      notes: receipt.notes,
      receipt: receipt,
    );
  }

  factory PaymentHistoryItem.fromRefund(RefundVoucher refund) {
    return PaymentHistoryItem(
      isRefund: true,
      date: refund.refundDate,
      number: refund.refundNumber,
      amount: refund.totalRefund,
      mode: refund.refundMode,
      notes: refund.notes,
      refund: refund,
    );
  }
}

class ItemsAndPaymentsTab extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final bool isLocked;
  final VoidCallback onRefresh;

  const ItemsAndPaymentsTab({
    super.key,
    required this.orderData,
    required this.isLocked,
    required this.onRefresh,
  });

  @override
  State<ItemsAndPaymentsTab> createState() => _ItemsAndPaymentsTabState();
}

class _ItemsAndPaymentsTabState extends State<ItemsAndPaymentsTab> {
  final _paymentService = PaymentService();
  bool _isPaymentHistoryExpanded = true;
  List<ReceiptVoucher> _receiptVouchers = [];
  List<RefundVoucher> _refundVouchers = [];
  List<PaymentHistoryItem> _paymentHistory = [];
  bool _isLoadingPayments = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    setState(() => _isLoadingPayments = true);
    try {
      final orderId = widget.orderData['id'] as int;
      final customerId = widget.orderData['customer'] as int;

      final vouchers = await _paymentService.getReceiptVouchersByOrder(orderId);
      final allRefunds = await _paymentService.getRefundVouchersByCustomer(
        customerId,
      );

      final receiptIds = vouchers.map((v) => v.id).toSet();
      final orderRefunds = allRefunds
          .where((r) => receiptIds.contains(r.receiptVoucher))
          .toList();

      final history = <PaymentHistoryItem>[
        ...vouchers.map((v) => PaymentHistoryItem.fromReceipt(v)),
        ...orderRefunds.map((r) => PaymentHistoryItem.fromRefund(r)),
      ];

      history.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _receiptVouchers = vouchers;
        _refundVouchers = orderRefunds;
        _paymentHistory = history;
        _isLoadingPayments = false;
      });
    } catch (e) {
      debugPrint('Error loading payments: $e');
      if (mounted) setState(() => _isLoadingPayments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.orderData['items'] as List?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildItemsCard(items)),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _buildFinancialSummaryCard(items)),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Items', style: AppTheme.heading3),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Center(child: Text('No items'))
          else
            _buildItemsTable(items),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List items) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Item')),
        DataColumn(label: Text('Qty')),
        DataColumn(label: Text('Amount')),
      ],
      rows: items
          .map(
            (item) => DataRow(
              cells: [
                DataCell(Text(item['item_name'] ?? 'N/A')),
                DataCell(Text('${item['quantity'] ?? 0}')),
                DataCell(Text('₹${item['total_price'] ?? 0}')),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildFinancialSummaryCard(List items) {
    double total = (widget.orderData['estimated_total'] ?? 0).toDouble();
    double collected = 0;
    for (var v in _receiptVouchers) collected += v.totalAmount;
    double refunded = 0;
    for (var r in _refundVouchers) refunded += r.totalRefund;

    double net = collected - refunded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _row('Total', '₹$total'),
          _row('Collected', '₹$net', color: AppTheme.success),
          const Divider(),
          _row('Balance', '₹${total - net}', isBold: true),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l),
            Text(
              v,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _buildPaymentHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('Payment History', style: AppTheme.heading3),
            trailing: ElevatedButton(
              onPressed: _onRecordPayment,
              child: const Text('Record Payment'),
            ),
          ),
          if (_isLoadingPayments)
            const LinearProgressIndicator()
          else
            _buildPaymentsTable(),
        ],
      ),
    );
  }

  Widget _buildPaymentsTable() {
    if (_paymentHistory.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No records'),
      );
    return DataTable(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Ref')),
        DataColumn(label: Text('Amount')),
      ],
      rows: _paymentHistory
          .map(
            (item) => DataRow(
              cells: [
                DataCell(Text(DateFormat('dd-MM-yyyy').format(item.date))),
                DataCell(Text(item.isRefund ? 'REFUND' : 'RECEIPT')),
                DataCell(Text(item.number)),
                DataCell(Text('₹${item.amount}')),
              ],
            ),
          )
          .toList(),
    );
  }

  void _onRecordPayment() async {
    await showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        orderData: widget.orderData,
        onPaymentRecorded: () {
          _loadPayments();
          widget.onRefresh();
        },
      ),
    );
    _loadPayments();
  }
}
