import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/purchase_bill.dart';
import '../../models/payment.dart';
import '../../providers/bill_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/amount_display.dart';
import '../../widgets/payment_card.dart';
import '../payments/payment_form_screen.dart';

class BillDetailScreen extends StatefulWidget {
  final int billId;

  const BillDetailScreen({Key? key, required this.billId}) : super(key: key);

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  bool _isLoading = true;
  PurchaseBill? _bill;
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadBillDetails();
  }

  Future<void> _loadBillDetails() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<BillProvider>();
      final bill = await provider.getBillById(widget.billId);
      final payments = await provider.getBillPayments(widget.billId);

      setState(() {
        _bill = bill;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading bill: $e')));
      }
    }
  }

  Future<void> _makePayment() async {
    if (_bill == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFormScreen(
          bill: _bill,
        ),
      ),
    );

    if (result == true) {
      _loadBillDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          if (_bill != null && _bill!.balanceAmountDouble > 0)
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: _makePayment,
              tooltip: 'Make Payment',
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bill == null
          ? const Center(child: Text('Bill not found'))
          : RefreshIndicator(
              onRefresh: _loadBillDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bill Info Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _bill!.billNumber,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                StatusBadge(status: _bill!.paymentStatus),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.business,
                              'Vendor',
                              _bill!.vendorName ?? 'Unknown Vendor',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Bill Date',
                              dateFormat.format(_bill!.billDate),
                            ),
                            if (_bill!.dueDate != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.event,
                                'Due Date',
                                dateFormat.format(_bill!.dueDate!),
                                isOverdue: _bill!.isOverdue,
                              ),
                            ],
                            if (_bill!.description != null &&
                                _bill!.description!.isNotEmpty) ...[
                              const Divider(height: 24),
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _bill!.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                            if (_bill!.notes != null &&
                                _bill!.notes!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _bill!.notes!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Amount Summary Card
                    Card(
                      elevation: 2,
                      color: const Color(0xFFFFF3E0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildAmountRow(
                              'Bill Amount',
                              _bill!.billAmountDouble,
                              isBold: true,
                            ),
                            if (_bill!.paidAmountDouble > 0) ...[
                              const SizedBox(height: 8),
                              _buildAmountRow(
                                'Paid',
                                _bill!.paidAmountDouble,
                                color: Colors.green[700],
                              ),
                            ],
                            if (_bill!.balanceAmountDouble > 0) ...[
                              const Divider(height: 20),
                              _buildAmountRow(
                                'Balance Due',
                                _bill!.balanceAmountDouble,
                                isBold: true,
                                fontSize: 18,
                                color: const Color(0xFFFF6F00),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        Text(
                          '${_payments.length} payment${_payments.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_payments.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.payment_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No payments yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          return PaymentCard(payment: _payments[index]);
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _bill != null && _bill!.balanceAmountDouble > 0
          ? FloatingActionButton.extended(
              onPressed: _makePayment,
              backgroundColor: const Color(0xFF1A237E),
              icon: const Icon(Icons.payment),
              label: const Text('Pay Now'),
            )
          : null,
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isOverdue = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isOverdue ? Colors.red : Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isOverdue ? Colors.red : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
        AmountDisplay(
          amount: amount,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: color,
        ),
      ],
    );
  }
}
