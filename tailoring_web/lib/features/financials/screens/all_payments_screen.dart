import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import '../providers/payment_transaction_provider.dart';
import '../models/payment_transaction.dart';
import '../widgets/update_deposit_dialog.dart';

class AllPaymentsScreen extends StatefulWidget {
  const AllPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AllPaymentsScreen> createState() => _AllPaymentsScreenState();
}

class _AllPaymentsScreenState extends State<AllPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentTransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/payments-received',
      child: Consumer<PaymentTransactionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildHeader(provider),
              if (provider.summary != null) _buildSummaryBar(provider.summary!),
              Expanded(
                child: provider.isLoading && provider.transactions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTable(provider.transactions),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(PaymentTransactionProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text('Payments Received', style: AppTheme.heading2),
          const SizedBox(width: 20),
          SizedBox(
            width: 300,
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (val) => p.setSearchQuery(val),
            ),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('Cash in Hand'),
            selected: p.showCashInHandOnly,
            onSelected: (val) => p.setCashInHandFilter(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(PaymentTransactionSummary s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppTheme.backgroundGrey.withOpacity(0.2),
      child: Row(
        children: [
          Text(
            'Total: ₹${s.totalReceived}',
            style: const TextStyle(
              color: AppTheme.success,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
          Text(
            'Net: ₹${s.netReceived}',
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
          Text(
            'Cash In Hand: ₹${s.cashInHand}',
            style: const TextStyle(
              color: AppTheme.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<PaymentTransaction> txns) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.backgroundGrey.withOpacity(0.5),
            child: Row(
              children: [
                _h('Date', 90),
                _h('Transaction #', 140),
                Expanded(flex: 3, child: _h('Customer', 0)),
                Expanded(flex: 2, child: _h('Order #', 0)),
                Expanded(flex: 2, child: _h('Invoice #', 0)),
                _h('Amount', 100),
                _h('Deposit', 85),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: txns.length,
              itemBuilder: (ctx, i) => _buildRow(txns[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _h(String t, double w) => w > 0
      ? SizedBox(
          width: w,
          child: Text(t, style: AppTheme.bodySmallBold),
        )
      : Text(t, style: AppTheme.bodySmallBold);

  Widget _buildRow(PaymentTransaction txn) {
    const style = TextStyle(color: Colors.black, fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(txn.formattedDate, style: style)),
          SizedBox(
            width: 140,
            child: Text(
              txn.transactionNumber,
              style: style.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              txn.customerName,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 2, child: Text(txn.orderNumber ?? '-', style: style)),
          Expanded(
            flex: 2,
            child: Text(txn.invoiceNumber ?? '-', style: style),
          ),
          SizedBox(
            width: 100,
            child: Text(
              txn.formattedAmount,
              style: style.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 85,
            child: Text(
              txn.paymentMode == 'CASH'
                  ? (txn.depositedToBank ? 'Deposited' : 'In Hand')
                  : 'N/A',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: txn.depositedToBank
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: (txn.paymentMode == 'CASH' && !txn.depositedToBank)
                ? PopupMenuButton(
                    onSelected: (v) => _showUpdateDepositDialog(txn),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'd',
                        child: Text('Update Deposit'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showUpdateDepositDialog(PaymentTransaction txn) {
    showDialog(
      context: context,
      builder: (ctx) => UpdateDepositDialog(
        transaction: txn,
        onConfirm: () async {
          final p = Provider.of<PaymentTransactionProvider>(
            context,
            listen: false,
          );
          final ok = await p.updateDepositStatus(txn.id, txn.transactionType);
          if (mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ok ? 'Deposit updated' : 'Update failed')),
            );
          }
        },
      ),
    );
  }
}
