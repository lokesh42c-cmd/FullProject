import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/orders/widgets/customer_autocomplete.dart';

/// Billing & Shipping Address Section - UPDATED
/// Two-column layout, shipping always visible (grayed when same as billing)
class BillingShippingSection extends StatefulWidget {
  final Customer? selectedCustomer;
  final ValueChanged<Customer?> onCustomerSelected;
  final TextEditingController billingNameController;
  final TextEditingController billingAddressController;
  final TextEditingController billingCityController;
  final TextEditingController billingStateController;
  final TextEditingController billingPincodeController;
  final TextEditingController billingGstinController;
  final TextEditingController shippingNameController;
  final TextEditingController shippingAddressController;
  final TextEditingController shippingCityController;
  final TextEditingController shippingStateController;
  final TextEditingController shippingPincodeController;
  final bool readOnly;

  const BillingShippingSection({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    required this.billingNameController,
    required this.billingAddressController,
    required this.billingCityController,
    required this.billingStateController,
    required this.billingPincodeController,
    required this.billingGstinController,
    required this.shippingNameController,
    required this.shippingAddressController,
    required this.shippingCityController,
    required this.shippingStateController,
    required this.shippingPincodeController,
    this.readOnly = false,
  });

  @override
  State<BillingShippingSection> createState() => _BillingShippingSectionState();
}

class _BillingShippingSectionState extends State<BillingShippingSection> {
  bool _sameAsBilling = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          // Customer Selection (if not read-only)
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomerAutocomplete(
                initialCustomer: widget.selectedCustomer,
                onCustomerSelected: (customer) {
                  widget.onCustomerSelected(customer);
                  if (customer != null) {
                    _copyCustomerToBilling(customer);
                  }
                },
              ),
            ),

          // Two-column layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Billing Address Column
                Expanded(child: _buildBillingColumn()),
                const SizedBox(width: 16),

                // Shipping Address Column (ALWAYS VISIBLE)
                Expanded(child: _buildShippingColumn()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with copy button
        Row(
          children: [
            const Icon(Icons.receipt, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text('Billing Address *', style: AppTheme.heading3),
            const Spacer(),
            if (widget.selectedCustomer != null && !widget.readOnly)
              TextButton.icon(
                onPressed: () =>
                    _copyCustomerToBilling(widget.selectedCustomer!),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy from Customer'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Name
        _buildTextField(
          controller: widget.billingNameController,
          label: 'Name *',
          readOnly: widget.readOnly,
        ),
        const SizedBox(height: 12),

        // Address
        _buildTextField(
          controller: widget.billingAddressController,
          label: 'Address *',
          maxLines: 2,
          readOnly: widget.readOnly,
          onChanged: (_) {
            if (_sameAsBilling) _copyBillingToShipping();
          },
        ),
        const SizedBox(height: 12),

        // City & State Row
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: widget.billingCityController,
                label: 'City',
                readOnly: widget.readOnly,
                onChanged: (_) {
                  if (_sameAsBilling) _copyBillingToShipping();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: widget.billingStateController,
                label: 'State *',
                readOnly: widget.readOnly,
                onChanged: (_) {
                  if (_sameAsBilling) _copyBillingToShipping();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Pincode & GSTIN Row
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: widget.billingPincodeController,
                label: 'Pincode',
                readOnly: widget.readOnly,
                onChanged: (_) {
                  if (_sameAsBilling) _copyBillingToShipping();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: widget.billingGstinController,
                label: 'GSTIN',
                readOnly: widget.readOnly,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShippingColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with checkbox
        Row(
          children: [
            const Icon(
              Icons.local_shipping,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text('Shipping Address', style: AppTheme.heading3),
            const Spacer(),
            if (!widget.readOnly)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _sameAsBilling,
                    onChanged: (value) {
                      setState(() {
                        _sameAsBilling = value ?? true;
                        if (_sameAsBilling) {
                          _copyBillingToShipping();
                        }
                      });
                    },
                  ),
                  const Text('Same as billing'),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ALWAYS SHOW FIELDS - just gray them out
        _buildTextField(
          controller: widget.shippingNameController,
          label: 'Name',
          readOnly: widget.readOnly || _sameAsBilling,
          isGrayed: _sameAsBilling,
        ),
        const SizedBox(height: 12),

        _buildTextField(
          controller: widget.shippingAddressController,
          label: 'Address',
          maxLines: 2,
          readOnly: widget.readOnly || _sameAsBilling,
          isGrayed: _sameAsBilling,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: widget.shippingCityController,
                label: 'City',
                readOnly: widget.readOnly || _sameAsBilling,
                isGrayed: _sameAsBilling,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: widget.shippingStateController,
                label: 'State',
                readOnly: widget.readOnly || _sameAsBilling,
                isGrayed: _sameAsBilling,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildTextField(
          controller: widget.shippingPincodeController,
          label: 'Pincode',
          readOnly: widget.readOnly || _sameAsBilling,
          isGrayed: _sameAsBilling,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool readOnly = false,
    bool isGrayed = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      style: AppTheme.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        filled: readOnly || isGrayed,
        fillColor: (readOnly || isGrayed) ? AppTheme.backgroundGrey : null,
      ),
    );
  }

  void _copyCustomerToBilling(Customer customer) {
    widget.billingNameController.text = customer.name;

    // Combine addressLine1 and addressLine2
    final address = [
      customer.addressLine1,
      customer.addressLine2,
    ].where((line) => line != null && line.isNotEmpty).join(' ');

    widget.billingAddressController.text = address;
    widget.billingCityController.text = customer.city ?? '';
    widget.billingStateController.text = customer.state ?? '';
    widget.billingPincodeController.text = customer.pincode ?? '';
    widget.billingGstinController.text = customer.gstin ?? '';

    if (_sameAsBilling) {
      _copyBillingToShipping();
    }
  }

  void _copyBillingToShipping() {
    widget.shippingNameController.text = widget.billingNameController.text;
    widget.shippingAddressController.text =
        widget.billingAddressController.text;
    widget.shippingCityController.text = widget.billingCityController.text;
    widget.shippingStateController.text = widget.billingStateController.text;
    widget.shippingPincodeController.text =
        widget.billingPincodeController.text;
  }
}
