// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tailoring_web/core/layouts/main_layout.dart';
// import 'package:tailoring_web/core/theme/app_theme.dart';
// import '../providers/order_provider.dart';
// import '../models/order.dart';
// import 'create_order_screen.dart';
// import 'order_detail_screen.dart';

// /// Orders List Screen
// ///
// /// Shows all orders with filters and search
// /// Can be filtered by customer when navigating from customer detail
// class OrderListScreen extends StatefulWidget {
//   final int? customerId; // ✅ NEW: Accept customerId
//   final String? customerName; // ✅ NEW: Accept customerName

//   const OrderListScreen({super.key, this.customerId, this.customerName});

//   @override
//   State<OrderListScreen> createState() => _OrderListScreenState();
// }

// class _OrderListScreenState extends State<OrderListScreen> {
//   final _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<OrderProvider>().fetchOrders();

//       // ✅ NEW: Apply customer filter if provided
//       if (widget.customerId != null) {
//         context.read<OrderProvider>().setCustomerFilter(widget.customerId);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<OrderProvider>();

//     return MainLayout(
//       currentRoute: '/orders',
//       child: Column(
//         children: [
//           // ✅ NEW: Customer filter banner (if filtered by customer)
//           if (widget.customerId != null) _buildCustomerFilterBanner(),

//           // Header
//           Container(
//             padding: const EdgeInsets.all(AppTheme.space5),
//             decoration: const BoxDecoration(
//               color: AppTheme.backgroundWhite,
//               border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
//             ),
//             child: Row(
//               children: [
//                 const Text('Orders', style: AppTheme.heading2),
//                 const Spacer(),
//                 ElevatedButton.icon(
//                   onPressed: () => _navigateToCreateOrder(),
//                   icon: const Icon(Icons.add, size: 16),
//                   label: const Text('New Order'),
//                 ),
//               ],
//             ),
//           ),

//           // Filters
//           Container(
//             padding: const EdgeInsets.all(AppTheme.space4),
//             decoration: const BoxDecoration(
//               color: AppTheme.backgroundWhite,
//               border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
//             ),
//             child: Row(
//               children: [
//                 // Search
//                 Expanded(
//                   flex: 2,
//                   child: SizedBox(
//                     height: AppTheme.inputHeight,
//                     child: TextField(
//                       controller: _searchController,
//                       style: AppTheme.bodySmall,
//                       decoration: const InputDecoration(
//                         hintText: 'Search by order number or customer...',
//                         prefixIcon: Icon(Icons.search, size: 18),
//                       ),
//                       onChanged: (value) => provider.setSearchQuery(value),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: AppTheme.space3),

//                 // Status filter
//                 Container(
//                   height: AppTheme.inputHeight,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: AppTheme.space3,
//                   ),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: AppTheme.borderLight),
//                     borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: provider.filterStatus ?? 'ALL',
//                       style: AppTheme.bodySmall,
//                       isDense: true,
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'ALL',
//                           child: Text('All Status'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'PENDING',
//                           child: Text('Pending'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'IN_PROGRESS',
//                           child: Text('In Progress'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'COMPLETED',
//                           child: Text('Completed'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'CANCELLED',
//                           child: Text('Cancelled'),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         provider.setFilterStatus(value == 'ALL' ? null : value);
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Orders table
//           Expanded(
//             child: provider.isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : provider.filteredOrders.isEmpty
//                 ? _buildEmptyState()
//                 : _buildOrdersTable(provider),
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ NEW: Customer filter banner
//   Widget _buildCustomerFilterBanner() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       decoration: BoxDecoration(
//         color: AppTheme.primaryBlue.withOpacity(0.08),
//         border: Border(
//           bottom: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.filter_list, size: 20, color: AppTheme.primaryBlue),
//           const SizedBox(width: 12),
//           Expanded(
//             child: RichText(
//               text: TextSpan(
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: AppTheme.textPrimary,
//                 ),
//                 children: [
//                   const TextSpan(text: 'Showing orders for '),
//                   TextSpan(
//                     text: widget.customerName ?? 'Customer',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       color: AppTheme.primaryBlue,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Back to customer button
//           TextButton.icon(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.arrow_back, size: 16),
//             label: const Text('Back to Customer'),
//             style: TextButton.styleFrom(
//               foregroundColor: AppTheme.primaryBlue,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//           ),
//           const SizedBox(width: 8),
//           // Clear filter button
//           IconButton(
//             onPressed: () {
//               // Clear customer filter and show all orders
//               context.read<OrderProvider>().clearCustomerFilter();
//               Navigator.pushReplacementNamed(context, '/orders');
//             },
//             icon: const Icon(Icons.close, size: 18),
//             tooltip: 'Show all orders',
//             color: AppTheme.textSecondary,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.shopping_bag_outlined,
//             size: 64,
//             color: AppTheme.textMuted,
//           ),
//           const SizedBox(height: AppTheme.space4),
//           Text(
//             widget.customerId != null
//                 ? 'No orders found for this customer'
//                 : 'No orders found',
//             style: AppTheme.heading3.copyWith(color: AppTheme.textSecondary),
//           ),
//           const SizedBox(height: AppTheme.space2),
//           Text(
//             'Create your first order to get started',
//             style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
//           ),
//           const SizedBox(height: AppTheme.space5),
//           ElevatedButton.icon(
//             onPressed: () => _navigateToCreateOrder(),
//             icon: const Icon(Icons.add, size: 16),
//             label: const Text('New Order'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersTable(OrderProvider provider) {
//     return SingleChildScrollView(
//       child: Container(
//         margin: const EdgeInsets.all(AppTheme.space5),
//         decoration: BoxDecoration(
//           color: AppTheme.backgroundWhite,
//           border: Border.all(color: AppTheme.borderLight),
//           borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
//         ),
//         child: Column(
//           children: [
//             // Table header
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               color: AppTheme.backgroundGrey,
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Text('ORDER #', style: AppTheme.tableHeader),
//                   ),
//                   Expanded(
//                     flex: 3,
//                     child: Text('CUSTOMER', style: AppTheme.tableHeader),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text('ORDER DATE', style: AppTheme.tableHeader),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text('DELIVERY', style: AppTheme.tableHeader),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text('TOTAL', style: AppTheme.tableHeader),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text('PAID', style: AppTheme.tableHeader),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text('BALANCE', style: AppTheme.tableHeader),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text('STATUS', style: AppTheme.tableHeader),
//                   ),
//                 ],
//               ),
//             ),

//             // Table body
//             ...provider.filteredOrders.map((order) {
//               return _buildOrderRow(order, provider);
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderRow(Order order, OrderProvider provider) {
//     return Container(
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
//       ),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => OrderDetailScreen(orderId: order.id!),
//             ),
//           ).then((_) {
//             // Refresh list when returning
//             provider.fetchOrders();
//           });
//         },
//         hoverColor: AppTheme.backgroundGrey.withOpacity(0.5),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Row(
//             children: [
//               // Order Number
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   order.orderNumber,
//                   style: AppTheme.bodyMediumBold.copyWith(
//                     color: AppTheme.primaryBlue,
//                   ),
//                 ),
//               ),

//               // Customer
//               Expanded(
//                 flex: 3,
//                 child: Text(order.customerName, style: AppTheme.bodyMedium),
//               ),

//               // Order Date
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   order.formattedOrderDate,
//                   style: AppTheme.bodySmall,
//                 ),
//               ),

//               // Delivery Date
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   order.formattedDeliveryDate,
//                   style: AppTheme.bodySmall,
//                 ),
//               ),

//               // Total Amount
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   order.formattedTotal,
//                   style: AppTheme.bodyMediumBold,
//                 ),
//               ),

//               // Paid Amount
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   '₹${order.advancePaid.toStringAsFixed(2)}',
//                   style: AppTheme.bodySmall.copyWith(
//                     color: order.advancePaid > 0
//                         ? AppTheme.success
//                         : AppTheme.textSecondary,
//                   ),
//                 ),
//               ),

//               // Balance Amount
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   '₹${order.balance.toStringAsFixed(2)}',
//                   style: AppTheme.bodyMediumBold.copyWith(
//                     color: order.balance > 0
//                         ? AppTheme.warning
//                         : AppTheme.success,
//                   ),
//                 ),
//               ),

//               // Status
//               Expanded(flex: 2, child: _buildStatusBadge(order.status)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusBadge(String status) {
//     Color bgColor;
//     Color textColor;

//     switch (status.toUpperCase()) {
//       case 'PENDING':
//         bgColor = AppTheme.warning.withOpacity(0.1);
//         textColor = AppTheme.warning;
//         break;
//       case 'IN_PROGRESS':
//       case 'INPROGRESS':
//         bgColor = AppTheme.primaryBlue.withOpacity(0.1);
//         textColor = AppTheme.primaryBlue;
//         break;
//       case 'COMPLETED':
//         bgColor = AppTheme.success.withOpacity(0.1);
//         textColor = AppTheme.success;
//         break;
//       case 'CANCELLED':
//         bgColor = AppTheme.danger.withOpacity(0.1);
//         textColor = AppTheme.danger;
//         break;
//       default:
//         bgColor = AppTheme.textMuted.withOpacity(0.1);
//         textColor = AppTheme.textMuted;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         Order(
//           customerId: 0,
//           orderNumber: '',
//           orderDate: DateTime.now(),
//           status: status,
//           subtotal: 0,
//           totalTax: 0,
//           grandTotal: 0,
//         ).statusDisplay,
//         style: TextStyle(
//           color: textColor,
//           fontSize: 12,
//           fontWeight: FontWeight.w500,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   Future<void> _navigateToCreateOrder() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
//     );

//     if (result == true && mounted) {
//       context.read<OrderProvider>().refresh();
//     }
//   }
// }
