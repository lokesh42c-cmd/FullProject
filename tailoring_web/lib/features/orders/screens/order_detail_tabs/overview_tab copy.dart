import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';

class OverviewTab extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final bool isLocked;
  final VoidCallback onRefresh;

  const OverviewTab({
    Key? key,
    required this.orderData,
    required this.isLocked,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final _apiClient = ApiClient();
  bool _isOrderNotesExpanded = true;
  bool _isChangeRequestsExpanded = true;

  late TextEditingController _orderNotesController;
  late TextEditingController _changeRequestsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _orderNotesController = TextEditingController(
      text: widget.orderData['order_summary'] ?? '',
    );
    _changeRequestsController = TextEditingController(
      text: widget.orderData['customer_instructions'] ?? '',
    );
  }

  @override
  void dispose() {
    _orderNotesController.dispose();
    _changeRequestsController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);

    try {
      await _apiClient.patch(
        'orders/orders/${widget.orderData['id']}/',
        data: {
          'order_summary': _orderNotesController.text.trim(),
          'customer_instructions': _changeRequestsController.text.trim(),
        },
      );

      if (mounted) {
        widget.onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummaryCard(),
          const SizedBox(height: 16),
          _buildNotesSection(),
          const SizedBox(height: 16),
          _buildBottomRow(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final customerName = widget.orderData['customer_name'] ?? 'N/A';
    final phone = widget.orderData['customer_phone'] ?? 'N/A';
    final orderStatus = widget.orderData['order_status'] ?? 'DRAFT';
    final deliveryStatus = widget.orderData['delivery_status'] ?? 'NOT_STARTED';
    final orderDate = widget.orderData['order_date'] ?? '';
    final expectedDelivery = widget.orderData['expected_delivery_date'] ?? '';
    final actualDelivery = widget.orderData['actual_delivery_date'];
    final priority = widget.orderData['priority'] ?? 'MEDIUM';
    final invoice = widget.orderData['invoice_number']; // Will be null for now
    final assignedTo = widget.orderData['assigned_to_name'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.summarize,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Order Summary', style: AppTheme.heading3),
              const Spacer(),
              if (!widget.isLocked)
                InkWell(
                  onTap: _onEditOrderSummary,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 14, color: AppTheme.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 1: Customer and Phone
          _buildSummaryRow('Customer', customerName, 'Phone', phone),
          const SizedBox(height: 10),

          // Row 2: Order Status and Delivery Status
          Row(
            children: [
              _buildLabelValue('Status', null),
              _buildStatusBadge(
                orderStatus,
                _getOrderStatusColor(orderStatus),
                () => _onEditStatus(context, 'order'),
              ),
              const SizedBox(width: 24),
              _buildLabelValue('Delivery', null),
              _buildStatusBadge(
                deliveryStatus,
                _getDeliveryStatusColor(deliveryStatus),
                () => _onEditStatus(context, 'delivery'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Order Date and Expected Delivery
          _buildSummaryRow(
            'Order Date',
            _formatDate(orderDate),
            'Expected',
            _formatDate(expectedDelivery),
          ),
          const SizedBox(height: 10),

          // Row 4: Actual Delivery and Priority
          Row(
            children: [
              _buildLabelValue(
                'Actual',
                actualDelivery != null
                    ? _formatDate(actualDelivery)
                    : 'Not Delivered',
              ),
              const SizedBox(width: 24),
              _buildLabelValue('Priority', null),
              _buildPriorityBadge(priority),
            ],
          ),
          const SizedBox(height: 10),

          // Row 5: Invoice and Assigned
          _buildSummaryRow(
            'Invoice',
            invoice != null ? invoice.toString() : 'Not Created',
            'Assigned',
            assignedTo ?? 'Not Assigned',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label1,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value1,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label2,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value2,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabelValue(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        if (value != null)
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: widget.isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatStatus(status),
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (!widget.isLocked) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _formatStatus(priority),
        style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final orderStatus = widget.orderData['order_status'] ?? 'DRAFT';
    final isOrderNotesEditable = orderStatus == 'DRAFT' && !widget.isLocked;

    return Column(
      children: [
        _buildCollapsibleNotesCard(
          icon: Icons.description,
          iconColor: AppTheme.primaryBlue,
          title: 'Order Notes',
          subtitle: 'Initial requirements and specifications',
          controller: _orderNotesController,
          isExpanded: _isOrderNotesExpanded,
          onToggle: () =>
              setState(() => _isOrderNotesExpanded = !_isOrderNotesExpanded),
          editable: isOrderNotesEditable,
          hint: 'Enter order notes, requirements, specifications...',
        ),
        const SizedBox(height: 16),
        _buildCollapsibleNotesCard(
          icon: Icons.update,
          iconColor: AppTheme.warning,
          title: 'Change Requests',
          subtitle: 'Any modifications or changes after order confirmation',
          controller: _changeRequestsController,
          isExpanded: _isChangeRequestsExpanded,
          onToggle: () => setState(
            () => _isChangeRequestsExpanded = !_isChangeRequestsExpanded,
          ),
          editable: !widget.isLocked,
          hint: 'Enter any changes, modifications, or updates...',
          showTimestamp: true,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isSaving || widget.isLocked) ? null : _saveNotes,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Notes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleNotesCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool editable,
    required String hint,
    bool showTimestamp = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTheme.heading3),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!editable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Read Only',
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    enabled: editable,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: editable ? hint : 'No notes added',
                      hintStyle: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      border: const OutlineInputBorder(),
                      filled: !editable,
                      fillColor: editable ? null : AppTheme.backgroundGrey,
                    ),
                    style: AppTheme.bodyMedium,
                  ),
                  if (showTimestamp &&
                      widget.orderData['updated_at'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last updated: ${_formatDateTime(widget.orderData['updated_at'])}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        Expanded(child: _buildQRCodeCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildRecordInfoCard()),
      ],
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_2,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('QR Code', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _onViewQRCode,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_2,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to view',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Record Information', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecordRow(
            'Created',
            widget.orderData['created_at'],
            widget.orderData['created_by'],
          ),
          const SizedBox(height: 12),
          _buildRecordRow(
            'Updated',
            widget.orderData['updated_at'],
            widget.orderData['updated_by'],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, dynamic dateTime, dynamic userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDateTime(dateTime),
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
        if (userId != null)
          Text(
            'by User #$userId',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  // Helper methods
  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null || dateTime.toString().isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'CONFIRMED':
        return AppTheme.primaryBlue;
      case 'IN_PROGRESS':
        return AppTheme.warning;
      case 'COMPLETED':
        return AppTheme.success;
      case 'CANCELLED':
        return AppTheme.danger;
      case 'ON_HOLD':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NOT_STARTED':
        return Colors.grey;
      case 'IN_PROGRESS':
        return AppTheme.warning;
      case 'READY':
        return AppTheme.primaryBlue;
      case 'DELIVERED':
        return AppTheme.success;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppTheme.danger;
      case 'LOW':
        return AppTheme.success;
      default:
        return AppTheme.warning;
    }
  }

  void _onEditOrderSummary() {
    // TODO: Open edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit dialog - To be implemented')),
    );
  }

  void _onEditStatus(BuildContext context, String type) {
    // TODO: Open status bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit $type status - To be implemented')),
    );
  }

  void _onViewQRCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Code viewer - To be implemented')),
    );
  }
}
