import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/features/auth/providers/auth_provider.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/invoices/models/invoice.dart';
import 'package:tailoring_web/features/invoices/providers/invoice_provider.dart';
import 'package:tailoring_web/features/invoices/widgets/company_details_header.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_details_row.dart';
import 'package:tailoring_web/features/invoices/widgets/billing_shipping_section.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_items_table.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_summary_panel.dart';
import 'package:tailoring_web/features/invoices/widgets/invoice_notes_section.dart';
import 'package:tailoring_web/features/orders/models/order.dart';

/// Create Invoice Screen - UPDATED
/// Supports: Tax mode toggle, Item search, Proper calculations
class CreateInvoiceScreen extends StatefulWidget {
  final Order? order;

  const CreateInvoiceScreen({super.key, this.order});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
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
  Customer? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _deliveryDate;
  String _taxType = 'INTRASTATE';
  bool _isTaxInclusive = false; // NEW: Tax mode state
  List<InvoiceItem> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final authProvider = context.read<AuthProvider>();

    if (widget.order != null) {
      // From order: pre-fill data
      if (widget.order!.customerName != null) {
        _billingNameController.text = widget.order!.customerName!;
      }

      // Auto-detect tax type
      if (_billingStateController.text.isNotEmpty &&
          authProvider.tenantState != null) {
        _taxType = _billingStateController.text == authProvider.tenantState
            ? 'INTRASTATE'
            : 'INTERSTATE';
      }

      // Items will be copied by backend
      _items = [];

      // Lock tax mode to order's mode (assuming order has this field)
      // For now, keep it editable
    } else {
      // Walk-in: start empty
      _items = [];
    }
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

  // NEW: Tax mode toggle handler
  void _onTaxModeChanged(bool isTaxInclusive) {
    setState(() {
      _isTaxInclusive = isTaxInclusive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/invoices/create',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildLeftColumn()),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: _buildRightColumn()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.order != null
                    ? 'Create Invoice from Order'
                    : 'Create New Invoice',
                style: AppTheme.heading2,
              ),
              if (widget.order != null)
                Text(
                  'Order: ${widget.order!.orderNumber}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (_isSaving)
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Saving...'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CompanyDetailsHeader(),
          const SizedBox(height: 20),

          InvoiceDetailsRow(
            invoiceNumberController: _invoiceNumberController,
            invoiceDate: _invoiceDate,
            deliveryDate: _deliveryDate,
            orderReference: widget.order?.orderNumber,
            taxType: _taxType,
            isTaxInclusive: _isTaxInclusive,
            onInvoiceDateChanged: (date) {
              if (date != null) {
                setState(() => _invoiceDate = date);
              }
            },
            onDeliveryDateChanged: (date) {
              setState(() => _deliveryDate = date);
            },
            onTaxTypeChanged: (type) {
              setState(() => _taxType = type);
            },
            isFromOrder: widget.order != null,
          ),
          const SizedBox(height: 20),

          BillingShippingSection(
            selectedCustomer: _selectedCustomer,
            onCustomerSelected: (customer) {
              setState(() {
                _selectedCustomer = customer;
                if (customer != null) {
                  _autoDetectTaxType();
                }
              });
            },
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
            readOnly: widget.order != null,
          ),
          const SizedBox(height: 20),

          // Items Section with Tax Toggle
          _buildItemsSection(),
          const SizedBox(height: 20),

          InvoiceNotesSection(
            notesController: _notesController,
            termsController: _termsController,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          // Header with Tax Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Invoice Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Tax Toggle (like Order screen)
                if (widget.order == null) // Only for walk-in
                  _buildTaxRadioSelector(),
              ],
            ),
          ),

          // Items Table or Message
          if (widget.order != null)
            // From order: show message
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Text(
                    'Items will be automatically copied from the order',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            // Walk-in: show table with search
            InvoiceItemsTable(
              items: _items,
              isTaxInclusive: _isTaxInclusive,
              onItemsChanged: (items) {
                setState(() => _items = items);
              },
              readOnly: false,
            ),
        ],
      ),
    );
  }

  // NEW: Tax mode toggle (exact copy from Order screen)
  Widget _buildTaxRadioSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _taxOption("Exclusive", false),
          _taxOption("Inclusive", true),
        ],
      ),
    );
  }

  Widget _taxOption(String label, bool value) {
    bool isSelected = _isTaxInclusive == value;
    return InkWell(
      onTap: () => _onTaxModeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.backgroundWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black12, blurRadius: 2)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    double? advanceAdjusted;
    if (widget.order != null) {
      advanceAdjusted = 0.0; // TODO: Calculate from receipt vouchers
    }

    return InvoiceSummaryPanel(
      items: _items,
      isTaxInclusive: _isTaxInclusive,
      advanceAdjusted: advanceAdjusted,
      isSaving: _isSaving,
      onCancel: _handleCancel,
      onSaveDraft: _handleSaveDraft,
      onIssueInvoice: _handleIssueInvoice,
    );
  }

  void _autoDetectTaxType() {
    final authProvider = context.read<AuthProvider>();
    if (_billingStateController.text.isNotEmpty &&
        authProvider.tenantState != null) {
      setState(() {
        _taxType = _billingStateController.text == authProvider.tenantState
            ? 'INTRASTATE'
            : 'INTERSTATE';
      });
    }
  }

  Future<void> _handleSaveDraft() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    final invoice = _buildInvoice(status: 'DRAFT');
    final invoiceProvider = context.read<InvoiceProvider>();

    final created = await invoiceProvider.createInvoice(invoice);

    setState(() => _isSaving = false);

    if (created != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft invoice ${created.invoiceNumber} saved'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              invoiceProvider.errorMessage ?? 'Failed to save draft',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleIssueInvoice() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    final invoice = _buildInvoice(status: 'ISSUED');
    final invoiceProvider = context.read<InvoiceProvider>();

    final created = await invoiceProvider.createInvoice(invoice);

    setState(() => _isSaving = false);

    if (created != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${created.invoiceNumber} issued'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              invoiceProvider.errorMessage ?? 'Failed to issue invoice',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  bool _validateForm() {
    if (_selectedCustomer == null) {
      _showError('Please select a customer');
      return false;
    }

    if (_billingNameController.text.isEmpty) {
      _showError('Billing name is required');
      return false;
    }

    if (_billingAddressController.text.isEmpty) {
      _showError('Billing address is required');
      return false;
    }

    if (_billingStateController.text.isEmpty) {
      _showError('Billing state is required');
      return false;
    }

    if (widget.order == null) {
      if (_items.isEmpty) {
        _showError('Please add at least one item');
        return false;
      }

      for (final item in _items) {
        if (item.itemDescription.isEmpty) {
          _showError('All items must have a description');
          return false;
        }
        if (item.quantity <= 0) {
          _showError('All items must have quantity > 0');
          return false;
        }
      }
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  Invoice _buildInvoice({required String status}) {
    return Invoice(
      invoiceNumber: _invoiceNumberController.text.isEmpty
          ? 'AUTO'
          : _invoiceNumberController.text,
      invoiceDate: _invoiceDate.toIso8601String().split('T')[0],
      customer: _selectedCustomer!.id!,
      order: widget.order?.id,
      status: status,
      billingName: _billingNameController.text,
      billingAddress: _billingAddressController.text,
      billingCity: _billingCityController.text,
      billingState: _billingStateController.text,
      billingPincode: _billingPincodeController.text,
      billingGstin: _billingGstinController.text,
      shippingName: _shippingNameController.text,
      shippingAddress: _shippingAddressController.text,
      shippingCity: _shippingCityController.text,
      shippingState: _shippingStateController.text,
      shippingPincode: _shippingPincodeController.text,
      taxType: _taxType,
      notes: _notesController.text,
      termsAndConditions: _termsController.text,
      items: widget.order == null ? _items : null,
    );
  }
}
