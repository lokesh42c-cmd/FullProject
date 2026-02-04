// lib/features/invoices/widgets/invoice_payment_history_widget.dart

import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

/// Payment History Widget for Invoice Detail Screen
///
/// Shows 4 types of payments:
/// - Advances (ReceiptVoucher) - Green - $ Adv
/// - Payments (InvoicePayment) - Blue - ≡ Pay
/// - Advance Refunds (RefundVoucher) - Red - ↩ ARf
/// - Payment Refunds (PaymentRefund) - Orange - ↺ PRf
///
/// Features:
/// - Collapsible section (collapsed by default)
/// - Legend dialog (ℹ️ icon)
/// - Hover tooltips on badges
/// - Full-width responsive table
/// - Action buttons per payment type
class InvoicePaymentHistoryWidget extends StatefulWidget {
  final int invoiceId;
  final List<dynamic> allPayments; // Mixed list of all payment types
  final VoidCallback? onRefresh;
  final Function(dynamic)? onRefundPayment;
  final Function(dynamic)? onDeletePayment;
  final Function(int)? onNavigateToOrder;

  const InvoicePaymentHistoryWidget({
    super.key,
    required this.invoiceId,
    required this.allPayments,
    this.onRefresh,
    this.onRefundPayment,
    this.onDeletePayment,
    this.onNavigateToOrder,
  });

  @override
  State<InvoicePaymentHistoryWidget> createState() =>
      _InvoicePaymentHistoryWidgetState();
}

class _InvoicePaymentHistoryWidgetState
    extends State<InvoicePaymentHistoryWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final totalPaid = _calculateTotalPaid();
    final paymentCount = widget.allPayments.length;

    return Container(
      margin: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(paymentCount, totalPaid),

          // Divider
          if (_isExpanded) const Divider(height: 1),

          // Payment table (when expanded)
          if (_isExpanded) _buildPaymentTable(),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, double total) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGrey,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusSmall),
            topRight: Radius.circular(AppTheme.radiusSmall),
            bottomLeft: _isExpanded
                ? Radius.zero
                : Radius.circular(AppTheme.radiusSmall),
            bottomRight: _isExpanded
                ? Radius.zero
                : Radius.circular(AppTheme.radiusSmall),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.payment, size: 22, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Text(
              'Payment History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 12),
            // Payment count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count payment${count != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            // Total paid amount
            Text(
              'Net: ₹${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: total >= 0 ? AppTheme.success : AppTheme.danger,
              ),
            ),
            const SizedBox(width: 16),
            // Legend button
            Tooltip(
              message: 'Show legend',
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: _showLegendDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            // Expand/collapse icon
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTable() {
    if (widget.allPayments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.payment_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No payments recorded yet',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 100,
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: AppTheme.borderLight),
            ),
            columnWidths: const {
              0: FixedColumnWidth(50), // #
              1: FixedColumnWidth(120), // Type
              2: FlexColumnWidth(2), // Date
              3: FlexColumnWidth(2.5), // Number
              4: FlexColumnWidth(1.5), // Mode
              5: FlexColumnWidth(1.5), // Amount
              6: FlexColumnWidth(1.5), // By
              7: FixedColumnWidth(120), // Actions
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: [
                  _buildTableHeader('#'),
                  _buildTableHeader('Type'),
                  _buildTableHeader('Date'),
                  _buildTableHeader('Number'),
                  _buildTableHeader('Mode'),
                  _buildTableHeader('Amount'),
                  _buildTableHeader('By'),
                  _buildTableHeader('Actions'),
                ],
              ),
              // Data rows
              ...widget.allPayments.asMap().entries.map((entry) {
                final index = entry.key;
                final payment = entry.value;
                return _buildPaymentRow(index + 1, payment);
              }),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildPaymentRow(int index, dynamic payment) {
    final paymentType = _getPaymentType(payment);
    final color = _getPaymentColor(paymentType);
    final icon = _getPaymentIcon(paymentType);
    final badge = _getPaymentBadge(paymentType);
    final tooltip = _getPaymentTooltip(paymentType);

    return TableRow(
      children: [
        _buildTableCell(
          Text(
            '$index',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ),
        _buildTableCell(
          Tooltip(
            message: tooltip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildTableCell(
          Text(
            _formatDate(payment['date'] ?? ''),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        _buildTableCell(
          Text(
            payment['number'] ?? '-',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        _buildTableCell(
          Row(
            children: [
              _getPaymentModeIcon(payment['mode'] ?? ''),
              const SizedBox(width: 6),
              Text(
                payment['mode'] ?? '-',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        _buildTableCell(
          Text(
            '₹${(payment['amount'] ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: (payment['amount'] ?? 0.0) >= 0
                  ? AppTheme.success
                  : AppTheme.danger,
            ),
          ),
        ),
        _buildTableCell(
          Text(
            payment['created_by'] ?? 'Admin',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        _buildTableCell(_buildActionButtons(paymentType, payment)),
      ],
    );
  }

  Widget _buildActionButtons(String paymentType, dynamic payment) {
    switch (paymentType) {
      case 'ADVANCE':
        // Advances from order - Read-only, link to order
        return ElevatedButton.icon(
          icon: const Icon(Icons.shopping_bag, size: 14),
          label: const Text('Order', style: TextStyle(fontSize: 12)),
          onPressed: () {
            final orderId = payment['order_id'];
            if (orderId != null && widget.onNavigateToOrder != null) {
              widget.onNavigateToOrder!(orderId);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: AppTheme.textDark,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

      case 'PAYMENT':
        // Invoice payments - Can refund and delete
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Refund payment',
              child: IconButton(
                icon: Icon(Icons.refresh, size: 18, color: AppTheme.warning),
                onPressed: () {
                  if (widget.onRefundPayment != null) {
                    widget.onRefundPayment!(payment);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Delete payment',
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.danger,
                ),
                onPressed: () => _confirmDelete(payment),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        );

      case 'ADVANCE_REFUND':
        // Advance refunds from order - Read-only, link to order
        return ElevatedButton.icon(
          icon: const Icon(Icons.shopping_bag, size: 14),
          label: const Text('Order', style: TextStyle(fontSize: 12)),
          onPressed: () {
            final orderId = payment['order_id'];
            if (orderId != null && widget.onNavigateToOrder != null) {
              widget.onNavigateToOrder!(orderId);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: AppTheme.textDark,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

      case 'PAYMENT_REFUND':
        // Payment refunds - View details only
        return IconButton(
          icon: Icon(Icons.info_outline, size: 18, color: AppTheme.info),
          onPressed: () => _showRefundDetails(payment),
          tooltip: 'View details',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(padding: const EdgeInsets.all(14), child: child);
  }

  // ==================== HELPER METHODS ====================

  String _getPaymentType(dynamic payment) {
    if (payment['type'] != null) return payment['type'];

    // Fallback: determine by checking fields
    if (payment['voucher_number'] != null) return 'ADVANCE';
    if (payment['payment_number'] != null && payment['refund_number'] == null) {
      return 'PAYMENT';
    }
    if (payment['receipt_voucher'] != null) return 'ADVANCE_REFUND';
    if (payment['refund_number'] != null) return 'PAYMENT_REFUND';

    return 'UNKNOWN';
  }

  Color _getPaymentColor(String type) {
    switch (type) {
      case 'ADVANCE':
        return AppTheme.success; // Green
      case 'PAYMENT':
        return AppTheme.primaryBlue; // Blue
      case 'ADVANCE_REFUND':
        return AppTheme.danger; // Red
      case 'PAYMENT_REFUND':
        return AppTheme.warning; // Orange
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getPaymentIcon(String type) {
    switch (type) {
      case 'ADVANCE':
        return Icons.attach_money; // $
      case 'PAYMENT':
        return Icons.payment; // ≡
      case 'ADVANCE_REFUND':
        return Icons.undo; // ↩
      case 'PAYMENT_REFUND':
        return Icons.refresh; // ↺
      default:
        return Icons.help_outline;
    }
  }

  String _getPaymentBadge(String type) {
    switch (type) {
      case 'ADVANCE':
        return 'Adv';
      case 'PAYMENT':
        return 'Pay';
      case 'ADVANCE_REFUND':
        return 'ARf';
      case 'PAYMENT_REFUND':
        return 'PRf';
      default:
        return '?';
    }
  }

  String _getPaymentTooltip(String type) {
    switch (type) {
      case 'ADVANCE':
        return 'Advance Payment (before invoice, with GST)';
      case 'PAYMENT':
        return 'Invoice Payment (against invoice)';
      case 'ADVANCE_REFUND':
        return 'Advance Refund (GST reversed)';
      case 'PAYMENT_REFUND':
        return 'Payment Refund (no GST)';
      default:
        return 'Unknown payment type';
    }
  }

  Icon _getPaymentModeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'CASH':
        return Icon(Icons.money, size: 16, color: AppTheme.success);
      case 'UPI':
        return Icon(Icons.qr_code, size: 16, color: AppTheme.primaryBlue);
      case 'CARD':
        return Icon(Icons.credit_card, size: 16, color: Colors.purple);
      case 'BANK_TRANSFER':
      case 'BANK':
        return Icon(Icons.account_balance, size: 16, color: AppTheme.warning);
      case 'CHEQUE':
        return Icon(Icons.receipt_long, size: 16, color: Colors.brown);
      default:
        return Icon(Icons.payment, size: 16, color: AppTheme.textMuted);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')} ${_getMonthAbbr(date.month)} ${date.year.toString().substring(2)}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthAbbr(int month) {
    const months = [
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
    return months[month - 1];
  }

  double _calculateTotalPaid() {
    double total = 0.0;
    for (var payment in widget.allPayments) {
      total += (payment['amount'] ?? 0.0);
    }
    return total;
  }

  // ==================== DIALOG & NAVIGATION ====================

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            const Text('Payment Types Legend'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                Icons.attach_money,
                'Adv',
                'Advance Payment',
                'Money received before invoice (with GST)',
                AppTheme.success,
              ),
              const SizedBox(height: 16),
              _buildLegendItem(
                Icons.payment,
                'Pay',
                'Invoice Payment',
                'Payment received against invoice',
                AppTheme.primaryBlue,
              ),
              const SizedBox(height: 16),
              _buildLegendItem(
                Icons.undo,
                'ARf',
                'Advance Refund',
                'Refund for advance payment (GST reversed)',
                AppTheme.danger,
              ),
              const SizedBox(height: 16),
              _buildLegendItem(
                Icons.refresh,
                'PRf',
                'Payment Refund',
                'Refund for invoice payment (no GST)',
                AppTheme.warning,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    IconData icon,
    String badge,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(dynamic payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text(
          'Are you sure you want to delete this payment of ₹${(payment['amount'] ?? 0.0).toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onDeletePayment != null) {
                widget.onDeletePayment!(payment);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRefundDetails(dynamic payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Refund Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Refund Number:', payment['number'] ?? '-'),
              _buildDetailRow(
                'Refund Date:',
                _formatDate(payment['date'] ?? ''),
              ),
              _buildDetailRow(
                'Amount:',
                '₹${(payment['amount'] ?? 0.0).toStringAsFixed(2)}',
              ),
              _buildDetailRow('Mode:', payment['mode'] ?? '-'),
              _buildDetailRow('Reason:', payment['reason'] ?? '-'),
              if (payment['notes'] != null && payment['notes'].isNotEmpty)
                _buildDetailRow('Notes:', payment['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
