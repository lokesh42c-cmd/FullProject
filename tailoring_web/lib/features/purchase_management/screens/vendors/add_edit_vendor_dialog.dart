import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/models/vendor.dart';
import 'package:tailoring_web/features/purchase_management/providers/vendor_provider.dart';

class AddEditVendorDialog extends StatefulWidget {
  final Vendor? vendor;

  const AddEditVendorDialog({super.key, this.vendor});

  @override
  State<AddEditVendorDialog> createState() => _AddEditVendorDialogState();
}

class _AddEditVendorDialogState extends State<AddEditVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _initializeWithVendor(widget.vendor!);
    }
  }

  void _initializeWithVendor(Vendor vendor) {
    _nameController.text = vendor.name;
    _businessNameController.text = vendor.businessName ?? '';
    _phoneController.text = vendor.phone;
    _alternatePhoneController.text = vendor.alternatePhone ?? '';
    _emailController.text = vendor.email ?? '';
    _addressLine1Controller.text = vendor.addressLine1 ?? '';
    _addressLine2Controller.text = vendor.addressLine2 ?? '';
    _cityController.text = vendor.city ?? '';
    _stateController.text = vendor.state ?? '';
    _pincodeController.text = vendor.pincode ?? '';
    _gstinController.text = vendor.gstin ?? '';
    _panController.text = vendor.pan ?? '';
    _paymentTermsController.text = vendor.paymentTermsDays?.toString() ?? '';
    _notesController.text = vendor.notes ?? '';
    _isActive = vendor.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vendor != null;

    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Edit Vendor' : 'New Vendor',
                    style: AppTheme.heading3,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      const Text(
                        'Basic Information',
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.space3),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor Name *',
                          hintText: 'e.g., Silk House',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vendor name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space3),

                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          hintText: 'e.g., Silk House Pvt Ltd',
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                hintText: '9876543210',
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (value.length != 10) {
                                  return 'Phone must be 10 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.space3),
                          Expanded(
                            child: TextFormField(
                              controller: _alternatePhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Alternate Phone',
                                hintText: '9876543210',
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length != 10) {
                                  return 'Phone must be 10 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space3),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'info@vendor.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter valid email';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space5),

                      // Address
                      const Text('Address', style: AppTheme.bodyMedium),
                      const SizedBox(height: AppTheme.space3),

                      TextFormField(
                        controller: _addressLine1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1',
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),

                      TextFormField(
                        controller: _addressLine2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 2',
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space3),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space3),
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              decoration: const InputDecoration(
                                labelText: 'Pincode',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space5),

                      // Tax Information
                      const Text('Tax Information', style: AppTheme.bodyMedium),
                      const SizedBox(height: AppTheme.space3),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gstinController,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN',
                                hintText: '29ABCDE1234F1Z5',
                              ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(15),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Z0-9]'),
                                ),
                              ],
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length != 15) {
                                  return 'GSTIN must be 15 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.space3),
                          Expanded(
                            child: TextFormField(
                              controller: _panController,
                              decoration: const InputDecoration(
                                labelText: 'PAN',
                                hintText: 'ABCDE1234F',
                              ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(10),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Z0-9]'),
                                ),
                              ],
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length != 10) {
                                  return 'PAN must be 10 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space5),

                      // Payment Terms
                      const Text('Payment Terms', style: AppTheme.bodyMedium),
                      const SizedBox(height: AppTheme.space3),

                      TextFormField(
                        controller: _paymentTermsController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms (Days)',
                          hintText: '30',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: AppTheme.space3),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppTheme.space3),

                      CheckboxListTile(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value ?? true;
                          });
                        },
                        title: const Text('Active'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Update Vendor' : 'Create Vendor'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final vendor = Vendor(
      id: widget.vendor?.id,
      name: _nameController.text,
      businessName: _businessNameController.text.isNotEmpty
          ? _businessNameController.text
          : null,
      phone: _phoneController.text,
      alternatePhone: _alternatePhoneController.text.isNotEmpty
          ? _alternatePhoneController.text
          : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      addressLine1: _addressLine1Controller.text.isNotEmpty
          ? _addressLine1Controller.text
          : null,
      addressLine2: _addressLine2Controller.text.isNotEmpty
          ? _addressLine2Controller.text
          : null,
      city: _cityController.text.isNotEmpty ? _cityController.text : null,
      state: _stateController.text.isNotEmpty ? _stateController.text : null,
      pincode: _pincodeController.text.isNotEmpty
          ? _pincodeController.text
          : null,
      gstin: _gstinController.text.isNotEmpty ? _gstinController.text : null,
      pan: _panController.text.isNotEmpty ? _panController.text : null,
      paymentTermsDays: _paymentTermsController.text.isNotEmpty
          ? int.tryParse(_paymentTermsController.text)
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      isActive: _isActive,
    );

    final provider = context.read<VendorProvider>();

    if (widget.vendor != null) {
      // Update
      final success = await provider.updateVendor(widget.vendor!.id!, vendor);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to update vendor'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } else {
      // Create
      final vendorId = await provider.createVendor(vendor);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (vendorId != null) {
          Navigator.pop(context, vendorId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to create vendor'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }
}
