import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../../../core/layouts/main_layout.dart';
import 'order_detail_tabs/overview_tab.dart';
import 'order_detail_tabs/items_and_payments_tab.dart';
import 'order_detail_tabs/measurements_tab.dart';

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
                        'VOID',
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

        // Action Buttons Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.print,
                label: 'Print (Customer)',
                onPressed: _onPrintCustomerCopy,
              ),
              _buildActionButton(
                icon: Icons.precision_manufacturing,
                label: 'Print (Workshop)',
                onPressed: _onPrintWorkshopCopy,
              ),
              _buildActionButton(
                icon: Icons.receipt_long,
                label: 'Create Invoice',
                onPressed: _onCreateInvoice,
                isPrimary: true,
              ),
              if (!isVoid)
                _buildActionButton(
                  icon: Icons.block,
                  label: 'Void Order',
                  onPressed: _onVoidOrder,
                  isDanger: true,
                ),
            ],
          ),
        ),

        // Void Banner
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This order has been voided',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_orderData!['void_reason'] != null)
                        Text(
                          'Reason: ${_orderData!['void_reason']}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.danger,
                          ),
                        ),
                    ],
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
                    'This order is locked. Some actions are disabled.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.warning,
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
            indicatorWeight: 3,
            labelStyle: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
                isLocked: isLocked || isVoid,
                onRefresh: _loadOrderDetails,
              ),
              ItemsAndPaymentsTab(
                orderData: _orderData!,
                isLocked: isLocked || isVoid,
                onRefresh: _loadOrderDetails,
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
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDanger
            ? AppTheme.danger
            : isPrimary
            ? AppTheme.primaryBlue
            : Colors.white,
        foregroundColor: isDanger
            ? Colors.white
            : isPrimary
            ? Colors.white
            : AppTheme.textPrimary,
        elevation: isPrimary || isDanger ? 2 : 0,
        side: !isPrimary && !isDanger
            ? const BorderSide(color: AppTheme.borderLight)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _onPrintCustomerCopy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print Customer Copy - To be implemented')),
    );
  }

  void _onPrintWorkshopCopy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print Workshop Copy - To be implemented')),
    );
  }

  void _onCreateInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Invoice - To be implemented')),
    );
  }

  void _onVoidOrder() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to void this order?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action will mark the order as void but keep it in the system for record-keeping.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for voiding (required)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Customer cancelled, Incorrect order',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for voiding'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              // TODO: Implement void order API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Void Order API - To be implemented'),
                  backgroundColor: AppTheme.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Void Order'),
          ),
        ],
      ),
    );
  }
}
