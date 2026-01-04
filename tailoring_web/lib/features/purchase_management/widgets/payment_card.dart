import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import 'payment_method_chip.dart';
import 'amount_display.dart';

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;

  const PaymentCard({Key? key, required this.payment, this.onTap})
    : super(key: key);

  // Helper method to provide clean labels for the UI
  String _getPaymentTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'BILL':
        return 'Bill Payment';
      case 'EXPENSE':
        return 'Expense Payment';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.vendorName ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Updated this line to use the helper method
                          _getPaymentTypeLabel(payment.paymentType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AmountDisplay(
                    amount: payment.amountDouble,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700]!,
                  ),
                ],
              ),
              const Divider(height: 24),
              if (payment.isBillPayment && payment.purchaseBillNumber != null)
                _buildDetailRow(
                  icon: Icons.receipt_long,
                  label: 'Bill',
                  value: payment.purchaseBillNumber!,
                ),
              if (payment.isExpensePayment &&
                  payment.expenseDescription != null)
                _buildDetailRow(
                  icon: Icons.article,
                  label: 'Expense',
                  value: payment.expenseDescription!,
                  maxLines: 2,
                ),
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: dateFormat.format(payment.paymentDate),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Method:',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  PaymentMethodChip(method: payment.paymentMethod),
                ],
              ),
              if (payment.referenceNumber != null &&
                  payment.referenceNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.tag,
                  label: 'Reference',
                  value: payment.referenceNumber!,
                ),
              ],
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
