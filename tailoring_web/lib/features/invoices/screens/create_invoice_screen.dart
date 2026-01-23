import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../widgets/invoice_item_form.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final int? orderId; // If provided, creates from order

  const CreateInvoiceScreen({super.key, this.orderId});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final _formKey = GlobalKey<FormState>();

  bool _isCreating = false;
  bool _isFromOrder = false;

  // Customer fields
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  final TextEditingController _customerController = TextEditingController();

  // Invoice fields
  String _invoiceDate = '';
  final TextEditingController _billingNameController = TextEditingController();
  final TextEditingController _billingAddressController =
      TextEditingController();
  final TextEditingController _billingCityController = TextEditingController();
  final TextEditingController _billingStateController = TextEditingController();
  final TextEditingController _billingPincodeController =
      TextEditingController();
  final TextEditingController _billingGstinController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _termsController = TextEditingController(
    text: 'Payment due within 7 days',
  );

  List<InvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _isFromOrder = widget.orderId != null;
    _invoiceDate = DateTime.now().toIso8601String().split('T')[0];

    if (_isFromOrder) {
      _loadOrderData();
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _billingNameController.dispose();
    _billingAddressController.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPincodeController.dispose();
    _billingGstinController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    // TODO: Load order data when integrating with orders
    // For now, this is a placeholder for future integration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Selection (only if not from order)
                    if (!_isFromOrder) _buildModeSelection(),
                    if (!_isFromOrder) const SizedBox(height: 20),

                    // Customer Selection
                    _buildCustomerSection(),
                    const SizedBox(height: 20),

                    // Billing Address
                    _buildBillingSection(),
                    const SizedBox(height: 20),

                    // Invoice Details
                    _buildInvoiceDetailsSection(),
                    const SizedBox(height: 20),

                    // Items Section
                    _buildItemsSection(),
                    const SizedBox(height: 20),

                    // Summary
                    _buildSummarySection(),
                    const SizedBox(height: 20),

                    // Notes & Terms
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createInvoice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Create Invoice'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('From Order'),
                    subtitle: const Text('Select existing order'),
                    value: true,
                    groupValue: _isFromOrder,
                    onChanged: (value) {
                      setState(() => _isFromOrder = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Direct/Walk-in'),
                    subtitle: const Text('Manual entry'),
                    value: false,
                    groupValue: _isFromOrder,
                    onChanged: (value) {
                      setState(() => _isFromOrder = value!);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'Select Customer *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Search customer by name or phone...',
              ),
              validator: (value) {
                if (_selectedCustomerId == null) {
                  return 'Please select a customer';
                }
                return null;
              },
              // TODO: Add autocomplete when integrating with customers
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Customer autocomplete will be added during integration',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _billingNameController,
              decoration: const InputDecoration(
                labelText: 'Billing Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _billingAddressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingCityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _billingStateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billingPincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _billingGstinController,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _invoiceDate,
              decoration: const InputDecoration(
                labelText: 'Invoice Date *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _invoiceDate = date.toIso8601String().split('T')[0];
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No items added',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add Item" to get started',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return InvoiceItemForm(
                  key: ValueKey(index),
                  item: item,
                  onChanged: (updatedItem) {
                    setState(() => _items[index] = updatedItem);
                  },
                  onDelete: () {
                    setState(() => _items.removeAt(index));
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final subtotal = _items.fold<double>(
      0.0,
      (sum, item) => sum + item.calculateSubtotal(),
    );
    final cgst = _items.fold<double>(
      0.0,
      (sum, item) => sum + item.calculateCgst('INTRASTATE'),
    );
    final sgst = _items.fold<double>(
      0.0,
      (sum, item) => sum + item.calculateSgst('INTRASTATE'),
    );
    final total = subtotal + cgst + sgst;

    return Card(
      elevation: 0,
      color: AppTheme.primaryBlue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('Subtotal', subtotal),
            const SizedBox(height: 8),
            _summaryRow('CGST', cgst),
            _summaryRow('SGST', sgst),
            const Divider(height: 20),
            _summaryRow('Grand Total', total, isBold: true, isLarge: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            fontSize: isLarge ? 18 : 14,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            fontSize: isLarge ? 18 : 14,
            color: isLarge ? AppTheme.primaryBlue : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(
                labelText: 'Terms & Conditions',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _items.add(
        InvoiceItem(
          itemDescription: '',
          quantity: 1.0,
          unitPrice: 0.0,
          gstRate: 18.0,
        ),
      );
    });
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Validate items
    for (var item in _items) {
      if (item.itemDescription.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all item descriptions'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
      if (item.quantity <= 0 || item.unitPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item quantity and price must be greater than 0'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
      // TODO: Get actual customer ID from autocomplete
      // For now, using placeholder customer ID = 1
      final invoice = Invoice(
        invoiceNumber: '', // Auto-generated
        invoiceDate: _invoiceDate,
        customer: 1, // TODO: Use _selectedCustomerId
        order: widget.orderId,
        status: 'DRAFT',
        billingName: _billingNameController.text,
        billingAddress: _billingAddressController.text,
        billingCity: _billingCityController.text.isNotEmpty
            ? _billingCityController.text
            : null,
        billingState: _billingStateController.text,
        billingPincode: _billingPincodeController.text.isNotEmpty
            ? _billingPincodeController.text
            : null,
        billingGstin: _billingGstinController.text.isNotEmpty
            ? _billingGstinController.text
            : null,
        taxType: 'INTRASTATE',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        termsAndConditions: _termsController.text.isNotEmpty
            ? _termsController.text
            : null,
        items: _items,
      );

      await _invoiceService.createInvoice(invoice);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
