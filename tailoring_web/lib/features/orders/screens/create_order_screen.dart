import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layouts/main_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/order_provider.dart';
import '../../items/providers/item_provider.dart';
import '../../customers/models/customer.dart';
import '../widgets/customer_autocomplete.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../widgets/order_items_table.dart';
import '../widgets/order_summary_panel.dart';
import '../widgets/reference_photos_section.dart';

class CreateOrderScreen extends StatefulWidget {
  final Customer? preSelectedCustomer;
  const CreateOrderScreen({super.key, this.preSelectedCustomer});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  Customer? _selectedCustomer;
  final List<OrderItem> _orderItems = [];
  final List<ReferencePhotoData> _referencePhotos = [];
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 7));
  bool _isTaxInclusive = false;
  bool _isLoading = false;

  final _orderSummaryController = TextEditingController();
  final _customerInstructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _orderSummaryController.dispose();
    _customerInstructionsController.dispose();
    super.dispose();
  }

  // FIX 2: Standardized Calculation Logic for Table & Summary
  void _onTaxModeChanged(bool isTaxInclusive) {
    setState(() {
      _isTaxInclusive = isTaxInclusive;
    });
  }

  Future<void> _saveOrder() async {
    if (_selectedCustomer == null || _orderItems.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      double totalTax = 0.0;
      double grandTotal = 0.0;
      double subtotal = 0.0;

      for (var item in _orderItems) {
        double lineNet = (item.quantity * item.unitPrice) - item.discount;
        if (_isTaxInclusive) {
          double base = lineNet / (1 + (item.taxAmount / 100));
          subtotal += base;
          totalTax += (lineNet - base);
          grandTotal += lineNet;
        } else {
          double tax = lineNet * (item.taxAmount / 100);
          subtotal += lineNet;
          totalTax += tax;
          grandTotal += (lineNet + tax);
        }
      }

      final order = Order(
        orderNumber: '',
        customerId: _selectedCustomer!.id!,
        orderDate: DateTime.now(),
        expectedDeliveryDate: _expectedDeliveryDate,
        orderStatus: 'PENDING',
        deliveryStatus: 'NOT_STARTED',
        estimatedTotal: grandTotal,
        orderSummary: _orderSummaryController.text,
        customerInstructions: _customerInstructionsController.text,
        items: _orderItems,
      );

      final createdOrder = await context.read<OrderProvider>().createOrder(
        order,
      );
      if (createdOrder != null && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/orders',
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildSplitLayout()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space2,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppTheme.space2),
          const Text('New Order', style: AppTheme.heading3),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Column(
              children: [
                _buildTopInfoBar(),
                const SizedBox(height: AppTheme.space4),
                _buildItemsSection(),
                const SizedBox(height: AppTheme.space4),
                ReferencePhotosSection(
                  photos: _referencePhotos,
                  onPhotosChanged: (photos) => setState(() {
                    _referencePhotos.clear();
                    _referencePhotos.addAll(photos);
                  }),
                ),
                const SizedBox(height: AppTheme.space4),
                _buildNotesSection(),
              ],
            ),
          ),
        ),
        // FIX 3: Unified naming via OrderSummaryPanel
        OrderSummaryPanel(
          items: _orderItems,
          isTaxInclusive: _isTaxInclusive,
          onTaxModeChanged: (_) {},
          onCreateOrder: _saveOrder,
          onCancel: () => Navigator.pop(context),
          isLoading: _isLoading,
          canCreate: _selectedCustomer != null && _orderItems.isNotEmpty,
          showTaxToggle: false,
        ),
      ],
    );
  }

  Widget _buildTopInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Search',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomerAutocomplete(
                      initialCustomer: _selectedCustomer,
                      onCustomerSelected: (customer) =>
                          setState(() => _selectedCustomer = customer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGrey,
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedCustomer?.phone ?? '---',
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expected Delivery',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expectedDeliveryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null)
                          setState(() => _expectedDeliveryDate = picked);
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_expectedDeliveryDate.day}/${_expectedDeliveryDate.month}/${_expectedDeliveryDate.year}',
                              style: AppTheme.bodyMedium,
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedCustomer != null &&
              !(_selectedCustomer!.hasMeasurements ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'No measurements found.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/customers/${_selectedCustomer!.id}',
                    ),
                    child: const Text(
                      'Add in Customer Profile →',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  'Order Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildTaxRadioSelector(),
              ],
            ),
          ),
          OrderItemsTable(
            items: _orderItems,
            onItemsChanged: (items) => setState(() {
              _orderItems.clear();
              _orderItems.addAll(items);
              // Requirement 1 & 2: The table widget should handle internal search clearing
            }),
            isTaxInclusive: _isTaxInclusive,
          ),
        ],
      ),
    );
  }

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

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          TextField(
            controller: _orderSummaryController,
            decoration: const InputDecoration(
              labelText: 'Internal Order Summary',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customerInstructionsController,
            decoration: const InputDecoration(
              labelText: 'Customer Instructions',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
