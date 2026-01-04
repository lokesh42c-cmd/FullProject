import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/providers/customer_provider.dart';
import 'package:tailoring_web/features/customers/widgets/add_edit_customer_dialog.dart';
import 'package:tailoring_web/features/customers/screens/customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return MainLayout(
      currentRoute: '/customers',
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
                const Text('Customers', style: AppTheme.heading2),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _handleAddCustomer(provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Customer'),
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
                        hintText: 'Search by name, phone or city...',
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
                          value: 'INDIVIDUAL',
                          child: Text('Individual (B2C)'),
                        ),
                        DropdownMenuItem(
                          value: 'BUSINESS',
                          child: Text('Business (B2B)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setFilterType(value);
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.errorMessage!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.danger,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        ElevatedButton(
                          onPressed: () => provider.refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : provider.customers.isEmpty
                ? const Center(child: Text('No customers found'))
                : _buildCustomerTable(provider),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddCustomer(CustomerProvider provider) async {
    final customerId = await showDialog<int>(
      context: context,
      builder: (context) => const AddEditCustomerDialog(),
    );

    if (customerId != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerDetailScreen(customerId: customerId),
        ),
      );
      provider.refresh();
    }
  }

  Widget _buildCustomerTable(CustomerProvider provider) {
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
                    flex: 3,
                    child: Text('NAME', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('PHONE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('WHATSAPP', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('CITY', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('TYPE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'ORDERS',
                      style: AppTheme.tableHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Table Body
            ...provider.customers.map((customer) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    if (customer.id != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerDetailScreen(customerId: customer.id!),
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
                          flex: 3,
                          child: Text(
                            customer.name,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            customer.phone,
                            style: AppTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            // ✅ FIXED: Only whatsappNumber (removed alternatePhone)
                            customer.whatsappNumber ?? '-',
                            style: AppTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            customer.city ?? '-',
                            style: AppTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            customer.customerType == 'BUSINESS' ? 'B2B' : 'B2C',
                            style: AppTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${customer.totalOrders ?? 0}',
                            style: AppTheme.bodySmall,
                            textAlign: TextAlign.center,
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
}
