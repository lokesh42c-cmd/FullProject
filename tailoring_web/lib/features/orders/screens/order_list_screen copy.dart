import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layouts/main_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../widgets/order_status_badge.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

/// Order List Screen
/// Shows all orders with filters and search
class OrderListScreen extends StatefulWidget {
  final int? customerId;
  final String? customerName;

  const OrderListScreen({super.key, this.customerId, this.customerName});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      if (widget.customerId != null) {
        provider.setFilterCustomerId(widget.customerId);
      }
      provider.fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return MainLayout(
      currentRoute: '/orders',
      child: Column(
        children: [
          // Customer filter banner
          if (widget.customerId != null) _buildCustomerFilterBanner(),

          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Text('Orders', style: AppTheme.heading2),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateOrder(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Order'),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: AppTheme.inputHeight,
                    child: TextField(
                      controller: _searchController,
                      style: AppTheme.bodySmall,
                      decoration: const InputDecoration(
                        hintText: 'Search by order number or customer...',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                      onChanged: (value) => provider.setSearchQuery(value),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),

                // Order Status filter
                Container(
                  height: AppTheme.inputHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.filterOrderStatus ?? 'ALL',
                      style: AppTheme.bodySmall,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                        DropdownMenuItem(
                          value: 'CONFIRMED',
                          child: Text('Confirmed'),
                        ),
                        DropdownMenuItem(
                          value: 'IN_PROGRESS',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(value: 'READY', child: Text('Ready')),
                        DropdownMenuItem(
                          value: 'COMPLETED',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'CANCELLED',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        provider.setFilterOrderStatus(
                          value == 'ALL' ? null : value,
                        );
                        provider.fetchOrders();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders table
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersTable(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerFilterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'Showing orders for '),
                  TextSpan(
                    text: widget.customerName ?? 'Customer',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to Customer'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              context.read<OrderProvider>().clearCustomerFilter();
              Navigator.pushReplacementNamed(context, '/orders');
            },
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Show all orders',
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            widget.customerId != null
                ? 'No orders found for this customer'
                : 'No orders found',
            style: AppTheme.heading3.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            'Create your first order to get started',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.space5),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateOrder(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(OrderProvider provider) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.backgroundGrey,
              child: Row(
                children: const [
                  Expanded(
                    flex: 2,
                    child: Text('ORDER #', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('CUSTOMER', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('ORDER DATE', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('DELIVERY', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('TOTAL', style: AppTheme.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('STATUS', style: AppTheme.tableHeader),
                  ),
                ],
              ),
            ),

            // Table body
            ...provider.filteredOrders.map((order) {
              return _buildOrderRow(order, provider);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(Order order, OrderProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: order.id!),
            ),
          ).then((_) {
            provider.fetchOrders();
          });
        },
        hoverColor: AppTheme.backgroundGrey.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Order Number
              Expanded(
                flex: 2,
                child: Text(
                  order.orderNumber ?? 'N/A',
                  style: AppTheme.bodyMediumBold.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),

              // Customer
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName ?? 'N/A',
                      style: AppTheme.bodyMedium,
                    ),
                    if (order.customerPhone != null)
                      Text(order.customerPhone!, style: AppTheme.bodySmall),
                  ],
                ),
              ),

              // Order Date
              Expanded(
                flex: 2,
                child: Text(
                  order.formattedOrderDate,
                  style: AppTheme.bodySmall,
                ),
              ),

              // Delivery Date
              Expanded(
                flex: 2,
                child: Text(
                  order.formattedExpectedDeliveryDate,
                  style: AppTheme.bodySmall.copyWith(
                    color: order.isOverdue
                        ? AppTheme.danger
                        : AppTheme.textPrimary,
                  ),
                ),
              ),

              // Total Amount
              Expanded(
                flex: 2,
                child: Text(
                  '₹${order.estimatedTotal.toStringAsFixed(2)}',
                  style: AppTheme.bodyMediumBold,
                ),
              ),

              // Status
              Expanded(
                flex: 2,
                child: OrderStatusBadge(status: order.orderStatus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreateOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
    );

    if (result == true && mounted) {
      context.read<OrderProvider>().refresh();
    }
  }
}
