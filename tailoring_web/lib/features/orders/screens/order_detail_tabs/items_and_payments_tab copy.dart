import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

import 'package:tailoring_web/features/financials/models/receipt_voucher.dart';
import 'package:tailoring_web/features/financials/models/refund_voucher.dart';
import 'package:tailoring_web/features/financials/services/payment_service.dart';
import 'package:tailoring_web/features/financials/widgets/record_payment_dialog.dart';
import 'package:tailoring_web/features/financials/widgets/issue_refund_dialog.dart';

// Helper class to merge receipts and refunds
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
    Key? key,
    required this.orderData,
    required this.isLocked,
    required this.onRefresh,
  }) : super(key: key);

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

      // Load both receipts and refunds
      final vouchers = await _paymentService.getReceiptVouchersByOrder(orderId);

      // Load refunds for this order's customer
      final customerId = widget.orderData['customer'] as int;
      final allRefunds = await _paymentService.getRefundVouchersByCustomer(
        customerId,
      );

      // Filter refunds that are related to this order's receipts
      final receiptIds = vouchers.map((v) => v.id).toSet();
      final orderRefunds = allRefunds
          .where((r) => receiptIds.contains(r.receiptVoucher))
          .toList();

      // Merge into payment history
      final history = <PaymentHistoryItem>[
        ...vouchers.map((v) => PaymentHistoryItem.fromReceipt(v)),
        ...orderRefunds.map((r) => PaymentHistoryItem.fromRefund(r)),
      ];

      // Sort by date (newest first)
      history.sort((a, b) => b.date.compareTo(a.date));

      print(
        '🔍 Loaded ${vouchers.length} receipts, ${orderRefunds.length} refunds',
      );

      if (!mounted) return;
      setState(() {
        _receiptVouchers = vouchers;
        _refundVouchers = orderRefunds;
        _paymentHistory = history;
        _isLoadingPayments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPayments = false);
      print('❌ Error loading payments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.orderData['items'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items and Financial Summary Row (70/30 split for better balance)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Items Table (70%)
              Expanded(flex: 70, child: _buildItemsCard(items)),
              const SizedBox(width: 16),
              // Financial Summary (30%)
              Expanded(flex: 30, child: _buildFinancialSummaryCard(items)),
            ],
          ),
          const SizedBox(height: 16),

          // Payment History (Collapsible)
          _buildPaymentHistoryCard(),
          const SizedBox(height: 100),
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
          Row(
            children: const [
              Icon(Icons.shopping_cart, color: AppTheme.primaryBlue, size: 18),
              SizedBox(width: 8),
              Text('Order Items', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _buildEmptyItemsState()
          else
            _buildItemsTable(items),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: AppTheme.borderLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No items added yet',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(List items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AppTheme.backgroundGrey),
        columnSpacing: 16,
        horizontalMargin: 0,
        dataRowMinHeight: 48,
        headingTextStyle: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
        dataTextStyle: AppTheme.bodyMedium,
        columns: const [
          DataColumn(label: Text('Item Name')),
          DataColumn(label: Text('Qty'), numeric: true),
          DataColumn(label: Text('Rate'), numeric: true),
          DataColumn(label: Text('Disc'), numeric: true),
          DataColumn(label: Text('Tax%'), numeric: true),
          DataColumn(label: Text('Amount'), numeric: true),
          DataColumn(label: Text('')),
        ],
        rows: items.map<DataRow>((item) {
          final itemName =
              item['item_name'] ?? item['item_description'] ?? 'N/A';
          final quantity = (item['quantity'] ?? 0).toDouble();
          final unitPrice = (item['unit_price'] ?? 0).toDouble();
          final discount = (item['discount'] ?? 0).toDouble();
          final taxPercentage = (item['tax_percentage'] ?? 0).toDouble();
          final totalPrice = (item['total_price'] ?? 0).toDouble();

          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(itemName, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(Text(quantity.toStringAsFixed(2))),
              DataCell(Text('₹${unitPrice.toStringAsFixed(2)}')),
              DataCell(
                discount > 0
                    ? Text(
                        '₹${discount.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.danger,
                        ),
                      )
                    : const Text('-'),
              ),
              DataCell(Text('${taxPercentage.toStringAsFixed(1)}%')),
              DataCell(
                Text(
                  '₹${totalPrice.toStringAsFixed(2)}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                widget.isLocked
                    ? const SizedBox.shrink()
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _onEditItem(context, item);
                          } else if (value == 'delete') {
                            _onDeleteItem(context, item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Item'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: AppTheme.danger,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Item',
                                  style: TextStyle(color: AppTheme.danger),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(List items) {
    double subtotalBeforeDiscount = 0.0;
    double totalDiscount = 0.0;
    double subtotal = 0.0;
    double totalTax = 0.0;
    double grandTotal = 0.0;

    for (var item in items) {
      final quantity = (item['quantity'] ?? 0).toDouble();
      final unitPrice = (item['unit_price'] ?? 0).toDouble();
      final discount = (item['discount'] ?? 0).toDouble();
      final itemSubtotal = (quantity * unitPrice) - discount;
      final taxAmount =
          (itemSubtotal * (item['tax_percentage'] ?? 0).toDouble()) / 100;

      subtotalBeforeDiscount += quantity * unitPrice;
      totalDiscount += discount;
      subtotal += itemSubtotal;
      totalTax += taxAmount;
      grandTotal += itemSubtotal + taxAmount;
    }

    final orderTotal = (widget.orderData['estimated_total'] ?? grandTotal)
        .toDouble();

    // Calculate net advance: receipts minus refunds
    double advanceReceived = 0.0;
    for (var voucher in _receiptVouchers) {
      advanceReceived += voucher.totalAmount;
    }

    double totalRefunded = 0.0;
    for (var refund in _refundVouchers) {
      totalRefunded += refund.totalRefund;
    }

    final netAdvance = advanceReceived - totalRefunded;
    final balanceDue = orderTotal - netAdvance;

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
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppTheme.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Financial Summary',
                  style: AppTheme.heading3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFinancialRow('Total Items', '${items.length}'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildFinancialRow(
            'Subtotal',
            '₹${subtotalBeforeDiscount.toStringAsFixed(2)}',
          ),
          if (totalDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildFinancialRow(
              'Discount',
              '- ₹${totalDiscount.toStringAsFixed(2)}',
              color: AppTheme.danger,
            ),
            const SizedBox(height: 8),
            _buildFinancialRow(
              'After Discount',
              '₹${subtotal.toStringAsFixed(2)}',
            ),
          ],
          const SizedBox(height: 8),
          _buildFinancialRow('Tax (GST)', '₹${totalTax.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildFinancialRow(
            'Grand Total',
            '₹${grandTotal.toStringAsFixed(2)}',
            isBold: true,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildFinancialRow(
            'Receipts',
            '₹${advanceReceived.toStringAsFixed(2)}',
            color: AppTheme.success,
          ),
          if (totalRefunded > 0) ...[
            const SizedBox(height: 8),
            _buildFinancialRow(
              'Refunds',
              '-₹${totalRefunded.toStringAsFixed(2)}',
              color: AppTheme.danger,
            ),
          ],
          const SizedBox(height: 8),
          _buildFinancialRow(
            'Net Advance',
            '₹${netAdvance.toStringAsFixed(2)}',
            isBold: true,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildFinancialRow(
            'Balance Due',
            '₹${balanceDue.toStringAsFixed(2)}',
            isBold: true,
            color: balanceDue > 0 ? AppTheme.warning : AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: color ?? AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryCard() {
    final items = (widget.orderData['items'] as List?) ?? [];

    double grandTotal = 0.0;
    for (var item in items) {
      final quantity = (item['quantity'] ?? 0).toDouble();
      final unitPrice = (item['unit_price'] ?? 0).toDouble();
      final discount = (item['discount'] ?? 0).toDouble();
      final itemSubtotal = (quantity * unitPrice) - discount;
      final taxAmount =
          (itemSubtotal * (item['tax_percentage'] ?? 0).toDouble()) / 100;
      grandTotal += itemSubtotal + taxAmount;
    }

    final orderTotal = (widget.orderData['estimated_total'] ?? grandTotal)
        .toDouble();

    // Calculate net advance: receipts minus refunds
    double advanceReceived = 0.0;
    for (var voucher in _receiptVouchers) {
      advanceReceived += voucher.totalAmount;
    }

    double totalRefunded = 0.0;
    for (var refund in _refundVouchers) {
      totalRefunded += refund.totalRefund;
    }

    final netAdvance = advanceReceived - totalRefunded;
    final balanceDue = orderTotal - netAdvance;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isPaymentHistoryExpanded = !_isPaymentHistoryExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.payment,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text('Payment History', style: AppTheme.heading3),
                  const Spacer(),
                  if (_paymentHistory.isNotEmpty) ...[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Net Collected: ₹${netAdvance.toStringAsFixed(2)}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    _isPaymentHistoryExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_isPaymentHistoryExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingPayments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_paymentHistory.isEmpty)
                    _buildEmptyPaymentsState()
                  else
                    _buildPaymentsTable(),
                  if (!widget.isLocked && balanceDue > 0) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onRecordPayment,
                        icon: const Icon(Icons.payment),
                        label: const Text('Record Payment'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPaymentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.payment_outlined, size: 64, color: AppTheme.borderLight),
            const SizedBox(height: 16),
            Text(
              'No payments recorded yet',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Payments will appear here once recorded',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AppTheme.backgroundGrey),
        columnSpacing: 16,
        horizontalMargin: 0,
        dataRowMinHeight: 48,
        headingTextStyle: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
        dataTextStyle: AppTheme.bodyMedium,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Type / Number')),
          DataColumn(label: Text('Mode')),
          DataColumn(label: Text('Base Amount'), numeric: true),
          DataColumn(label: Text('GST %'), numeric: true),
          DataColumn(label: Text('GST Amount'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Notes')),
          DataColumn(label: Text('')),
        ],
        rows: _paymentHistory.map<DataRow>((item) {
          final isRefund = item.isRefund;
          final voucher = item.receipt;
          final refund = item.refund;

          return DataRow(
            cells: [
              // Date
              DataCell(
                Text(_formatDate(item.date), style: AppTheme.bodyMedium),
              ),
              // Type & Number with badge
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isRefund
                            ? AppTheme.danger.withOpacity(0.1)
                            : AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isRefund
                              ? AppTheme.danger.withOpacity(0.3)
                              : AppTheme.success.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isRefund ? 'REFUND' : 'RECEIPT',
                        style: AppTheme.bodySmall.copyWith(
                          color: isRefund ? AppTheme.danger : AppTheme.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Number
                    Text(
                      item.number,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isRefund
                            ? AppTheme.danger
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              // Mode
              DataCell(_buildPaymentModeBadge(item.mode)),
              // Base Amount (negative for refunds)
              DataCell(
                Text(
                  isRefund
                      ? '-₹${refund!.refundAmount.toStringAsFixed(2)}'
                      : '₹${voucher!.advanceAmount.toStringAsFixed(2)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: isRefund ? AppTheme.danger : null,
                    fontWeight: isRefund ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              // GST %
              DataCell(
                Text(
                  isRefund
                      ? refund!.gstRate > 0
                            ? '${refund.gstRate.toStringAsFixed(0)}%'
                            : '-'
                      : voucher!.gstRate > 0
                      ? '${voucher.gstRate.toStringAsFixed(0)}%'
                      : '-',
                  style: AppTheme.bodyMedium.copyWith(
                    color: (isRefund ? refund!.gstRate : voucher!.gstRate) > 0
                        ? (isRefund ? AppTheme.danger : AppTheme.textPrimary)
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
              // GST Amount (negative for refunds)
              DataCell(
                Text(
                  isRefund
                      ? refund!.gstRate > 0
                            ? '-₹${(refund.cgstAmount + refund.sgstAmount + refund.igstAmount).toStringAsFixed(2)}'
                            : '-'
                      : voucher!.gstRate > 0
                      ? '₹${(voucher.cgstAmount + voucher.sgstAmount + voucher.igstAmount).toStringAsFixed(2)}'
                      : '-',
                  style: AppTheme.bodyMedium.copyWith(
                    color: (isRefund ? refund!.gstRate : voucher!.gstRate) > 0
                        ? (isRefund ? AppTheme.danger : AppTheme.textPrimary)
                        : AppTheme.textSecondary,
                    fontWeight: isRefund ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              // Total (negative for refunds)
              DataCell(
                Text(
                  isRefund
                      ? '-₹${refund!.totalRefund.toStringAsFixed(2)}'
                      : '₹${voucher!.totalAmount.toStringAsFixed(2)}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isRefund ? AppTheme.danger : AppTheme.success,
                  ),
                ),
              ),
              // Notes
              DataCell(
                item.notes != null && item.notes!.isNotEmpty
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Tooltip(
                          message: item.notes!,
                          child: Text(
                            item.notes!,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodySmall,
                          ),
                        ),
                      )
                    : const Text('-'),
              ),
              // Actions (only for receipts)
              DataCell(
                !isRefund
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'view') {
                            _onViewReceipt(context, voucher!);
                          } else if (value == 'print') {
                            _onPrintReceipt(context, voucher!);
                          } else if (value == 'refund') {
                            _onRefundPayment(context, voucher!);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'print',
                            child: Row(
                              children: [
                                Icon(Icons.print, size: 18),
                                SizedBox(width: 8),
                                Text('Print Receipt'),
                              ],
                            ),
                          ),
                          if (!widget.isLocked)
                            const PopupMenuItem(
                              value: 'refund',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.money_off,
                                    size: 18,
                                    color: AppTheme.danger,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Process Refund',
                                    style: TextStyle(color: AppTheme.danger),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentModeBadge(String mode) {
    Color color;
    IconData icon;

    // Using ONLY existing AppTheme colors
    switch (mode.toUpperCase()) {
      case 'CASH':
        color = AppTheme.success;
        icon = Icons.money;
        break;
      case 'UPI':
        color = AppTheme.primaryBlue;
        icon = Icons.smartphone;
        break;
      case 'CARD':
        color = AppTheme.warning; // Using existing warning color (orange)
        icon = Icons.credit_card;
        break;
      case 'BANK_TRANSFER':
        color = AppTheme.info; // Using existing info color (blue)
        icon = Icons.account_balance;
        break;
      default:
        color = AppTheme.textSecondary; // Using existing text color
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _formatPaymentMode(mode),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMode(String mode) {
    switch (mode.toUpperCase()) {
      case 'BANK_TRANSFER':
        return 'Bank';
      case 'UPI':
        return 'UPI';
      case 'CARD':
        return 'Card';
      case 'CASH':
        return 'Cash';
      default:
        return mode;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yy').format(date);
  }

  void _onEditItem(BuildContext context, Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Item - To be implemented')),
    );
  }

  void _onDeleteItem(BuildContext context, Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete Item - To be implemented')),
    );
  }

  void _onRecordPayment() {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        orderData: widget.orderData,
        onPaymentRecorded: (voucher) {
          _loadPayments();
          widget.onRefresh();
        },
      ),
    );
  }

  void _onViewReceipt(BuildContext context, ReceiptVoucher voucher) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View Receipt Details - ${voucher.voucherNumber}'),
      ),
    );
  }

  void _onPrintReceipt(BuildContext context, ReceiptVoucher voucher) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Print Receipt - ${voucher.voucherNumber}')),
    );
  }

  void _onRefundPayment(BuildContext context, ReceiptVoucher voucher) {
    showDialog(
      context: context,
      builder: (context) => IssueRefundDialog(
        receiptVoucher: voucher,
        onRefundIssued: () {
          _loadPayments();
          widget.onRefresh();
        },
      ),
    );
  }
}
