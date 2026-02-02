import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/auth/providers/auth_provider.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/invoices/models/invoice.dart';
import 'package:tailoring_web/features/invoices/providers/invoice_provider.dart';
import 'package:tailoring_web/features/invoices/widgets/company_details_header.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_details_row.dart';
import 'package:tailoring_web/features/invoices/widgets/billing_shipping_section.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_summary_panel.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_notes_section.dart';

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
  final _apiClient = ApiClient();

  // Controllers
  final _invoiceNumberController = TextEditingController();
  final _billingNameController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPincodeController = TextEditingController();
  final _billingGstinController = TextEditingController();
  final _shippingNameController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPincodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  Customer? _selectedCustomer;
  Map<String, dynamic>? _orderData;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _deliveryDate;
  String _taxType = 'INTRASTATE';
  bool _isTaxInclusive = false;
  List<InvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadOrderAndCustomer();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
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
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderAndCustomer() async {
    try {
      final orderRes = await _apiClient.get('orders/orders/${widget.orderId}/');
      final customerRes = await _apiClient.get(
        'orders/customers/${widget.customerId}/',
      );

      setState(() {
        _orderData = orderRes.data;
        _selectedCustomer = Customer.fromJson(customerRes.data);

        _billingNameController.text = _selectedCustomer?.name ?? '';
        _billingAddressController.text =
            _orderData?['billing_address'] ??
            _selectedCustomer?.addressLine1 ??
            '';
        _billingCityController.text =
            _orderData?['billing_city'] ?? _selectedCustomer?.city ?? '';
        _billingStateController.text =
            _orderData?['billing_state'] ?? _selectedCustomer?.state ?? '';
        _billingPincodeController.text =
            _orderData?['billing_pincode'] ?? _selectedCustomer?.pincode ?? '';

        _shippingNameController.text = _selectedCustomer?.name ?? '';
        _shippingAddressController.text =
            _orderData?['shipping_address'] ??
            _selectedCustomer?.addressLine1 ??
            '';
        _shippingCityController.text =
            _orderData?['shipping_city'] ?? _selectedCustomer?.city ?? '';
        _shippingStateController.text =
            _orderData?['shipping_state'] ?? _selectedCustomer?.state ?? '';
        _shippingPincodeController.text =
            _orderData?['shipping_pincode'] ?? _selectedCustomer?.pincode ?? '';

        if (_orderData?['expected_delivery_date'] != null) {
          _deliveryDate = DateTime.parse(_orderData!['expected_delivery_date']);
        }

        final authProvider = context.read<AuthProvider>();
        if (_billingStateController.text.isNotEmpty &&
            authProvider.tenantState != null) {
          _taxType = _billingStateController.text == authProvider.tenantState
              ? 'INTRASTATE'
              : 'INTERSTATE';
        }

        if (_orderData?['items'] != null) {
          _items = (_orderData!['items'] as List)
              .map(
                (i) => InvoiceItem(
                  itemDescription: i['item_name'] ?? 'Item',
                  quantity: (i['quantity'] ?? 1).toDouble(),
                  unitPrice: (i['unit_price'] ?? 0).toDouble(),
                  gstRate: (i['gst_rate'] ?? 0).toDouble(),
                ),
              )
              .toList();
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: AppTheme.backgroundGray,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            _buildDialogHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildLeftFormColumn()),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: _buildRightSummaryColumn()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            'Create Invoice from Order: ${_orderData?['order_number']}',
            style: AppTheme.heading2,
          ),
          const Spacer(),
          if (_isSaving) const CircularProgressIndicator(strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildLeftFormColumn() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const CompanyDetailsHeader(),
          const SizedBox(height: 20),

          InvoiceDetailsRow(
            invoiceNumberController: _invoiceNumberController,
            invoiceDate: _invoiceDate,
            deliveryDate: _deliveryDate,
            orderReference: _orderData?['order_number'],
            taxType: _taxType,
            isTaxInclusive: _isTaxInclusive,
            onInvoiceDateChanged: (date) =>
                setState(() => _invoiceDate = date ?? DateTime.now()),
            onDeliveryDateChanged: (date) =>
                setState(() => _deliveryDate = date),
            onTaxTypeChanged: (type) => setState(() => _taxType = type),
            isFromOrder: true,
          ),
          const SizedBox(height: 20),

          BillingShippingSection(
            selectedCustomer: _selectedCustomer,
            onCustomerSelected: (_) {},
            billingNameController: _billingNameController,
            billingAddressController: _billingAddressController,
            billingCityController: _billingCityController,
            billingStateController: _billingStateController,
            billingPincodeController: _billingPincodeController,
            billingGstinController: _billingGstinController,
            shippingNameController: _shippingNameController,
            shippingAddressController: _shippingAddressController,
            shippingCityController: _shippingCityController,
            shippingStateController: _shippingStateController,
            shippingPincodeController: _shippingPincodeController,
            readOnly: true,
          ),
          const SizedBox(height: 20),

          _buildReadOnlyItemsTable(),
          const SizedBox(height: 20),

          InvoiceNotesSection(
            notesController: _notesController,
            termsController: _termsController,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyItemsTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Order Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                title: Text(item.itemDescription),
                subtitle: Text('Qty: ${item.quantity} x ₹${item.unitPrice}'),
                trailing: Text(
                  '₹${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: AppTheme.fontBold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRightSummaryColumn() {
    return InvoiceSummaryPanel(
      items: _items,
      isTaxInclusive: _isTaxInclusive,
      advanceAdjusted: 0.0,
      isSaving: _isSaving,
      onCancel: () => Navigator.pop(context),
      onSaveDraft: () => _handleAction('DRAFT'),
      onIssueInvoice: () => _handleAction('ISSUED'),
    );
  }

  Future<void> _handleAction(String status) async {
    setState(() => _isSaving = true);
    final invoice = Invoice(
      invoiceNumber: _invoiceNumberController.text.isEmpty
          ? 'AUTO'
          : _invoiceNumberController.text,
      invoiceDate: _invoiceDate.toIso8601String().split('T')[0],
      customer: widget.customerId,
      order: widget.orderId,
      status: status,
      billingName: _billingNameController.text,
      billingAddress: _billingAddressController.text,
      billingCity: _billingCityController.text,
      billingState: _billingStateController.text,
      billingPincode: _billingPincodeController.text,
      taxType: _taxType,
      items: null,
    );
    final success = await context.read<InvoiceProvider>().createInvoice(
      invoice,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success != null) Navigator.pop(context);
    }
  }
}
