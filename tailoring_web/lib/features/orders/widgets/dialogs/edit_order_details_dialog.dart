import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';

class EditOrderDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onSaved;

  const EditOrderDetailsDialog({
    Key? key,
    required this.orderData,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<EditOrderDetailsDialog> createState() => _EditOrderDetailsDialogState();
}

class _EditOrderDetailsDialogState extends State<EditOrderDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  late TextEditingController _paymentTermsController;

  late DateTime _orderDate;
  late DateTime _expectedDeliveryDate;
  DateTime? _actualDeliveryDate;
  late String _priority;
  late String _orderStatus;
  late String _deliveryStatus;
  int? _assignedTo;

  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingEmployees = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _paymentTermsController = TextEditingController(
      text: widget.orderData['payment_terms'] ?? '',
    );

    _orderDate = DateTime.parse(widget.orderData['order_date']);
    _expectedDeliveryDate = DateTime.parse(
      widget.orderData['expected_delivery_date'],
    );

    final actualDate = widget.orderData['actual_delivery_date'];
    if (actualDate != null) {
      _actualDeliveryDate = DateTime.parse(actualDate);
    }

    _priority = widget.orderData['priority'] ?? 'MEDIUM';
    _orderStatus = widget.orderData['order_status'] ?? 'DRAFT';
    _deliveryStatus = widget.orderData['delivery_status'] ?? 'NOT_STARTED';
    _assignedTo = widget.orderData['assigned_to'];

    _loadEmployees();
  }

  @override
  void dispose() {
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await _apiClient.get('employees/employees/');
      setState(() {
        if (response.data is Map && response.data['results'] != null) {
          _employees = List<Map<String, dynamic>>.from(
            response.data['results'],
          );
        } else if (response.data is List) {
          _employees = List<Map<String, dynamic>>.from(response.data);
        }
        _isLoadingEmployees = false;
      });
    } catch (e) {
      print('Error loading employees: $e');
      setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _actualDeliveryDate ?? DateTime.now(),
      firstDate: _orderDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _actualDeliveryDate = pickedDate;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'order_status': _orderStatus,
        'delivery_status': _deliveryStatus,
        'priority': _priority,
        if (_actualDeliveryDate != null)
          'actual_delivery_date': _actualDeliveryDate!.toIso8601String().split(
            'T',
          )[0],
        if (_assignedTo != null) 'assigned_to': _assignedTo,
        if (_paymentTermsController.text.isNotEmpty)
          'payment_terms': _paymentTermsController.text,
      };

      await _apiClient.patch(
        'orders/orders/${widget.orderData['id']}/',
        data: updateData,
      );

      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order details updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dates Section (Read-only)
                      Text('Order Dates', style: AppTheme.heading3),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildReadOnlyField(
                              'Order Date',
                              _formatDate(_orderDate),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReadOnlyField(
                              'Expected Delivery',
                              _formatDate(_expectedDeliveryDate),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Actual Delivery (Editable)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actual Delivery Date',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderLight),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _actualDeliveryDate != null
                                        ? _formatDate(_actualDeliveryDate!)
                                        : 'Not Set',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: _actualDeliveryDate != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Order Status
                      Text('Order Status', style: AppTheme.heading3),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _orderStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'DRAFT',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'CONFIRMED',
                            child: Text('Confirmed'),
                          ),
                          DropdownMenuItem(
                            value: 'IN_PROGRESS',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'READY',
                            child: Text('Ready'),
                          ),
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
                          if (value != null) {
                            setState(() => _orderStatus = value);
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Priority
                      Text('Priority', style: AppTheme.heading3),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Low')),
                          DropdownMenuItem(
                            value: 'MEDIUM',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(value: 'HIGH', child: Text('High')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _priority = value);
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Delivery Status
                      Text('Delivery Status', style: AppTheme.heading3),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _deliveryStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'NOT_STARTED',
                            child: Text('Not Started'),
                          ),
                          DropdownMenuItem(
                            value: 'IN_TRANSIT',
                            child: Text('In Transit'),
                          ),
                          DropdownMenuItem(
                            value: 'DELIVERED',
                            child: Text('Delivered'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _deliveryStatus = value);
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Assigned To
                      Text('Assigned To', style: AppTheme.heading3),
                      const SizedBox(height: 16),

                      _isLoadingEmployees
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<int>(
                              value: _assignedTo,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                hintText: 'Select Employee',
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Not Assigned'),
                                ),
                                ..._employees.map((emp) {
                                  return DropdownMenuItem<int>(
                                    value: emp['id'],
                                    child: Text(
                                      emp['name'] ?? 'Employee ${emp['id']}',
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _assignedTo = value);
                              },
                            ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Payment Terms
                      Text('Additional Information', style: AppTheme.heading3),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _paymentTermsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms',
                          hintText: 'e.g., 50% advance, balance on delivery',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 40),
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
                                : const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusMedium),
          topRight: Radius.circular(AppTheme.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          const Text('Edit Order Details', style: AppTheme.heading2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
