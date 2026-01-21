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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    _paymentTermsController = TextEditingController(
      text: widget.orderData['payment_terms'] ?? '',
    );

    // Initialize dates
    _orderDate = DateTime.parse(widget.orderData['order_date']);
    _expectedDeliveryDate = DateTime.parse(
      widget.orderData['expected_delivery_date'],
    );

    final actualDate = widget.orderData['actual_delivery_date'];
    if (actualDate != null) {
      _actualDeliveryDate = DateTime.parse(actualDate);
    }

    _priority = widget.orderData['priority'] ?? 'MEDIUM';
  }

  @override
  void dispose() {
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    DateTime initialDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (field) {
      case 'order':
        initialDate = _orderDate;
        firstDate = DateTime.now().subtract(const Duration(days: 365));
        lastDate = DateTime.now().add(const Duration(days: 30));
        break;
      case 'expected':
        initialDate = _expectedDeliveryDate;
        firstDate = _orderDate;
        lastDate = DateTime.now().add(const Duration(days: 365));
        break;
      case 'actual':
        initialDate = _actualDeliveryDate ?? DateTime.now();
        firstDate = _orderDate;
        lastDate = DateTime.now().add(const Duration(days: 30));
        break;
      default:
        return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        switch (field) {
          case 'order':
            _orderDate = picked;
            break;
          case 'expected':
            _expectedDeliveryDate = picked;
            break;
          case 'actual':
            _actualDeliveryDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _apiClient.patch(
        'orders/orders/${widget.orderData['id']}/',
        data: {
          'order_date': _orderDate.toIso8601String().split('T')[0],
          'expected_delivery_date': _expectedDeliveryDate
              .toIso8601String()
              .split('T')[0],
          'actual_delivery_date': _actualDeliveryDate?.toIso8601String().split(
            'T',
          )[0],
          'priority': _priority,
          'payment_terms': _paymentTermsController.text.trim(),
        },
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order details updated successfully'),
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text('Edit Order Details', style: AppTheme.heading2),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dates Section
                  Text('Dates', style: AppTheme.heading3),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          'Order Date',
                          _orderDate,
                          () => _selectDate(context, 'order'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          'Expected Delivery',
                          _expectedDeliveryDate,
                          () => _selectDate(context, 'expected'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildDateField(
                    'Actual Delivery (Optional)',
                    _actualDeliveryDate,
                    () => _selectDate(context, 'actual'),
                    optional: true,
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Priority Section
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
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _priority = value);
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Text Fields Section
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
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
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
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    bool optional = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (optional && date != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _actualDeliveryDate = null;
                    });
                  },
                  tooltip: 'Clear date',
                ),
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 12),
            ],
          ),
        ),
        child: Text(
          date != null ? _formatDate(date) : 'Not Set',
          style: AppTheme.bodyMedium,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
