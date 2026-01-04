import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/customers/providers/customer_provider.dart';

/// Autocomplete Customer Search
///
/// Search customers by typing, shows matching results
class CustomerAutocomplete extends StatefulWidget {
  final Customer? initialCustomer;
  final Function(Customer?) onCustomerSelected;

  const CustomerAutocomplete({
    super.key,
    this.initialCustomer,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerAutocomplete> createState() => _CustomerAutocompleteState();
}

class _CustomerAutocompleteState extends State<CustomerAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;
    if (_selectedCustomer != null) {
      _controller.text = _selectedCustomer!.name;
    }

    // Load customers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();

    return Row(
      children: [
        // Autocomplete field
        Expanded(
          child: Autocomplete<Customer>(
            initialValue: _selectedCustomer != null
                ? TextEditingValue(text: _selectedCustomer!.name)
                : null,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Customer>.empty();
              }

              final query = textEditingValue.text.toLowerCase();
              return customerProvider.customers.where((customer) {
                return customer.name.toLowerCase().contains(query) ||
                    customer.phone.contains(query);
              });
            },
            displayStringForOption: (Customer customer) => customer.name,
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Customer *',
                      hintText: 'Type to search by name or phone...',
                      prefixIcon: const Icon(Icons.person_search, size: 20),
                      suffixIcon: _selectedCustomer != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                controller.clear();
                                setState(() => _selectedCustomer = null);
                                widget.onCustomerSelected(null);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 400,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final customer = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(customer),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primaryBlue
                                      .withOpacity(0.1),
                                  child: Text(
                                    customer.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: AppTheme.bodyMedium,
                                      ),
                                      Text(
                                        '${customer.phone} • ${customer.city ?? 'No city'}',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (Customer customer) {
              setState(() => _selectedCustomer = customer);
              widget.onCustomerSelected(customer);
            },
          ),
        ),

        const SizedBox(width: 8),

        // Add new customer button
        IconButton(
          onPressed: _showCreateCustomerDialog,
          icon: const Icon(Icons.add_circle, color: AppTheme.primaryBlue),
          tooltip: 'Add New Customer',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  void _showCreateCustomerDialog() {
    // TODO: Show create customer dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quick customer creation - Coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
