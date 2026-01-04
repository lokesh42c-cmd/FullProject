import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/models/purchase_bill.dart';
import 'package:tailoring_web/features/purchase_management/providers/bill_provider.dart';
import 'package:tailoring_web/features/purchase_management/providers/vendor_provider.dart';

class BillFormScreen extends StatefulWidget {
  final PurchaseBill? bill;

  const BillFormScreen({super.key, this.bill});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _billAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _billDate = DateTime.now();
  int? _selectedVendorId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _billNumberController.text = widget.bill!.billNumber;
      _billAmountController.text = widget.bill!.billAmount;
      _descriptionController.text = widget.bill!.description ?? '';
      _billDate = widget.bill!.billDate;
      _selectedVendorId = widget.bill!.vendor;
    }
    // Load vendors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchVendors(refresh: true);
    });
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _billAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final isEdit = widget.bill != null;

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    isEdit ? 'Edit Bill' : 'New Purchase Bill',
                    style: AppTheme.heading3,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vendor Dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedVendorId,
                        decoration: const InputDecoration(
                          labelText: 'Vendor *',
                          prefixIcon: Icon(Icons.business, size: 18),
                        ),
                        style: AppTheme.bodyMedium,
                        items: vendorProvider.vendors
                            .map(
                              (vendor) => DropdownMenuItem(
                                value: vendor.id,
                                child: Text(vendor.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVendorId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a vendor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Bill Number
                      TextFormField(
                        controller: _billNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Number *',
                          prefixIcon: Icon(Icons.receipt, size: 18),
                          hintText: 'e.g., INV-2025-001',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter bill number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Bill Date
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Bill Date *',
                            prefixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _formatDate(_billDate),
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Bill Amount
                      TextFormField(
                        controller: _billAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Amount (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee, size: 18),
                          hintText: '0.00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter bill amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description, size: 18),
                          hintText: 'Brief description of purchase...',
                        ),
                        maxLines: 3,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(isEdit ? 'Update Bill' : 'Create Bill'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _billDate) {
      setState(() {
        _billDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedVendorId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final bill = PurchaseBill(
      id: widget.bill?.id,
      vendor: _selectedVendorId!,
      billNumber: _billNumberController.text,
      billDate: _billDate,
      billAmount: _billAmountController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
    );

    final provider = context.read<BillProvider>();

    if (widget.bill != null) {
      // Update
      final success = await provider.updateBill(widget.bill!.id!, bill);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to update bill'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } else {
      // Create
      final billId = await provider.createBill(bill);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (billId != null) {
          Navigator.pop(context, billId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to create bill'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }
}
