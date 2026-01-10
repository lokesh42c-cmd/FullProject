import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layouts/main_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../widgets/order_status_badge.dart';

/// Order Detail Screen
/// View and edit order details with QR code display
class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  Order? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await context.read<OrderProvider>().fetchOrderById(
      widget.orderId,
    );
    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  Future<void> _toggleLock() async {
    if (_order == null) return;

    final success = _order!.isLocked
        ? await context.read<OrderProvider>().unlockOrder(_order!.id!)
        : await context.read<OrderProvider>().lockOrder(_order!.id!);

    if (success) {
      _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_order!.isLocked ? 'Order unlocked' : 'Order locked'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/orders',
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _order == null
                ? _buildErrorState()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
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
          const SizedBox(width: AppTheme.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Details', style: AppTheme.heading2),
              if (_order != null)
                Text(
                  _order!.orderNumber,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (_order != null) ...[
            if (_order!.isLocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock, size: 16, color: AppTheme.warning),
                    SizedBox(width: 6),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                _order!.isLocked ? Icons.lock_open : Icons.lock,
                color: AppTheme.textSecondary,
              ),
              onPressed: _toggleLock,
              tooltip: _order!.isLocked ? 'Unlock Order' : 'Lock Order',
            ),
          ],
        ],
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
          const Text('Order not found', style: AppTheme.heading3),
          const SizedBox(height: 8),
          Text(
            'The order you are looking for does not exist',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildCustomerCard(),
                    const SizedBox(height: AppTheme.space4),
                    _buildOrderInfoCard(),
                    const SizedBox(height: AppTheme.space4),
                    _buildItemsCard(),
                    const SizedBox(height: AppTheme.space4),
                    _buildNotesCard(),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  children: [
                    if (_order!.qrCode != null) _buildQRCodeCard(),
                    const SizedBox(height: AppTheme.space4),
                    _buildStatusCard(),
                    const SizedBox(height: AppTheme.space4),
                    _buildTotalsCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
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
            children: [
              const Icon(Icons.person, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Customer Details',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Name', _order!.customerName ?? 'N/A'),
          _infoRow('Phone', _order!.customerPhone ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
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
            children: [
              const Icon(
                Icons.calendar_today,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Information',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Order Date', _order!.formattedOrderDate),
          _infoRow('Expected Delivery', _order!.formattedExpectedDeliveryDate),
          if (_order!.actualDeliveryDate != null)
            _infoRow(
              'Actual Delivery',
              '${_order!.actualDeliveryDate!.day.toString().padLeft(2, '0')}-${_order!.actualDeliveryDate!.month.toString().padLeft(2, '0')}-${_order!.actualDeliveryDate!.year}',
            ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
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
            children: [
              const Icon(
                Icons.shopping_cart,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Items',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_order!.items.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemDescription,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: AppTheme.fontSemibold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity.toStringAsFixed(2)} × ₹${item.unitPrice.toStringAsFixed(2)}',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: AppTheme.bodyMediumBold,
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    if (_order!.orderSummary == null && _order!.customerInstructions == null) {
      return const SizedBox.shrink();
    }

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
            children: [
              const Icon(Icons.note, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_order!.orderSummary != null) ...[
            Text(
              'Order Summary:',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: AppTheme.fontSemibold,
              ),
            ),
            const SizedBox(height: 4),
            Text(_order!.orderSummary!, style: AppTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          if (_order!.customerInstructions != null) ...[
            Text(
              'Customer Instructions:',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: AppTheme.fontSemibold,
              ),
            ),
            const SizedBox(height: 4),
            Text(_order!.customerInstructions!, style: AppTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          Text(
            'Order QR Code',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: AppTheme.fontSemibold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Image.network(
              _order!.qrCode!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.qr_code,
                    size: 48,
                    color: AppTheme.textMuted,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
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
          Text(
            'Status',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: AppTheme.fontSemibold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Status:', style: AppTheme.bodySmall),
              OrderStatusBadge(status: _order!.orderStatus),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Status:', style: AppTheme.bodySmall),
              OrderStatusBadge(
                status: _order!.deliveryStatus,
                isDeliveryStatus: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
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
          Text(
            'Order Total',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: AppTheme.fontSemibold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Total:', style: AppTheme.bodySmall),
              Text(
                '₹${_order!.estimatedTotal.toStringAsFixed(2)}',
                style: AppTheme.bodyMediumBold,
              ),
            ],
          ),
          if (_order!.totalPaid != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Paid:', style: AppTheme.bodySmall),
                Text(
                  '₹${_order!.totalPaid!.toStringAsFixed(2)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.success,
                    fontWeight: AppTheme.fontSemibold,
                  ),
                ),
              ],
            ),
          ],
          if (_order!.remainingBalance != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance:', style: AppTheme.bodySmall),
                Text(
                  '₹${_order!.remainingBalance!.toStringAsFixed(2)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.warning,
                    fontWeight: AppTheme.fontSemibold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: AppTheme.bodyMedium)),
        ],
      ),
    );
  }
}
