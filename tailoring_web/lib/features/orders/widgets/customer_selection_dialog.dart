import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/customers/providers/customer_provider.dart';
import 'package:tailoring_web/features/customers/widgets/add_edit_customer_dialog.dart';

/// Customer Selection Dialog
///
/// Search and select customer for order creation
class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
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
    // Clear search filter when dialog closes
    context.read<CustomerProvider>().setSearchQuery('');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Dialog(
      child: Container(
        width: 600,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space5),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGray,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_search, color: AppTheme.primaryBlue),
                  const SizedBox(width: AppTheme.space3),
                  const Text('Select Customer', style: AppTheme.heading2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => provider.setSearchQuery(value),
              ),
            ),

            // Quick create button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _createNewCustomer(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create New Customer'),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space4),

            // Customer list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: AppTheme.space3),
                          Text(
                            'No customers found',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.customers.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space4,
                      ),
                      itemBuilder: (context, index) {
                        final customer = provider.customers[index];
                        return _buildCustomerCard(customer);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      child: InkWell(
        onTap: () => Navigator.pop(context, customer),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space4),

              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTheme.bodyMediumBold),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (customer.city != null) ...[
                          const SizedBox(width: AppTheme.space3),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer.city!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Select icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewCustomer() async {
    final customerId = await showDialog<int>(
      context: context,
      builder: (context) => const AddEditCustomerDialog(),
    );

    if (customerId != null && mounted) {
      // Refresh customer list
      await context.read<CustomerProvider>().fetchCustomers(refresh: true);

      // Find and return the newly created customer
      final provider = context.read<CustomerProvider>();
      final newCustomer = provider.customers.firstWhere(
        (c) => c.id == customerId,
        orElse: () => provider.customers.first,
      );

      if (mounted) {
        Navigator.pop(context, newCustomer);
      }
    }
  }
}
