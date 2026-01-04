/// Order Payments Tab
/// Location: lib/features/customer_payments/widgets/order_payments_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../providers/payment_provider.dart';
import 'package:tailoring_web/features/customer_payments/models/payment.dart';
import 'payment_summary_card.dart';
import 'add_payment_modal.dart';

class OrderPaymentsTab extends StatefulWidget {
  final int orderId;
  final double orderTotal;

  const OrderPaymentsTab({
    Key? key,
    required this.orderId,
    required this.orderTotal,
  }) : super(key: key);

  @override
  State<OrderPaymentsTab> createState() => _OrderPaymentsTabState();
}

class _OrderPaymentsTabState extends State<OrderPaymentsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    provider.setOrderFilter(widget.orderId);

    await provider.loadSummary(orderId: widget.orderId);
  }

  void _showAddPaymentModal() {
    showDialog(
      context: context,
      builder: (context) => AddPaymentModal(orderId: widget.orderId),
    ).then((created) {
      if (created == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              if (provider.summary != null)
                PaymentSummaryCard(summary: provider.summary!),
              const SizedBox(height: 24),

              // Payment History Header
              Row(
                children: [
                  const Text('Payment History', style: AppTheme.heading3),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showAddPaymentModal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payments List
              if (provider.payments.isEmpty)
                _buildEmptyState()
              else
                _buildPaymentsList(provider.payments),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _headerText('Date')),
                Expanded(flex: 3, child: _headerText('Payment #')),
                Expanded(flex: 2, child: _headerText('Amount')),
                Expanded(flex: 2, child: _headerText('Method')),
                Expanded(flex: 4, child: _headerText('Bank/Reference')),
                const SizedBox(width: 40), // Keep action menu fixed
              ],
            ),
          ),

          // Payments
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return _buildPaymentRow(payments[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow_headerText(String text) {
    return Text(text, style: AppTheme.bodySmallBold);
  }

  Widget _buildPaymentRow(Payment payment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        color: payment.isRefund
            ? AppTheme.error.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 80,
            child: Text(payment.formattedDate, style: AppTheme.bodyMedium),
          ),

          // Payment Number
          SizedBox(
            width: 120,
            child: Text(
              payment.paymentNumber,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          // Amount
          SizedBox(
            width: 100,
            child: Text(
              payment.formattedAmount,
              style: AppTheme.bodyMedium.copyWith(
                color: payment.isRefund ? AppTheme.error : AppTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Method
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Text(payment.methodIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(payment.paymentMethodDisplay, style: AppTheme.bodyMedium),
              ],
            ),
          ),

          // Bank/Reference
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (payment.bankName != null)
                  Text(payment.bankName!, style: AppTheme.bodySmall),
                if (payment.referenceNumber != null)
                  Text(
                    payment.referenceNumber!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                if (payment.notes != null)
                  Text(
                    payment.notes!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Actions
          SizedBox(
            width: 40,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (payment.paymentMethod == 'CASH' && !payment.depositedToBank)
                  const PopupMenuItem(
                    value: 'deposit',
                    child: Text('Mark Deposited'),
                  ),
                const PopupMenuItem(value: 'void', child: Text('Void')),
              ],
              onSelected: (value) => _handleAction(value as String, payment),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, Payment payment) {
    switch (action) {
      case 'edit':
        // TODO: Edit modal
        break;
      case 'deposit':
        _showDepositModal(payment);
        break;
      case 'void':
        _confirmVoid(payment);
        break;
    }
  }

  void _showDepositModal(Payment payment) {
    final dateController = TextEditingController();
    final bankController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Cash as Deposited'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankController,
              decoration: const InputDecoration(labelText: 'Bank Name *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Deposit Date *',
                hintText: 'YYYY-MM-DD',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (bankController.text.isEmpty || dateController.text.isEmpty) {
                return;
              }
              Navigator.pop(context);
              final provider = Provider.of<PaymentProvider>(
                context,
                listen: false,
              );
              final success = await provider.markDeposited(
                id: payment.id,
                depositDate: DateTime.parse(dateController.text),
                depositBankName: bankController.text,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as deposited')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmVoid(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Payment'),
        content: Text(
          'Void payment ${payment.paymentNumber} for ${payment.formattedAmount}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<PaymentProvider>(
                context,
                listen: false,
              );
              final success = await provider.voidPayment(
                payment.id,
                'Voided from UI',
              );
              if (success && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Payment voided')));
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Void'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.payment, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No payments recorded',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Add the first payment for this order',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
