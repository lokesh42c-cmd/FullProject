import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase_bill.dart';
import 'status_badge.dart';
import 'amount_display.dart';

class BillCard extends StatelessWidget {
  final PurchaseBill bill;
  final VoidCallback? onTap;
  final VoidCallback? onPay;

  const BillCard({Key? key, required this.bill, this.onTap, this.onPay}) : super(key: key);

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
                          bill.billNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bill.vendorName ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: bill.paymentStatus),
                ],
              ),
              const Divider(height: 24),
              if (bill.description != null)
                Text(
                  bill.description!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Bill: ${dateFormat.format(bill.billDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (bill.dueDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event,
                      size: 14,
                      color: bill.isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${dateFormat.format(bill.dueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: bill.isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: bill.isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bill Amount',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        AmountDisplay(
                          amount: bill.billAmountDouble,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    if (bill.paidAmountDouble > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paid', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          AmountDisplay(
                            amount: bill.paidAmountDouble,
                            fontSize: 13,
                            color: Colors.green[700],
                          ),
                        ],
                      ),
                    ],
                    if (bill.balanceAmountDouble > 0) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Balance Due',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6F00),
                            ),
                          ),
                          AmountDisplay(
                            amount: bill.balanceAmountDouble,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6F00),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (bill.balanceAmountDouble > 0 && onPay != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
