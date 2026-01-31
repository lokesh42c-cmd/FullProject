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

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Orders'),
              ),
              const Spacer(),
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
                      isDangerous: true,
                    ),
                ],
              ),
            ],
          ),
        ),

        if (_orderData!['invoice_id'] != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This order is locked because an invoice has been created.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Items & Payments'),
              Tab(text: 'Measurements'),
            ],
          ),
        ),

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
    bool isDangerous = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDangerous ? AppTheme.danger : null,
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

  // ✅ FIXED: Use correct parameters for CreateInvoiceDialog
  void _onCreateInvoice() async {
    final orderStatus = _orderData!['order_status'];

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

    if (_orderData!['invoice_id'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice already exists for this order'),
          backgroundColor: AppTheme.info,
        ),
      );
      return;
    }

    // ✅ FIXED: Use orderId and customerId parameters
    final invoiceId = await showDialog<int>(
      context: context,
      builder: (context) => CreateInvoiceDialog(
        orderId: widget.orderId,
        customerId: _orderData!['customer'],
      ),
    );

    if (invoiceId != null && mounted) {
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

  // ✅ NEW: Cancel Order with Invoice Check
  void _onCancelOrder() async {
    final hasInvoice = _orderData!['invoice_id'] != null;

    if (hasInvoice) {
      _showCancelOptionsDialog();
    } else {
      _showSimpleCancelDialog();
    }
  }

  // ✅ NEW: Simple cancel (no invoice)
  void _showSimpleCancelDialog() async {
    final reason = await _showReasonDialog('Cancel Order');
    if (reason == null) return;

    try {
      await _apiClient.post(
        'orders/orders/${widget.orderId}/cancel/',
        data: {'reason': reason},
      );

      if (mounted) {
        Navigator.pop(context);
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

  // ✅ NEW: 3-option dialog (has invoice)
  void _showCancelOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This order has invoice ${_orderData!['invoice_number']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('What would you like to do?'),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelInvoiceOnly();
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Cancel Invoice Only'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Cancel invoice and keep the order',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelBoth();
                },
                icon: const Icon(Icons.block),
                label: const Text('Cancel Both'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Cancel both invoice and order',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Cancel invoice only
  void _cancelInvoiceOnly() async {
    final reason = await _showReasonDialog('Cancel Invoice');
    if (reason == null) return;

    try {
      await _apiClient.post(
        'invoicing/invoices/${_orderData!['invoice_id']}/cancel/',
        data: {'reason': reason},
      );

      await _loadOrderDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invoice cancelled successfully. Order is now unlocked.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  // ✅ NEW: Cancel both
  void _cancelBoth() async {
    final reason = await _showReasonDialog('Cancel Invoice & Order');
    if (reason == null) return;

    try {
      // Cancel invoice first
      await _apiClient.post(
        'invoicing/invoices/${_orderData!['invoice_id']}/cancel/',
        data: {'reason': reason},
      );

      // Then cancel order
      await _apiClient.post(
        'orders/orders/${widget.orderId}/cancel/',
        data: {'reason': reason},
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice and order cancelled successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  // ✅ NEW: Reason dialog
  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️ This action cannot be undone.'),
              const SizedBox(height: 16),
              const Text(
                'Please provide a reason for cancellation:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason...',
                  helperText: '* Required',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reason is required'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }
}
