/// All Payments Received Screen
/// Location: lib/features/financials/screens/all_payments_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/features/financials/providers/payment_transaction_provider.dart';
import 'package:tailoring_web/features/financials/models/payment_transaction.dart';

class AllPaymentsScreen extends StatefulWidget {
  const AllPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AllPaymentsScreen> createState() => _AllPaymentsScreenState();
}

class _AllPaymentsScreenState extends State<AllPaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final provider = Provider.of<PaymentTransactionProvider>(
      context,
      listen: false,
    );
    await provider.loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/payments-received',
      child: Consumer<PaymentTransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 1. Unified Header with Search and Actions
              _buildHeader(provider),

              // 2. Compact Summary Bar (Moved up and resized)
              if (provider.summary != null)
                _buildCompactSummary(provider.summary!),

              // 3. Transactions Table
              Expanded(
                child: provider.transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsTable(provider.transactions),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(PaymentTransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Text('Payments Received', style: AppTheme.heading2),
          const SizedBox(width: 24),

          // Search bar moved next to Title
          SizedBox(
            width: 320,
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer, transaction...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (value) => provider.setSearchQuery(value),
            ),
          ),
          const SizedBox(width: 12),

          // Cash in Hand Filter moved to header
          FilterChip(
            label: const Text(
              'Cash in Hand Only',
              style: TextStyle(fontSize: 12),
            ),
            selected: provider.showCashInHandOnly,
            onSelected: provider.setCashInHandFilter,
            visualDensity: VisualDensity.compact,
          ),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 20),
            tooltip: 'Export',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.print, size: 20),
            tooltip: 'Print',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummary(PaymentTransactionSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppTheme.backgroundGrey.withOpacity(0.1),
      child: Row(
        children: [
          _buildCompactSummaryItem(
            'Total Received',
            '₹${summary.totalReceived}',
            AppTheme.success,
            Icons.trending_up,
          ),
          _buildDivider(),
          _buildCompactSummaryItem(
            'Net Received',
            '₹${summary.netReceived}',
            AppTheme.primaryBlue,
            Icons.account_balance_wallet,
          ),
          _buildDivider(),
          _buildCompactSummaryItem(
            'Cash in Hand',
            '₹${summary.cashInHand}',
            AppTheme.warning,
            Icons.money,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 16,
      width: 1,
      color: AppTheme.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildTransactionsTable(List<PaymentTransaction> transactions) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 90, child: _headerText('Date')),
                SizedBox(width: 140, child: _headerText('Transaction #')),
                Expanded(flex: 3, child: _headerText('Customer')),
                Expanded(flex: 2, child: _headerText('Order #')),
                Expanded(flex: 2, child: _headerText('Invoice #')),
                SizedBox(width: 100, child: _headerText('Amount')),
                SizedBox(width: 100, child: _headerText('Method')),
                SizedBox(width: 85, child: _headerText('Deposit')),
                const SizedBox(width: 40),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) =>
                  _buildTransactionRow(transactions[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) => Text(text, style: AppTheme.bodySmallBold);

  Widget _buildTransactionRow(PaymentTransaction txn) {
    const TextStyle rowStyle = TextStyle(
      color: Colors.black,
      fontSize: 13,
      fontWeight: FontWeight.w400,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ), // Reduced padding for more rows
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(txn.formattedDate, style: rowStyle)),
          SizedBox(
            width: 140,
            child: Text(
              txn.transactionNumber,
              style: rowStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              txn.customerName,
              style: rowStyle.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(txn.orderNumber ?? '-', style: rowStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(txn.invoiceNumber ?? '-', style: rowStyle),
          ),
          SizedBox(
            width: 100,
            child: Text(
              txn.formattedAmount,
              style: rowStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(txn.paymentModeDisplay, style: rowStyle),
          ),
          SizedBox(
            width: 85,
            child: Text(
              txn.paymentMode == 'CASH'
                  ? (txn.depositedToBank ? 'Deposited' : 'In Hand')
                  : 'N/A',
              style: rowStyle.copyWith(
                fontSize: 11,
                color: txn.depositedToBank
                    ? AppTheme.success
                    : AppTheme.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) => _handleAction(val, txn),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'deposit',
                  child: Text('Update Deposit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, PaymentTransaction txn) {
    if (action == 'deposit') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updating deposit for ${txn.transactionNumber}'),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No transactions found', style: AppTheme.bodyLarge),
    );
  }
}
