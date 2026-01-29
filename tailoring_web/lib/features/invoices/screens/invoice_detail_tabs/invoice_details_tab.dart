import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

class InvoiceDetailsTab extends StatelessWidget {
  final Map<String, dynamic> invoiceData;

  const InvoiceDetailsTab({super.key, required this.invoiceData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceInfo(),
          const SizedBox(height: AppTheme.space4),
          _buildCustomerBilling(),
          const SizedBox(height: AppTheme.space4),
          _buildItemsTable(),
          const SizedBox(height: AppTheme.space4),
          _buildFinancialSummary(),
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoice Information', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.space3),
          _infoRow('Invoice Number', invoiceData['invoice_number'] ?? 'N/A'),
          _infoRow('Invoice Date', invoiceData['invoice_date'] ?? 'N/A'),
          _infoRow('Order Number', invoiceData['order_number'] ?? 'N/A'),
          _infoRow('Status', invoiceData['status_display'] ?? 'N/A'),
          _infoRow('Payment Status', _getPaymentStatus()),
        ],
      ),
    );
  }

  Widget _buildCustomerBilling() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer & Billing', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.space3),
          _infoRow('Customer', invoiceData['customer_name'] ?? 'N/A'),
          if (invoiceData['customer_phone'] != null)
            _infoRow('Phone', invoiceData['customer_phone']),
          const SizedBox(height: AppTheme.space2),
          const Text(
            'Billing Address:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAddress(
              invoiceData['billing_address'],
              invoiceData['billing_city'],
              invoiceData['billing_state'],
              invoiceData['billing_pincode'],
            ),
            style: AppTheme.bodySmall,
          ),
          if (invoiceData['billing_gstin'] != null) ...[
            const SizedBox(height: 8),
            _infoRow('GSTIN', invoiceData['billing_gstin']),
          ],
          if (invoiceData['shipping_address'] != null) ...[
            const SizedBox(height: AppTheme.space2),
            const Divider(),
            const SizedBox(height: AppTheme.space2),
            const Text(
              'Shipping Address:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAddress(
                invoiceData['shipping_address'],
                invoiceData['shipping_city'],
                invoiceData['shipping_state'],
                invoiceData['shipping_pincode'],
              ),
              style: AppTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    final items = invoiceData['items'] as List? ?? [];

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
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: const Text('Invoice Items', style: AppTheme.heading3),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.backgroundGrey),
                children: [
                  _tableHeader('Item'),
                  _tableHeader('Qty'),
                  _tableHeader('Price'),
                  _tableHeader('Tax'),
                  _tableHeader('Total'),
                ],
              ),
              ...items.map(
                (item) => TableRow(
                  children: [
                    _tableCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['item_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (item['item_description'] != null)
                            Text(
                              item['item_description'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _tableCell(Text('${item['quantity'] ?? 0}')),
                    _tableCell(
                      Text('₹${(item['unit_price'] ?? 0).toStringAsFixed(2)}'),
                    ),
                    _tableCell(Text('${item['tax_percentage'] ?? 0}%')),
                    _tableCell(
                      Text(
                        '₹${(item['total_price'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final subtotal = (invoiceData['subtotal'] ?? 0).toDouble();
    final cgst = (invoiceData['cgst_amount'] ?? 0).toDouble();
    final sgst = (invoiceData['sgst_amount'] ?? 0).toDouble();
    final igst = (invoiceData['igst_amount'] ?? 0).toDouble();
    final total = (invoiceData['total_amount'] ?? 0).toDouble();
    final paid = (invoiceData['total_paid'] ?? 0).toDouble();
    final balance = (invoiceData['remaining_balance'] ?? 0).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          width: 400,
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Financial Summary', style: AppTheme.heading3),
              const SizedBox(height: AppTheme.space3),
              _summaryRow('Subtotal', subtotal),
              if (cgst > 0)
                _summaryRow(
                  'CGST (${invoiceData['tax_percentage'] ?? 0 / 2}%)',
                  cgst,
                ),
              if (sgst > 0)
                _summaryRow(
                  'SGST (${invoiceData['tax_percentage'] ?? 0 / 2}%)',
                  sgst,
                ),
              if (igst > 0)
                _summaryRow(
                  'IGST (${invoiceData['tax_percentage'] ?? 0}%)',
                  igst,
                ),
              const Divider(height: 24),
              _summaryRow('Grand Total', total, isBold: true, fontSize: 16),
              const Divider(height: 24),
              _summaryRow('Total Paid', paid, color: Colors.green.shade700),
              _summaryRow(
                'Balance Due',
                balance,
                color: balance > 0
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
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
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentStatus() {
    final balance = (invoiceData['remaining_balance'] ?? 0).toDouble();
    if (balance <= 0) return 'PAID ✓';
    if (balance < (invoiceData['total_amount'] ?? 0).toDouble())
      return 'PARTIALLY PAID';
    return 'UNPAID';
  }

  String _formatAddress(
    String? address,
    String? city,
    String? state,
    String? pincode,
  ) {
    final parts = <String>[];
    if (address != null) parts.add(address);

    final cityState = <String>[];
    if (city != null) cityState.add(city);
    if (state != null) cityState.add(state);
    if (cityState.isNotEmpty) parts.add(cityState.join(', '));

    if (pincode != null) parts.add(pincode);

    return parts.join('\n');
  }
}
