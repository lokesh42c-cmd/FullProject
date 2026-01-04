import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/providers/bill_provider.dart';
import 'package:tailoring_web/features/purchase_management/screens/bills/bill_form_screen.dart';
import 'package:tailoring_web/features/purchase_management/screens/bills/bill_detail_screen.dart';
import 'package:intl/intl.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd-MMM-yy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().fetchBills(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    return MainLayout(
      currentRoute: '/purchase/bills',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Text('Purchase Bills', style: AppTheme.heading2),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _handleAddBill(provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Bill'),
                ),
              ],
            ),
          ),
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
                        hintText: 'Search by bill number or vendor...',
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
                      value: provider.filterStatus,
                      style: AppTheme.bodySmall,
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Bills'),
                        ),
                        DropdownMenuItem(
                          value: 'UNPAID',
                          child: Text('Unpaid'),
                        ),
                        DropdownMenuItem(
                          value: 'PARTIALLY_PAID',
                          child: Text('Partially Paid'),
                        ),
                        DropdownMenuItem(
                          value: 'FULLY_PAID',
                          child: Text('Fully Paid'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setFilterStatus(value);
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
                : provider.bills.isEmpty
                ? const Center(child: Text('No bills found'))
                : _buildBillTable(provider),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddBill(BillProvider provider) async {
    final billId = await showDialog<int>(
      context: context,
      builder: (context) => const BillFormScreen(),
    );

    if (billId != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillDetailScreen(billId: billId),
        ),
      );
      provider.refresh();
    }
  }

  Widget _buildBillTable(BillProvider provider) {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundGrey,
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('BILL NUMBER', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('VENDOR', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('DATE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'BILL AMOUNT',
                      style: AppTheme.tableHeader,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'BALANCE',
                      style: AppTheme.tableHeader,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'STATUS',
                      style: AppTheme.tableHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            ...provider.bills.map((bill) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    if (bill.id != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BillDetailScreen(billId: bill.id!),
                        ),
                      );
                      provider.refresh();
                    }
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
                            bill.billNumber ?? "",
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(flex: 2, child: Text(bill.vendorName ?? "-")),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _dateFormat.format(bill.billDate),
                            style: AppTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _currencyFormat.format(bill.billAmountDouble),
                            style: AppTheme.bodyMedium,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _currencyFormat.format(bill.balanceAmountDouble),
                            style: AppTheme.bodyMedium.copyWith(
                              color: bill.balanceAmountDouble > 0
                                  ? AppTheme.danger
                                  : AppTheme.success,
                              fontWeight: bill.balanceAmountDouble > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: _buildStatusBadge(bill.paymentStatus),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'UNPAID':
        color = AppTheme.danger;
        label = 'UNPAID';
        break;
      case 'PARTIALLY_PAID':
        color = AppTheme.warning;
        label = 'PARTIAL';
        break;
      case 'FULLY_PAID':
        color = AppTheme.success;
        label = 'PAID';
        break;
      default:
        color = AppTheme.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
