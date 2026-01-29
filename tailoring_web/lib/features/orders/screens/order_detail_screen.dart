import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../../../core/layouts/main_layout.dart';
import 'order_detail_tabs/overview_tab.dart';
import 'order_detail_tabs/items_and_payments_tab.dart';
import 'order_detail_tabs/measurements_tab.dart';
import '../widgets/print_internal_dialog.dart';
import '../widgets/print_workshop_dialog.dart';

import '../../invoices/widgets/dialogs/create_invoice_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();

  late TabController _tabController;
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get('orders/orders/${widget.orderId}/');
      setState(() {
        _orderData = response.data;
        print('Order Data: $_orderData');
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load order details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/orders',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: AppTheme.heading2.copyWith(color: AppTheme.danger),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final orderNumber = _orderData!['order_number'] ?? 'N/A';
    final isLocked = _orderData!['is_locked'] ?? false;
    final isVoid = _orderData!['is_void'] ?? false;

    return Column(
      children: [
        // Header with Back Button and Order Number
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  const Text('Order Details', style: AppTheme.heading2),
                  Text(
                    orderNumber,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 16, color: AppTheme.warning),
                      const SizedBox(width: 6),
                      Text(
                        'Locked',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isVoid) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block, size: 16, color: AppTheme.danger),
                      const SizedBox(width: 6),
                      Text(
                        'CANCELLED',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Action Buttons Row - Back left, Actions right
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              // Left: Back button
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Orders'),
              ),
              const Spacer(),
              // Right: Action buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    icon: Icons.print,
                    label: 'Print - Internal',
                    onPressed: _onPrintCustomerCopy,
                  ),
                  _buildActionButton(
                    icon: Icons.precision_manufacturing,
                    label: 'Print - Workshop',
                    onPressed: _onPrintWorkshopCopy,
                  ),
                  // ✅ FIXED: Show "Create Invoice" or "View Invoice"
                  _buildActionButton(
                    icon: _orderData!['invoice_id'] != null
                        ? Icons.visibility
                        : Icons.receipt_long,
                    label: _orderData!['invoice_id'] != null
                        ? 'View Invoice'
                        : 'Create Invoice',
                    onPressed: _orderData!['invoice_id'] != null
                        ? _onViewInvoice
                        : _onCreateInvoice,
                    isPrimary: true,
                  ),
                  if (!isVoid)
                    _buildActionButton(
                      icon: Icons.block,
                      label: 'Cancel Order',
                      onPressed: _onCancelOrder,
                      isDanger: true,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Cancel Banner
        if (isVoid)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.danger.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 20,
                  color: AppTheme.danger,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This order has been cancelled and cannot be modified.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Lock Banner
        if (isLocked && !isVoid)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.warning.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This order is locked because an invoice has been created.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryBlue,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Items & Payments'),
              Tab(text: 'Measurements'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(
                orderData: _orderData!,
                isLocked: isLocked,
                onRefresh: _loadOrderDetails,
              ),
              ItemsAndPaymentsTab(
                orderData: _orderData!,
                onUpdate: _loadOrderDetails,
              ),
              MeasurementsTab(orderData: _orderData!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDanger
            ? AppTheme.danger
            : isPrimary
            ? AppTheme.primaryBlue
            : Colors.white,
        foregroundColor: isDanger || isPrimary
            ? Colors.white
            : AppTheme.textPrimary,
        elevation: isDanger || isPrimary ? 2 : 0,
        side: isDanger || isPrimary
            ? null
            : const BorderSide(color: AppTheme.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _onPrintCustomerCopy() {
    showDialog(
      context: context,
      builder: (context) => PrintInternalDialog(orderData: _orderData!),
    );
  }

  void _onPrintWorkshopCopy() {
    showDialog(
      context: context,
      builder: (context) => PrintWorkshopDialog(orderData: _orderData!),
    );
  }

  void _onCreateInvoice() async {
    final orderStatus = _orderData!['order_status'];

    // Allow invoice creation for CONFIRMED, IN_PROGRESS, READY, COMPLETED
    if (orderStatus != 'CONFIRMED' &&
        orderStatus != 'IN_PROGRESS' &&
        orderStatus != 'READY' &&
        orderStatus != 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order must be confirmed or in progress to create invoice. Current status: ${_orderData!['order_status_display']}',
          ),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Check if invoice already exists
    if (_orderData!['invoice_id'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice already exists for this order'),
          backgroundColor: AppTheme.info,
        ),
      );
      return;
    }

    // Show create invoice dialog
    final invoiceId = await showDialog<int>(
      context: context,
      builder: (context) => CreateInvoiceDialog(
        orderId: widget.orderId,
        customerId: _orderData!['customer'],
      ),
    );

    if (invoiceId != null && mounted) {
      // Reload order to show locked state
      await _loadOrderDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invoice created successfully!'),
          backgroundColor: AppTheme.success,
          action: SnackBarAction(
            label: 'View Invoice',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/invoices/$invoiceId');
            },
          ),
        ),
      );
    }
  }

  void _onViewInvoice() {
    final invoiceId = _orderData!['invoice_id'];
    if (invoiceId != null) {
      Navigator.pushNamed(context, '/invoices/$invoiceId');
    }
  }

  void _onCancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.patch(
        'orders/orders/${widget.orderId}/',
        data: {'is_void': true},
      );

      await _loadOrderDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}
