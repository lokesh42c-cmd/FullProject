import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../../payments_received/widgets/dialogs/record_payment_dialog.dart';

class InvoicePaymentsTab extends StatefulWidget {
  final int invoiceId;
  final Map<String, dynamic> invoiceData;
  final VoidCallback onPaymentRecorded;

  const InvoicePaymentsTab({
    super.key,
    required this.invoiceId,
    required this.invoiceData,
    required this.onPaymentRecorded,
  });

  @override
  State<InvoicePaymentsTab> createState() => _InvoicePaymentsTabState();
}

class _InvoicePaymentsTabState extends State<InvoicePaymentsTab> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _advances = [];
  List<Map<String, dynamic>> _invoicePayments = [];
  bool _isLoading = true;

  double _totalAdvances = 0;
  double _advancesApplied = 0;
  double _advancesRemaining = 0;
  double _totalInvoicePayments = 0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final orderId = widget.invoiceData['order'];

      // Fetch advances (receipt vouchers)
      final advancesResponse = await _apiClient.get(
        'financials/receipts/',
        params: {'order': orderId},
      );
      final advancesList = (advancesResponse.data['results'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      // Fetch invoice payments
      final invoicePaymentsResponse = await _apiClient.get(
        'financials/payments/',
        params: {'invoice': widget.invoiceId},
      );
      final invoicePaymentsList =
          (invoicePaymentsResponse.data['results'] as List? ?? [])
              .cast<Map<String, dynamic>>();

      // Calculate totals
      double totalAdv = 0;
      double appliedAdv = 0;
      for (var adv in advancesList) {
        final amount = (adv['amount'] ?? 0).toDouble();
        totalAdv += amount;
        // Check if applied to this invoice
        if (adv['invoice_id'] == widget.invoiceId) {
          appliedAdv += amount;
        }
      }

      double totalInvPay = 0;
      for (var pay in invoicePaymentsList) {
        totalInvPay += (pay['amount'] ?? 0).toDouble();
      }

      setState(() {
        _advances = advancesList;
        _invoicePayments = invoicePaymentsList;
        _totalAdvances = totalAdv;
        _advancesApplied = appliedAdv;
        _advancesRemaining = totalAdv - appliedAdv;
        _totalInvoicePayments = totalInvPay;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payments: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _recordPayment() async {
    final balanceDue = (widget.invoiceData['remaining_balance'] ?? 0)
        .toDouble();

    if (balanceDue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice is already fully paid'),
          backgroundColor: AppTheme.info,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RecordPaymentDialog(
        orderId: widget.invoiceData['order'],
        invoiceId: widget.invoiceId,
        maxAmount: balanceDue,
        isInvoicePayment: true,
      ),
    );

    if (result == true) {
      _loadPayments();
      widget.onPaymentRecorded();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment History', style: AppTheme.heading2),
              ElevatedButton.icon(
                onPressed: _recordPayment,
                icon: const Icon(Icons.add),
                label: const Text('Record Payment'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),

          if (_advances.isNotEmpty) ...[
            _buildAdvancesSection(),
            const SizedBox(height: AppTheme.space4),
          ],

          _buildInvoicePaymentsSection(),
          const SizedBox(height: AppTheme.space4),

          _buildPaymentSummary(),
        ],
      ),
    );
  }

  Widget _buildAdvancesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Advances (Before Invoice)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
              5: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.backgroundGrey),
                children: [
                  _tableHeader('Type'),
                  _tableHeader('Date'),
                  _tableHeader('Reference'),
                  _tableHeader('Method'),
                  _tableHeader('Amount'),
                  _tableHeader('Status'),
                ],
              ),
              ..._advances.map(
                (adv) => TableRow(
                  children: [
                    _tableCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Advance',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    _tableCell(
                      Text(
                        adv['payment_date'] ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    _tableCell(
                      Text(
                        adv['receipt_number'] ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    _tableCell(
                      Text(
                        adv['payment_method_display'] ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    _tableCell(
                      Text(
                        '₹${(adv['amount'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _tableCell(
                      Text(
                        adv['invoice_id'] == widget.invoiceId
                            ? 'Applied'
                            : 'Unapplied',
                        style: TextStyle(
                          fontSize: 11,
                          color: adv['invoice_id'] == widget.invoiceId
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.space3),
            decoration: BoxDecoration(color: Colors.blue.shade50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Advances: ₹${_totalAdvances.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 24),
                Text(
                  'Applied: ₹${_advancesApplied.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'Remaining: ₹${_advancesRemaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicePaymentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Invoice Payments (After Invoice Created)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          if (_invoicePayments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space5),
              child: Center(
                child: Text(
                  'No invoice payments yet',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundGrey,
                  ),
                  children: [
                    _tableHeader('Type'),
                    _tableHeader('Date'),
                    _tableHeader('Reference'),
                    _tableHeader('Method'),
                    _tableHeader('Amount'),
                  ],
                ),
                ..._invoicePayments.map(
                  (pay) => TableRow(
                    children: [
                      _tableCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Invoice Pay',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      _tableCell(
                        Text(
                          pay['payment_date'] ?? 'N/A',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      _tableCell(
                        Text(
                          pay['payment_number'] ?? 'N/A',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      _tableCell(
                        Text(
                          pay['payment_method_display'] ?? 'N/A',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      _tableCell(
                        Text(
                          '₹${(pay['amount'] ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (_invoicePayments.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.space3),
              decoration: BoxDecoration(color: Colors.green.shade50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total Invoice Payments: ₹${_totalInvoicePayments.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final invoiceTotal = (widget.invoiceData['total_amount'] ?? 0).toDouble();
    final totalPaid = (widget.invoiceData['total_paid'] ?? 0).toDouble();
    final balanceDue = (widget.invoiceData['remaining_balance'] ?? 0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              const Text(
                'Payment Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          _summaryRow('Invoice Total', invoiceTotal),
          _summaryRow(
            'Advances Applied',
            _advancesApplied,
            color: Colors.blue.shade700,
          ),
          _summaryRow(
            'Invoice Payments',
            _totalInvoicePayments,
            color: Colors.green.shade700,
          ),
          const Divider(height: 24),
          _summaryRow('TOTAL PAID', totalPaid, isBold: true, fontSize: 16),
          _summaryRow(
            'BALANCE DUE',
            balanceDue,
            isBold: true,
            fontSize: 16,
            color: balanceDue > 0
                ? Colors.orange.shade700
                : Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: AppTheme.tableHeader),
    );
  }

  Widget _tableCell(Widget child) {
    return Padding(padding: const EdgeInsets.all(12), child: child);
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
