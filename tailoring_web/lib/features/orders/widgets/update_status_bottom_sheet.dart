import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';

class UpdateStatusBottomSheet extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String statusType; // 'order' or 'delivery'
  final VoidCallback onSaved;

  const UpdateStatusBottomSheet({
    Key? key,
    required this.orderData,
    required this.statusType,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<UpdateStatusBottomSheet> createState() =>
      _UpdateStatusBottomSheetState();
}

class _UpdateStatusBottomSheetState extends State<UpdateStatusBottomSheet> {
  final _apiClient = ApiClient();
  late String _selectedStatus;
  bool _isSaving = false;
  DateTime? _actualDeliveryDate;

  @override
  void initState() {
    super.initState();
    if (widget.statusType == 'order') {
      _selectedStatus = widget.orderData['order_status'] ?? 'DRAFT';
    } else {
      _selectedStatus = widget.orderData['delivery_status'] ?? 'NOT_STARTED';
    }

    final actualDate = widget.orderData['actual_delivery_date'];
    if (actualDate != null) {
      _actualDeliveryDate = DateTime.parse(actualDate);
    }
  }

  List<Map<String, dynamic>> _getStatusOptions() {
    if (widget.statusType == 'order') {
      return [
        {'value': 'DRAFT', 'label': 'Draft', 'color': Colors.grey},
        {
          'value': 'CONFIRMED',
          'label': 'Confirmed',
          'color': AppTheme.primaryBlue,
        },
        {
          'value': 'IN_PROGRESS',
          'label': 'In Progress',
          'color': AppTheme.warning,
        },
        {'value': 'COMPLETED', 'label': 'Completed', 'color': AppTheme.success},
        {'value': 'ON_HOLD', 'label': 'On Hold', 'color': Colors.amber},
        {'value': 'CANCELLED', 'label': 'Cancelled', 'color': AppTheme.danger},
      ];
    } else {
      return [
        {'value': 'NOT_STARTED', 'label': 'Not Started', 'color': Colors.grey},
        {
          'value': 'IN_PROGRESS',
          'label': 'In Progress',
          'color': AppTheme.warning,
        },
        {'value': 'READY', 'label': 'Ready', 'color': AppTheme.primaryBlue},
        {'value': 'DELIVERED', 'label': 'Delivered', 'color': AppTheme.success},
      ];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _actualDeliveryDate ?? DateTime.now(),
      firstDate: DateTime.parse(widget.orderData['order_date']),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _actualDeliveryDate = picked;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{};

      if (widget.statusType == 'order') {
        data['order_status'] = _selectedStatus;
      } else {
        data['delivery_status'] = _selectedStatus;

        // Auto-set actual delivery date when status is DELIVERED
        if (_selectedStatus == 'DELIVERED') {
          data['actual_delivery_date'] = (_actualDeliveryDate ?? DateTime.now())
              .toIso8601String()
              .split('T')[0];
        }
      }

      await _apiClient.patch(
        'orders/orders/${widget.orderData['id']}/',
        data: data,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppTheme.danger,
          ),
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
    final options = _getStatusOptions();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  widget.statusType == 'order'
                      ? Icons.assignment
                      : Icons.local_shipping,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.statusType == 'order'
                      ? 'Update Order Status'
                      : 'Update Delivery Status',
                  style: AppTheme.heading2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: options.map((option) {
                final isSelected = _selectedStatus == option['value'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatus = option['value'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (option['color'] as Color).withOpacity(0.1)
                            : AppTheme.backgroundGrey,
                        border: Border.all(
                          color: isSelected
                              ? option['color'] as Color
                              : AppTheme.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: option['color'] as Color,
                                width: 2,
                              ),
                              color: isSelected
                                  ? option['color'] as Color
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            option['label'] as String,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? option['color'] as Color
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Actual Delivery Date (for delivery status = DELIVERED)
          if (widget.statusType == 'delivery' &&
              _selectedStatus == 'DELIVERED') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Actual Delivery Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    _formatDate(_actualDeliveryDate ?? DateTime.now()),
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Update Status'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
