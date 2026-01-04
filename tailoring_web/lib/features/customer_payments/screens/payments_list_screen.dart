/// Daily Payments Screen
/// Location: lib/features/payments/screens/payments_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/features/customer_payments/providers/payment_provider.dart';
import 'package:tailoring_web/features/customer_payments/models/payment.dart';
import 'package:tailoring_web/features/customer_payments/widgets/add_payment_modal.dart';

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  Future<void> _loadPayments() async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    await provider.loadPayments();
  }

  void _showAddPaymentModal() {
    showDialog(
      context: context,
      builder: (context) => const AddPaymentModal(),
    ).then((created) {
      if (created == true) {
        _loadPayments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/payments',
      child: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Header
              _buildHeader(provider),

              // Payments Table
              Expanded(
                child: provider.payments.isEmpty
                    ? _buildEmptyState()
                    : _buildPaymentsTable(provider.payments),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(PaymentProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // Title
          const Text('Payments', style: AppTheme.heading1),
          const SizedBox(width: 16),

          // Summary chips
          _buildSummaryChip(
            '${provider.paymentCount} Payments',
            AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          _buildSummaryChip(
            '₹${provider.totalAmount.toStringAsFixed(2)}',
            AppTheme.success,
          ),

          const Spacer(),

          // Add Payment Button
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
    );
  }

  Widget _buildSummaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentsTable(List<Payment> payments) {
    return Container(
      margin: const EdgeInsets.all(24),
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
                SizedBox(width: 100, child: _headerText('Date')),
                Expanded(child: _headerText('Customer')),
                SizedBox(width: 140, child: _headerText('Order #')),
                SizedBox(width: 120, child: _headerText('Amount')),
                SizedBox(width: 140, child: _headerText('Method')),
                SizedBox(width: 140, child: _headerText('Bank')),
                const SizedBox(width: 40), // Actions
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return _buildPaymentRow(payments[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(text, style: AppTheme.bodySmallBold);
  }

  Widget _buildPaymentRow(Payment payment) {
    return InkWell(
      onTap: () {
        // Navigate to order detail
        Navigator.pushNamed(context, '/orders/${payment.orderId}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            // Date
            SizedBox(
              width: 100,
              child: Text(payment.formattedDate, style: AppTheme.bodyMedium),
            ),

            // Customer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.customerName,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (payment.customerPhone != null)
                    Text(
                      payment.customerPhone!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Order Number
            SizedBox(
              width: 140,
              child: Text(
                payment.orderNumber,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),

            // Amount
            SizedBox(
              width: 120,
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
              width: 140,
              child: Row(
                children: [
                  Text(
                    payment.methodIcon,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    payment.paymentMethodDisplay,
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Bank
            SizedBox(
              width: 140,
              child: Text(
                payment.depositedToBank && payment.depositBankName != null
                    ? payment.depositBankName!
                    : payment.bankName ?? '-',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),

            // Actions
            SizedBox(
              width: 40,
              child: PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Order')),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Payment'),
                  ),
                  if (payment.paymentMethod == 'CASH' &&
                      !payment.depositedToBank)
                    const PopupMenuItem(
                      value: 'deposit',
                      child: Text('Mark Deposited'),
                    ),
                  const PopupMenuItem(
                    value: 'void',
                    child: Text('Void Payment'),
                  ),
                ],
                onSelected: (value) => _handleAction(value as String, payment),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, Payment payment) {
    switch (action) {
      case 'view':
        Navigator.pushNamed(context, '/orders/${payment.orderId}');
        break;
      case 'edit':
        // TODO: Show edit modal
        break;
      case 'deposit':
        // TODO: Show deposit modal
        break;
      case 'void':
        _confirmVoid(payment);
        break;
    }
  }

  void _confirmVoid(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Payment'),
        content: Text(
          'Are you sure you want to void payment ${payment.paymentNumber}?',
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
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment voided successfully')),
                );
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No payments yet',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first payment to get started',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPaymentModal,
            icon: const Icon(Icons.add),
            label: const Text('Add Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
