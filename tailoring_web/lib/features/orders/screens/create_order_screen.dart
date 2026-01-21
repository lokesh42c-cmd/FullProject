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
import 'order_detail_screen.dart';

/// Create Order Screen - Final Version
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

  void _onTaxModeChanged(bool isTaxInclusive) {
    setState(() {
      _isTaxInclusive = isTaxInclusive;
    });
  }

  Future<void> _saveOrder() async {
    if (_selectedCustomer == null || _orderItems.isEmpty) return;

    print('🟢 [ORDER CREATION] Starting order creation...');
    print('📝 Customer ID: ${_selectedCustomer!.id}');
    print('📝 Items count: ${_orderItems.length}');

    setState(() => _isLoading = true);

    try {
      double grandTotal = 0.0;
      for (var item in _orderItems) {
        double lineNet = (item.quantity * item.unitPrice) - item.discount;
        if (_isTaxInclusive) {
          grandTotal += lineNet;
        } else {
          double tax = lineNet * (item.taxPercentage / 100);
          grandTotal += (lineNet + tax);
        }
        print('📦 Item: ${item.itemDescription}, Total: $grandTotal');
      }

      print('💰 Grand Total calculated: $grandTotal');

      final order = Order(
        // ✅ FIX #2: Removed orderNumber - backend generates it
        customerId: _selectedCustomer!.id!,
        orderDate: DateTime.now(),
        expectedDeliveryDate: _expectedDeliveryDate,
        orderStatus: 'DRAFT',
        deliveryStatus: 'NOT_STARTED',
        estimatedTotal: grandTotal,
        orderSummary: _orderSummaryController.text,
        customerInstructions: _customerInstructionsController.text,
        items: _orderItems,
      );

      print('📤 Sending order to backend...');
      final createdOrder = await context.read<OrderProvider>().createOrder(
        order,
      );

      print('📥 Response received from backend');

      if (createdOrder != null) {
        print('✅ Order created successfully!');
        print('📋 Order ID: ${createdOrder.id}');
        print(
          '📋 Order Number: ${createdOrder.orderNumber ?? "NOT GENERATED"}',
        );
        print('💰 Order Total: ${createdOrder.estimatedTotal}');

        // Upload reference photos if any (web compatible - uses bytes)
        if (_referencePhotos.isNotEmpty && createdOrder.id != null) {
          print('📸 Uploading ${_referencePhotos.length} photos...');
          for (final photo in _referencePhotos) {
            if (photo.imageBytes != null) {
              print('📸 Uploading photo: ${photo.fileName}');
              await context.read<OrderProvider>().uploadReferencePhoto(
                createdOrder.id!,
                photo.imageBytes!,
                photo.fileName ?? 'photo.jpg',
              );
            }
          }
          print('✅ All photos uploaded');
        }

        if (mounted) {
          print('🚀 Navigating to order detail screen...');
          // Navigate to order detail screen
          try {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OrderDetailScreen(orderId: createdOrder.id!),
              ),
            );
            print('✅ Navigation completed');
          } catch (e) {
            print('❌ Navigation error: $e');
            print('📍 Error type: ${e.runtimeType}');
            // If navigation fails, show success and go back
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order created: Check orders list'),
                  backgroundColor: AppTheme.success,
                  duration: const Duration(seconds: 3),
                ),
              );
              Navigator.pop(context, true);
            }
          }
        }
      } else {
        print('❌ Order creation returned null');
        print('❌ Error message: ${context.read<OrderProvider>().errorMessage}');
        // Show error if creation failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<OrderProvider>().errorMessage ??
                    'Failed to create order',
              ),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION during order creation: $e');
      print('📍 Exception type: ${e.runtimeType}');
      print('📚 Stack trace: $stackTrace');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print('🏁 Order creation process completed');
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
                ReferencePhotosPicker(
                  initialPhotos: _referencePhotos,
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
              SizedBox(
                width: 180,
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
                            Flexible(
                              child: Text(
                                '${_expectedDeliveryDate.day}/${_expectedDeliveryDate.month}/${_expectedDeliveryDate.year}',
                                style: AppTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                  Flexible(
                    child: Text(
                      'No measurements found. ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/customers/${_selectedCustomer!.id}',
                    ),
                    child: const Text(
                      'Add Now →',
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
