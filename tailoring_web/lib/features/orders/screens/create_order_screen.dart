// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tailoring_web/core/layouts/main_layout.dart';
// import 'package:tailoring_web/core/theme/app_theme.dart';
// import 'package:tailoring_web/features/customers/models/customer.dart';
// import 'package:tailoring_web/features/customers/providers/customer_provider.dart';
// // import 'package:tailoring_web/features/customers/providers/customer_detail_provider.dart';
// import 'package:tailoring_web/features/orders/models/order.dart';
// import 'package:tailoring_web/features/orders/models/order_item.dart';
// import 'package:tailoring_web/features/orders/providers/order_provider.dart';
// import 'package:tailoring_web/features/orders/widgets/customer_autocomplete.dart';
// import 'package:tailoring_web/features/orders/widgets/inline_order_items_table.dart';
// import 'package:tailoring_web/features/orders/widgets/reference_photos_picker.dart';

// class CreateOrderScreen extends StatefulWidget {
//   final Customer? preSelectedCustomer;

//   const CreateOrderScreen({super.key, this.preSelectedCustomer});

//   @override
//   State<CreateOrderScreen> createState() => _CreateOrderScreenState();
// }

// class _CreateOrderScreenState extends State<CreateOrderScreen> {
//   Customer? _selectedCustomer;
//   final List<OrderItem> _orderItems = [];
//   final List<ReferencePhotoData> _referencePhotos = [];
//   DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
//   String _priority = 'NORMAL';
//   bool _isTaxInclusive = false;
//   double _orderDiscountPercent = 0.0;

//   final _orderSummaryController = TextEditingController();
//   final _customerInstructionsController = TextEditingController();
//   final _orderDiscountController = TextEditingController(text: '0');

//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _selectedCustomer = widget.preSelectedCustomer;

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<CustomerProvider>().fetchCustomers();

//       // if (_selectedCustomer != null) {
//       //   context.read<CustomerDetailProvider>().fetchCustomerDetail(
//       //     _selectedCustomer!.id!,
//       //   );
//       // }
//     });
//   }

//   @override
//   void dispose() {
//     _orderSummaryController.dispose();
//     _customerInstructionsController.dispose();
//     _orderDiscountController.dispose();
//     super.dispose();
//   }

//   // --- HELPER METHODS ---

//   Future<void> _selectDeliveryDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _deliveryDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _deliveryDate) {
//       setState(() {
//         _deliveryDate = picked;
//       });
//     }
//   }

//   void _recalculateAllItems() {
//     if (_orderItems.isEmpty) return;

//     final updated = _orderItems.map((item) {
//       if (item.item == null) return item;
//       return item.recalculate(isTaxInclusive: _isTaxInclusive);
//     }).toList();

//     setState(() {
//       _orderItems.clear();
//       _orderItems.addAll(updated);
//     });
//   }

//   // --- BUILD METHODS ---

//   @override
//   Widget build(BuildContext context) {
//     return MainLayout(
//       currentRoute: '/orders',
//       child: Column(
//         children: [
//           _buildHeader(),
//           Expanded(child: _buildSplitLayout()),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(AppTheme.space5),
//       decoration: const BoxDecoration(
//         color: AppTheme.backgroundWhite,
//         border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const SizedBox(width: AppTheme.space3),
//           const Text('Create Order', style: AppTheme.heading2),
//           const Spacer(),
//           if (_isLoading)
//             const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSplitLayout() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           flex: 7,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(AppTheme.space5),
//             child: Column(
//               children: [
//                 _buildCustomerInline(),
//                 const SizedBox(height: AppTheme.space4),
//                 _buildOrderDetailsCompact(),
//                 const SizedBox(height: AppTheme.space4),
//                 _buildItemsSection(),
//                 const SizedBox(height: AppTheme.space4),
//                 _buildReferencePhotosSection(),
//                 const SizedBox(height: AppTheme.space4),
//                 _buildNotesSection(),
//               ],
//             ),
//           ),
//         ),
//         Container(
//           width: 380,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             border: const Border(left: BorderSide(color: AppTheme.borderLight)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: const Offset(-2, 0),
//               ),
//             ],
//           ),
//           child: _buildStickySummary(),
//         ),
//       ],
//     );
//   }

//   Widget _buildCustomerInline() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.backgroundWhite,
//         border: Border.all(color: AppTheme.borderLight),
//         borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.person, size: 20, color: AppTheme.primaryBlue),
//           const SizedBox(width: 12),
//           SizedBox(
//             width: 350,
//             child: CustomerAutocomplete(
//               initialCustomer: _selectedCustomer,
//               onCustomerSelected: (customer) {
//                 setState(() => _selectedCustomer = customer);
//                 if (customer != null) {
//                   context.read<CustomerDetailProvider>().fetchCustomerDetail(
//                     customer.id!,
//                   );
//                 }
//               },
//             ),
//           ),
//           const SizedBox(width: 16),
//           if (_selectedCustomer != null)
//             Expanded(
//               child: Consumer<CustomerDetailProvider>(
//                 builder: (context, detailProvider, child) {
//                   final hasMeasurements = detailProvider.familyMembers.any(
//                     (m) => m.relationship == 'SELF' && m.hasMeasurements,
//                   );

//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: hasMeasurements
//                           ? AppTheme.success.withOpacity(0.05)
//                           : AppTheme.warning.withOpacity(0.05),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: hasMeasurements
//                             ? AppTheme.success.withOpacity(0.3)
//                             : AppTheme.warning.withOpacity(0.3),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           hasMeasurements
//                               ? Icons.check_circle
//                               : Icons.warning_amber,
//                           size: 16,
//                           color: hasMeasurements
//                               ? AppTheme.success
//                               : AppTheme.warning,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             hasMeasurements
//                                 ? 'Measurements available'
//                                 : 'No measurements - Add before cutting',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: hasMeasurements
//                                   ? AppTheme.success
//                                   : AppTheme.warning,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderDetailsCompact() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.backgroundWhite,
//         border: Border.all(color: AppTheme.borderLight),
//         borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: InkWell(
//               onTap: _selectDeliveryDate,
//               child: InputDecorator(
//                 decoration: const InputDecoration(
//                   labelText: 'Delivery Date',
//                   prefixIcon: Icon(Icons.calendar_today, size: 18),
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 8,
//                   ),
//                 ),
//                 child: Text(
//                   '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
//                   style: AppTheme.bodySmall,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: DropdownButtonFormField<String>(
//               value: _priority,
//               decoration: const InputDecoration(
//                 labelText: 'Priority',
//                 prefixIcon: Icon(Icons.flag, size: 18),
//                 contentPadding: EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//               ),
//               style: AppTheme.bodySmall,
//               items: OrderPriority.all.map((p) {
//                 return DropdownMenuItem(
//                   value: p['value'],
//                   child: Text(p['label']!),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value != null) setState(() => _priority = value);
//               },
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Tax Type',
//                   style: AppTheme.bodySmall.copyWith(fontSize: 12),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     Expanded(child: _buildTaxTypeButton('Exclusive', false)),
//                     const SizedBox(width: 8),
//                     Expanded(child: _buildTaxTypeButton('Inclusive', true)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTaxTypeButton(String label, bool isInclusive) {
//     final isSelected = _isTaxInclusive == isInclusive;
//     return InkWell(
//       onTap: () {
//         setState(() {
//           _isTaxInclusive = isInclusive;
//           _recalculateAllItems(); // Trigger recalculation when type changes
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppTheme.primaryBlue.withOpacity(0.1)
//               : Colors.transparent,
//           border: Border.all(
//             color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
//           ),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildItemsSection() {
//     return InlineOrderItemsTable(
//       items: _orderItems,
//       isTaxInclusive: _isTaxInclusive,
//       onItemsChanged: (updatedItems) {
//         setState(() {
//           _orderItems.clear();
//           _orderItems.addAll(updatedItems);
//         });
//       },
//     );
//   }

//   Widget _buildReferencePhotosSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.backgroundWhite,
//         border: Border.all(color: AppTheme.borderLight),
//         borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
//       ),
//       child: ReferencePhotosPicker(
//         initialPhotos: _referencePhotos,
//         onPhotosChanged: (photos) {
//           setState(() {
//             _referencePhotos.clear();
//             _referencePhotos.addAll(photos);
//           });
//         },
//         maxPhotos: 5,
//       ),
//     );
//   }

//   Widget _buildNotesSection() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.backgroundWhite,
//         border: Border.all(color: AppTheme.borderLight),
//         borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
//       ),
//       child: Column(
//         children: [
//           TextField(
//             controller: _orderSummaryController,
//             decoration: const InputDecoration(
//               labelText: 'Order Summary (Internal)',
//             ),
//             maxLines: 2,
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _customerInstructionsController,
//             decoration: const InputDecoration(
//               labelText: 'Customer Instructions',
//             ),
//             maxLines: 2,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStickySummary() {
//     // 1. Raw Subtotal from items
//     final itemsSubtotal = _orderItems.fold<double>(
//       0,
//       (sum, item) => sum + item.baseAmount,
//     );

//     // 2. Item-level discounts
//     final itemDiscounts = _orderItems.fold<double>(
//       0,
//       (sum, item) => sum + item.itemDiscountAmount,
//     );

//     final afterItemDiscount = itemsSubtotal - itemDiscounts;

//     // 3. Apply Global Order Discount
//     final orderDiscountAmount =
//         afterItemDiscount * (_orderDiscountPercent / 100);

//     // 4. Final Aggregated Tax
//     // When global discount is applied, it reduces the taxable value proportionally.
//     final discountFactor = (afterItemDiscount > 0)
//         ? (afterItemDiscount - orderDiscountAmount) / afterItemDiscount
//         : 1.0;

//     final totalTax = _orderItems.fold<double>(
//       0,
//       (sum, item) => sum + (item.taxAmount * discountFactor),
//     );

//     final grandTotal =
//         (afterItemDiscount - orderDiscountAmount) +
//         (_isTaxInclusive ? 0 : totalTax);
//     final taxableValue = _isTaxInclusive
//         ? (grandTotal - totalTax)
//         : (afterItemDiscount - orderDiscountAmount);

//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: AppTheme.primaryBlue.withOpacity(0.1),
//             border: const Border(
//               bottom: BorderSide(color: AppTheme.borderLight),
//             ),
//           ),
//           child: const Row(
//             children: [
//               Icon(Icons.receipt_long, color: AppTheme.primaryBlue, size: 20),
//               SizedBox(width: 8),
//               Text('Order Summary', style: AppTheme.heading3),
//             ],
//           ),
//         ),
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_orderItems.isNotEmpty)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppTheme.primaryBlue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       '${_orderItems.length} ${_orderItems.length == 1 ? "Item" : "Items"}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: AppTheme.primaryBlue,
//                       ),
//                     ),
//                   ),
//                 const SizedBox(height: 20),
//                 _summaryRow('Subtotal', '₹${itemsSubtotal.toStringAsFixed(2)}'),
//                 if (itemDiscounts > 0)
//                   _summaryRow(
//                     'Item Discounts',
//                     '-₹${itemDiscounts.toStringAsFixed(2)}',
//                     color: AppTheme.success,
//                   ),
//                 const SizedBox(height: 20),
//                 TextField(
//                   controller: _orderDiscountController,
//                   decoration: InputDecoration(
//                     labelText: 'Order Discount %',
//                     prefixIcon: const Icon(Icons.percent, size: 18),
//                     filled: true,
//                     fillColor: AppTheme.backgroundWhite,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   keyboardType: TextInputType.number,
//                   onChanged: (value) => setState(
//                     () => _orderDiscountPercent = double.tryParse(value) ?? 0,
//                   ),
//                 ),
//                 if (orderDiscountAmount > 0)
//                   _summaryRow(
//                     'Order Discount',
//                     '-₹${orderDiscountAmount.toStringAsFixed(2)}',
//                     color: AppTheme.success,
//                   ),
//                 const Divider(height: 32, thickness: 1),
//                 _summaryRow(
//                   _isTaxInclusive ? 'Taxable Value' : 'After Discount',
//                   '₹${taxableValue.toStringAsFixed(2)}',
//                 ),
//                 const SizedBox(height: 8),
//                 _summaryRow('Tax (GST)', '₹${totalTax.toStringAsFixed(2)}'),
//                 const Divider(height: 32, thickness: 2),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: AppTheme.primaryBlue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: AppTheme.primaryBlue, width: 2),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'GRAND TOTAL',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: AppTheme.primaryBlue,
//                         ),
//                       ),
//                       Text(
//                         '₹${grandTotal.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                           color: AppTheme.primaryBlue,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.all(20),
//           decoration: const BoxDecoration(
//             color: AppTheme.backgroundWhite,
//             border: Border(top: BorderSide(color: AppTheme.borderLight)),
//           ),
//           child: Column(
//             children: [
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: (_selectedCustomer == null || _orderItems.isEmpty)
//                       ? null
//                       : _saveOrder,
//                   icon: const Icon(Icons.save),
//                   label: const Text('Create Order'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _summaryRow(String label, String value, {Color? color}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: AppTheme.bodySmall.copyWith(
//             color: color ?? AppTheme.textSecondary,
//           ),
//         ),
//         Text(
//           value,
//           style: AppTheme.bodyMedium.copyWith(
//             color: color ?? AppTheme.textPrimary,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _saveOrder() async {
//     if (_selectedCustomer == null || _orderItems.isEmpty) return;
//     setState(() => _isLoading = true);

//     try {
//       final itemsSubtotal = _orderItems.fold<double>(
//         0,
//         (sum, item) => sum + item.baseAmount,
//       );
//       final itemDiscounts = _orderItems.fold<double>(
//         0,
//         (sum, item) => sum + item.itemDiscountAmount,
//       );
//       final afterItemDiscount = itemsSubtotal - itemDiscounts;
//       final orderDiscountAmount =
//           afterItemDiscount * (_orderDiscountPercent / 100);

//       final discountFactor = (afterItemDiscount > 0)
//           ? (afterItemDiscount - orderDiscountAmount) / afterItemDiscount
//           : 1.0;

//       final totalTax = _orderItems.fold<double>(
//         0,
//         (sum, item) => sum + (item.taxAmount * discountFactor),
//       );

//       final grandTotal =
//           (afterItemDiscount - orderDiscountAmount) +
//           (_isTaxInclusive ? 0 : totalTax);

//       final detailProvider = context.read<CustomerDetailProvider>();

//       final order = Order(
//         customerId: _selectedCustomer!.id!,
//         orderNumber: '',
//         orderDate: DateTime.now(),
//         plannedDeliveryDate: _deliveryDate,
//         status: OrderStatus.pending,
//         priority: _priority,
//         subtotal: itemsSubtotal,
//         orderDiscountPercentage: _orderDiscountPercent,
//         orderDiscountAmount: orderDiscountAmount,
//         totalDiscount: itemDiscounts + orderDiscountAmount,
//         totalTax: totalTax,
//         grandTotal: grandTotal,
//         advancePaid: 0,
//         balance: grandTotal,
//         orderSummary: _orderSummaryController.text,
//         customerInstructions: _customerInstructionsController.text,
//         items: _orderItems,
//       );

//       final createdOrder = await context.read<OrderProvider>().createOrder(
//         order,
//         referencePhotos: _referencePhotos.isNotEmpty ? _referencePhotos : null,
//       );

//       if (createdOrder != null && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Order ${createdOrder.orderNumber ?? "created"} successfully!',
//             ),
//             backgroundColor: AppTheme.success,
//           ),
//         );
//         Navigator.pop(context, true);
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
// }
