import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/orders/widgets/measurement_display_widget.dart';
import 'package:tailoring_web/features/customer_payments/widgets/order_payments_tab.dart';
import 'package:tailoring_web/features/customer_payments/providers/payment_provider.dart';
import 'package:tailoring_web/features/customer_payments/services/payment_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrderDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetail() async {
    setState(() => _isLoading = true);

    final provider = context.read<OrderProvider>();
    final order = await provider.getOrderDetail(widget.orderId);

    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/orders',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text('Order not found', style: AppTheme.heading3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F9FA),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrderDetailsTab(),
                        _buildPaymentsTab(),
                        _buildMeasurementsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: AppTheme.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Text(
            _order?.orderNumber ?? 'Order Details',
            style: AppTheme.heading2,
          ),
          const SizedBox(width: 12),
          _buildStatusBadge(_order?.status ?? 'PENDING'),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Edit Order'),
          ),
          const SizedBox(width: 8),
          _buildPrintMenu(),
        ],
      ),
    );
  }

  Widget _buildPrintMenu() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print, size: 16, color: AppTheme.textSecondary),
            SizedBox(width: 8),
            Text('Print', style: AppTheme.bodySmall),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'internal', child: Text('Internal Report')),
        const PopupMenuItem(value: 'workshop', child: Text('Work Order')),
      ],
      onSelected: (value) {
        if (value == 'internal') _printInternalReport();
        if (value == 'workshop') _printWorkOrder();
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryBlue,
        tabs: const [
          Tab(text: 'Order Details'),
          Tab(text: 'Payments'),
          Tab(text: 'Measurements'),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: Column(
              children: [
                _buildSidebarCard(
                  title: 'Order Summary',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _infoRow('Order #', _order?.orderNumber ?? '-'),
                    _infoRow('Created', _formatDate(_order?.orderDate)),
                    _infoRow(
                      'Delivery',
                      _formatDate(_order?.plannedDeliveryDate),
                    ),
                    if (_order?.actualDeliveryDate != null)
                      _infoRow(
                        'Actual Delivery',
                        _formatDate(_order?.actualDeliveryDate),
                      ),
                    if (_order?.trialDate != null)
                      _infoRow('Trial Date', _formatDate(_order?.trialDate)),
                    _infoRow('Priority', _order?.priorityDisplay ?? '-'),
                    _infoRow('Status', _order?.statusDisplay ?? '-'),
                    if (_order?.updatedAt != null)
                      _infoRow('Updated', _formatDate(_order?.updatedAt)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSidebarCard(
                  title: 'Customer Info',
                  icon: Icons.person_outline,
                  children: [
                    _infoRow('Name', _order?.customerName ?? '-'),
                    _infoRow('Customer ID', '#${_order?.customerId ?? "-"}'),
                  ],
                ),
                const SizedBox(height: 16),
                if (_order?.orderSummary != null &&
                    _order!.orderSummary!.isNotEmpty)
                  _buildSidebarCard(
                    title: 'Order Summary Notes',
                    icon: Icons.notes,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _order!.orderSummary!,
                          style: AppTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                if (_order?.orderSummary != null &&
                    _order!.orderSummary!.isNotEmpty)
                  const SizedBox(height: 16),
                if (_order?.customerInstructions != null &&
                    _order!.customerInstructions!.isNotEmpty)
                  _buildSidebarCard(
                    title: 'Customer Instructions',
                    icon: Icons.info_outline,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warning.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          _order!.customerInstructions!,
                          style: AppTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                if (_order?.customerInstructions != null &&
                    _order!.customerInstructions!.isNotEmpty)
                  const SizedBox(height: 16),
                _buildSidebarCard(
                  title: 'Order Tracking',
                  icon: Icons.qr_code_2,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: QrImageView(
                        data: _order?.qrCode ?? _order?.orderNumber ?? 'N/A',
                        size: 150,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildMainCard(
                  title: 'Order Items (${_order?.items?.length ?? 0})',
                  child: _buildOrderItemsList(),
                ),
                const SizedBox(height: 20),
                if (_order?.referencePhotos != null &&
                    _order!.referencePhotos!.isNotEmpty)
                  _buildMainCard(
                    title:
                        'Reference Photos (${_order!.referencePhotos!.length})',
                    child: _buildReferencePhotosSection(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return OrderPaymentsTab(
      orderId: _order!.id!,
      orderTotal: _order!.grandTotal,
    );
  }
  // ✅ MEASUREMENTS TAB WITH ACTUAL DATA

  Widget _buildMeasurementsTab() {
    final measurements = _order?.customerMeasurements;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: measurements == null
          ? _buildNoMeasurementsState()
          : MeasurementDisplayWidget(measurements: measurements, gender: null),
    );
  }

  Widget _buildNoMeasurementsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            const Icon(Icons.straighten, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No measurements recorded for this customer',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Measurements can be added in the Customers section',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.heading3),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildSidebarCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              Text(title, style: AppTheme.bodyMediumBold),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList() {
    final items = _order?.items ?? [];

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text('No items in this order', style: AppTheme.bodyMedium),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Item', style: AppTheme.bodySmallBold),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: AppTheme.bodySmallBold,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Price',
                  style: AppTheme.bodySmallBold,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Disc%',
                  style: AppTheme.bodySmallBold,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Tax',
                  style: AppTheme.bodySmallBold,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: AppTheme.bodySmallBold,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 16),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          String itemName = item.itemName;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: index < items.length - 1
                    ? const BorderSide(color: AppTheme.borderLight)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    itemName,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${item.quantity.toInt()}',
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    item.formattedUnitPrice,
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    item.itemDiscountPercentage > 0
                        ? '${item.itemDiscountPercentage.toStringAsFixed(0)}%'
                        : '-',
                    style: AppTheme.bodySmall.copyWith(
                      color: item.itemDiscountPercentage > 0
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${item.taxAmount.toStringAsFixed(2)}',
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    item.formattedTotal,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 24, thickness: 2),
        _buildSummaryRow('Subtotal', _order!.formattedSubtotal),
        if (_order!.totalDiscount > 0)
          _buildSummaryRow(
            'Discount',
            '-₹${_order!.totalDiscount.toStringAsFixed(2)}',
          ),
        _buildSummaryRow('Tax', '₹${_order!.totalTax.toStringAsFixed(2)}'),
        const Divider(height: 16),
        _buildSummaryRow('Grand Total', _order!.formattedTotal, isBold: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 40),
          SizedBox(
            width: 120,
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferencePhotosSection() {
    final photos = _order!.referencePhotos!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _buildPhotoCard(photo);
      },
    );
  }

  Widget _buildPhotoCard(photo) {
    return GestureDetector(
      onTap: () => _showPhotoDialog(photo),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: photo.photoUrl != null
                    ? Image.network(
                        photo.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.backgroundGrey,
                            child: const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: AppTheme.textMuted,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppTheme.backgroundGrey,
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                      ),
              ),
            ),
            if (photo.description != null && photo.description!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  photo.description!,
                  style: AppTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDialog(photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(photo.description ?? 'Reference Photo'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: photo.photoUrl != null
                    ? Image.network(photo.photoUrl!, fit: BoxFit.contain)
                    : const Center(child: Text('No image available')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status.toUpperCase()) {
      case 'PENDING':
        badgeColor = AppTheme.warning;
        break;
      case 'IN_PROGRESS':
        badgeColor = AppTheme.primaryBlue;
        break;
      case 'READY':
      case 'DELIVERED':
      case 'COMPLETED':
        badgeColor = AppTheme.success;
        break;
      case 'CANCELLED':
        badgeColor = AppTheme.danger;
        break;
      default:
        badgeColor = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _order?.statusDisplay ?? status,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _printInternalReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Internal Report - Coming soon!')),
    );
  }

  void _printWorkOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workshop Work Order - Coming soon!')),
    );
  }
}
