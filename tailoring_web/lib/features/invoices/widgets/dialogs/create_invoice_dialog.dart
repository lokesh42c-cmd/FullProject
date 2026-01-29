import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:intl/intl.dart';

class CreateInvoiceDialog extends StatefulWidget {
  final int orderId;
  final int customerId;

  const CreateInvoiceDialog({
    super.key,
    required this.orderId,
    required this.customerId,
  });

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  bool _isLoading = false;
  bool _isSameAsCustomer = true;

  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _customerData;

  // Billing fields
  final _billingNameController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPincodeController = TextEditingController();
  final _billingGstinController = TextEditingController();

  // Shipping fields
  final _shippingNameController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPincodeController = TextEditingController();

  String _taxType = 'INTRASTATE';
  DateTime _invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _billingNameController.dispose();
    _billingAddressController.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPincodeController.dispose();
    _billingGstinController.dispose();
    _shippingNameController.dispose();
    _shippingAddressController.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final orderResponse = await _apiClient.get(
        'orders/orders/${widget.orderId}/',
      );
      final customerResponse = await _apiClient.get(
        'orders/customers/${widget.customerId}/',
      );

      setState(() {
        _orderData = orderResponse.data;
        _customerData = customerResponse.data;

        _billingNameController.text = _customerData!['name'] ?? '';
        _billingAddressController.text =
            _customerData!['address_line1'] ??
            _customerData!['full_address'] ??
            '';
        _billingCityController.text = _customerData!['city'] ?? '';
        _billingStateController.text = _customerData!['state'] ?? 'Karnataka';
        _billingPincodeController.text = _customerData!['pincode'] ?? '';

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _copyBillingToShipping() {
    if (_isSameAsCustomer) {
      _shippingNameController.text = _billingNameController.text;
      _shippingAddressController.text = _billingAddressController.text;
      _shippingCityController.text = _billingCityController.text;
      _shippingStateController.text = _billingStateController.text;
      _shippingPincodeController.text = _billingPincodeController.text;
    } else {
      _shippingNameController.clear();
      _shippingAddressController.clear();
      _shippingCityController.clear();
      _shippingStateController.clear();
      _shippingPincodeController.clear();
    }
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'order': widget.orderId,
        'customer': widget.customerId,
        'status': 'DRAFT',
        'invoice_date': DateFormat('yyyy-MM-dd').format(_invoiceDate),
        'billing_name': _billingNameController.text,
        'billing_address': _billingAddressController.text,
        'billing_state': _billingStateController.text,
        'tax_type': _taxType,
      };

      if (_billingCityController.text.isNotEmpty) {
        data['billing_city'] = _billingCityController.text;
      }
      if (_billingPincodeController.text.isNotEmpty) {
        data['billing_pincode'] = _billingPincodeController.text;
      }
      if (_billingGstinController.text.isNotEmpty) {
        data['billing_gstin'] = _billingGstinController.text;
      }

      if (!_isSameAsCustomer) {
        if (_shippingNameController.text.isNotEmpty) {
          data['shipping_name'] = _shippingNameController.text;
        }
        if (_shippingAddressController.text.isNotEmpty) {
          data['shipping_address'] = _shippingAddressController.text;
        }
        if (_shippingCityController.text.isNotEmpty) {
          data['shipping_city'] = _shippingCityController.text;
        }
        if (_shippingStateController.text.isNotEmpty) {
          data['shipping_state'] = _shippingStateController.text;
        }
        if (_shippingPincodeController.text.isNotEmpty) {
          data['shipping_pincode'] = _shippingPincodeController.text;
        }
      }

      final response = await _apiClient.post('invoicing/invoices/', data: data);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context, response.data['id']);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 1200,
        height: 800,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(flex: 4, child: _buildOrderSummary()),
                        Container(width: 1, color: AppTheme.borderLight),
                        Expanded(flex: 6, child: _buildInvoiceForm()),
                      ],
                    ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Invoice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Review order details and enter billing information',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    if (_orderData == null || _customerData == null) return const SizedBox();

    final items = _orderData!['items'] as List? ?? [];
    double subtotal = 0;
    double tax = 0;
    double total = 0;

    for (var item in items) {
      subtotal += (item['subtotal'] ?? 0).toDouble();
      tax += (item['tax_amount'] ?? 0).toDouble();
      total += (item['total_price'] ?? 0).toDouble();
    }

    return Container(
      color: AppTheme.backgroundGrey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _summaryCard(
              icon: Icons.receipt,
              color: Colors.blue,
              children: [
                _summaryRow(
                  'Order Number',
                  _orderData!['order_number'] ?? 'N/A',
                  isBold: true,
                ),
                _summaryRow('Order Date', _orderData!['order_date'] ?? 'N/A'),
                _summaryRow(
                  'Status',
                  _orderData!['order_status_display'] ?? 'N/A',
                ),
                _summaryRow(
                  'Delivery Date',
                  _orderData!['expected_delivery_date'] ?? 'N/A',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _summaryCard(
              icon: Icons.person,
              color: Colors.green,
              children: [
                _summaryRow(
                  'Customer',
                  _customerData!['name'] ?? 'N/A',
                  isBold: true,
                ),
                _summaryRow('Phone', _customerData!['phone'] ?? 'N/A'),
                if (_customerData!['email'] != null)
                  _summaryRow('Email', _customerData!['email']),
              ],
            ),

            const SizedBox(height: 16),

            _summaryCard(
              icon: Icons.inventory_2,
              color: Colors.orange,
              title: 'Items (${items.length})',
              children: [
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${item['quantity'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['item_name'] ?? 'Item',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (item['item_description'] != null)
                                Text(
                                  item['item_description'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${(item['total_price'] ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.primaryBlue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  _totalRow('Subtotal', subtotal),
                  const SizedBox(height: 8),
                  _totalRow('Tax', tax),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _totalRow('Grand Total', total, isGrandTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_document,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Invoice Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionTitle('Billing Information'),
            const SizedBox(height: 16),
            _buildTextField(
              _billingNameController,
              'Billing Name *',
              Icons.person,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _billingAddressController,
              'Billing Address *',
              Icons.location_on,
              maxLines: 2,
              required: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _billingCityController,
                    'City',
                    Icons.location_city,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _billingStateController,
                    'State *',
                    Icons.map,
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _billingPincodeController,
                    'Pincode',
                    Icons.pin_drop,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _billingGstinController,
                    'GSTIN',
                    Icons.tag,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                _sectionTitle('Shipping Information'),
                const Spacer(),
                Checkbox(
                  value: _isSameAsCustomer,
                  onChanged: (value) {
                    setState(() {
                      _isSameAsCustomer = value ?? true;
                      _copyBillingToShipping();
                    });
                  },
                  activeColor: AppTheme.primaryBlue,
                ),
                const Text(
                  'Same as Billing',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            if (!_isSameAsCustomer) ...[
              const SizedBox(height: 16),
              _buildTextField(
                _shippingNameController,
                'Shipping Name',
                Icons.person,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _shippingAddressController,
                'Shipping Address',
                Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _shippingCityController,
                      'City',
                      Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _shippingStateController,
                      'State',
                      Icons.map,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _shippingPincodeController,
                'Pincode',
                Icons.pin_drop,
                keyboardType: TextInputType.number,
              ),
            ],

            const SizedBox(height: 32),

            _sectionTitle('Tax Configuration'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _taxType,
              decoration: InputDecoration(
                labelText: 'Tax Type',
                prefixIcon: const Icon(Icons.percent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.backgroundGrey,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'INTRASTATE',
                  child: Text('Intrastate (CGST + SGST)'),
                ),
                DropdownMenuItem(
                  value: 'INTERSTATE',
                  child: Text('Interstate (IGST)'),
                ),
                DropdownMenuItem(value: 'ZERO', child: Text('Zero Rated')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _taxType = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color color,
    String? title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isBold ? AppTheme.textPrimary : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 16 : 13,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
            color: isGrandTotal ? AppTheme.primaryBlue : AppTheme.textPrimary,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isGrandTotal ? AppTheme.primaryBlue : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: AppTheme.backgroundGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: required
          ? (value) => value?.isEmpty ?? true ? 'Required' : null
          : null,
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          const Text(
            'Invoice will be created in DRAFT status',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _createInvoice,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isLoading ? 'Creating...' : 'Create Invoice'),
          ),
        ],
      ),
    );
  }
}
