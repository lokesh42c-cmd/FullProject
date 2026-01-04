import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/providers/payment_provider.dart';
import 'package:tailoring_web/features/purchase_management/screens/payments/payment_form_screen.dart';
import 'package:intl/intl.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd-MMM-yy');
  final _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchPayments(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    return MainLayout(
      currentRoute: '/purchase/payments',
      child: Column(
        children: [
          // Page header
          Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Text('Payments', style: AppTheme.heading2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                    vertical: AppTheme.space2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    'Today: ${_currencyFormat.format(provider.getTodayTotal())}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                ElevatedButton.icon(
                  onPressed: () => _handleAddPayment(provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Record Payment'),
                ),
              ],
            ),
          ),

          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: AppTheme.inputHeight,
                    child: TextField(
                      controller: _searchController,
                      style: AppTheme.bodySmall,
                      decoration: const InputDecoration(
                        hintText: 'Search by payment number or reference...',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                      onChanged: (value) => provider.setSearchQuery(value),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Container(
                  height: AppTheme.inputHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.filterType,
                      style: AppTheme.bodySmall,
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Types'),
                        ),
                        DropdownMenuItem(
                          value: 'PURCHASE_BILL',
                          child: Text('Bill Payments'),
                        ),
                        DropdownMenuItem(
                          value: 'EXPENSE',
                          child: Text('Expense Payments'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setFilterType(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Container(
                  height: AppTheme.inputHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.filterMethod,
                      style: AppTheme.bodySmall,
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Methods'),
                        ),
                        DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem(
                          value: 'BANK_TRANSFER',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(value: 'CARD', child: Text('Card')),
                        DropdownMenuItem(
                          value: 'CHEQUE',
                          child: Text('Cheque'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setFilterMethod(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                ? Center(child: Text(provider.errorMessage!))
                : provider.payments.isEmpty
                ? const Center(child: Text('No payments found'))
                : _buildPaymentTable(provider),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddPayment(PaymentProvider provider) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => const PaymentFormScreen(),
    );

    if (success == true && mounted) {
      provider.refresh();
    }
  }

  Widget _buildPaymentTable(PaymentProvider provider) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundGrey,
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('PAYMENT #', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('DATE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('TYPE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('REFERENCE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'AMOUNT',
                      style: AppTheme.tableHeader,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'METHOD',
                      style: AppTheme.tableHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Table Body
            ...provider.payments.map((payment) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    // Show payment detail if needed
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            payment.paymentNumber,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dateFormat.format(payment.paymentDate),
                                style: AppTheme.bodySmall,
                              ),
                              Text(
                                _timeFormat.format(payment.paymentDate),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    payment.paymentType == 'PURCHASE_BILL'
                                        ? Icons.receipt_long
                                        : Icons.payment,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    payment.typeDisplay,
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                              if (payment.vendorName != null)
                                Text(
                                  payment.vendorName!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            payment.displayReference ?? '-',
                            style: AppTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _currencyFormat.format(payment.amountDouble),
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: _buildMethodChip(payment.paymentMethod),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodChip(String method) {
    IconData icon;
    Color color;

    switch (method) {
      case 'CASH':
        icon = Icons.money;
        color = AppTheme.success;
        break;
      case 'UPI':
        icon = Icons.phone_android;
        color = AppTheme.primaryBlue;
        break;
      case 'BANK_TRANSFER':
        icon = Icons.account_balance;
        color = AppTheme.primaryBlue;
        break;
      case 'CARD':
        icon = Icons.credit_card;
        color = AppTheme.warning;
        break;
      case 'CHEQUE':
        icon = Icons.receipt;
        color = AppTheme.textSecondary;
        break;
      default:
        icon = Icons.payment;
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            method.replaceAll('_', ' '),
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
