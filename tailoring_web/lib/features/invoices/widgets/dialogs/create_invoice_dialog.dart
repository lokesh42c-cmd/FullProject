import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';

import 'package:tailoring_web/features/invoices/models/invoice.dart';

import 'package:tailoring_web/features/invoices/services/invoice_service.dart';

class CreateInvoiceDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onInvoiceCreated;

  const CreateInvoiceDialog({
    super.key,
    required this.orderData,
    required this.onInvoiceCreated,
  });

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  final InvoiceService _invoiceService = InvoiceService();
  final _formKey = GlobalKey<FormState>();

  bool _isCreating = false;
  String _invoiceDate = '';
  String _notes = '';
  String _termsAndConditions = 'Payment due within 7 days';

  @override
  void initState() {
    super.initState();
    // Default to today's date
    _invoiceDate = DateTime.now().toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    final customerData = widget.orderData;
    final items = widget.orderData['items'] as List? ?? [];
    final double grandTotal = _getDoubleValue(widget.orderData['grand_total']);
    final double advanceReceived = _getDoubleValue(
      widget.orderData['advance_received'],
    );
    final double balanceDue = grandTotal - advanceReceived;

    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create Invoice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info
                      _buildInfoCard(
                        customerData,
                        items,
                        grandTotal,
                        advanceReceived,
                        balanceDue,
                      ),

                      const SizedBox(height: 20),

                      // Invoice Date
                      TextFormField(
                        initialValue: _invoiceDate,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Date *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _invoiceDate = date.toIso8601String().split(
                                'T',
                              )[0];
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 2,
                        onChanged: (value) => _notes = value,
                      ),

                      const SizedBox(height: 16),

                      // Terms & Conditions
                      TextFormField(
                        initialValue: _termsAndConditions,
                        decoration: const InputDecoration(
                          labelText: 'Terms & Conditions',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                        onChanged: (value) => _termsAndConditions = value,
                      ),

                      const SizedBox(height: 20),

                      // Important Notes
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          border: Border.all(
                            color: AppTheme.warning.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: AppTheme.warning,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Important:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Invoice will be created with status DRAFT\n'
                              '• Order will be LOCKED after invoice creation\n'
                              '• Advance payments will be automatically adjusted\n'
                              '• Invoice can be issued after review',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isCreating
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isCreating
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
                        : const Text('Create Invoice'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    Map<String, dynamic> customerData,
    List items,
    double grandTotal,
    double advanceReceived,
    double balanceDue,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Order & Customer Info
            _infoRow('Order Number', customerData['order_number'] ?? '-'),
            _infoRow('Customer', customerData['customer_name'] ?? '-'),
            _infoRow('Phone', customerData['customer_phone'] ?? '-'),

            const Divider(height: 24),

            // Items Count
            Text(
              '${items.length} Items',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Items List
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• ${item['item_name']} (${item['quantity']}x)',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '₹${_getDoubleValue(item['total_amount']).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            // Financial Summary
            _infoRow(
              'Grand Total',
              '₹${grandTotal.toStringAsFixed(2)}',
              isBold: true,
            ),
            _infoRow(
              'Advance Received',
              '₹${advanceReceived.toStringAsFixed(2)}',
              valueColor: AppTheme.success,
            ),
            _infoRow(
              'Balance Due',
              '₹${balanceDue.toStringAsFixed(2)}',
              isBold: true,
              valueColor: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final orderItems = widget.orderData['items'] as List? ?? [];

      // Build invoice items from order items
      final invoiceItems = orderItems.map((item) {
        return InvoiceItem(
          item: item['item'],
          itemDescription: item['item_name'] ?? '',
          itemType: 'SERVICE',
          quantity: _getDoubleValue(item['quantity']),
          unitPrice: _getDoubleValue(item['rate']),
          gstRate: _getDoubleValue(item['tax_percentage']),
        );
      }).toList();

      // Create invoice object
      final invoice = Invoice(
        invoiceNumber: '', // Auto-generated by backend
        invoiceDate: _invoiceDate,
        customer: widget.orderData['customer'],
        order: widget.orderData['id'],
        status: 'DRAFT',
        billingName: widget.orderData['customer_name'] ?? '',
        billingAddress: widget.orderData['customer_address'] ?? '',
        billingState: widget.orderData['customer_state'] ?? '',
        taxType: 'INTRASTATE', // Will be calculated by backend
        notes: _notes.isNotEmpty ? _notes : null,
        termsAndConditions: _termsAndConditions.isNotEmpty
            ? _termsAndConditions
            : null,
        items: invoiceItems,
      );

      // Create invoice via API
      final createdInvoice = await _invoiceService.createInvoice(invoice);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invoice ${createdInvoice.invoiceNumber} created successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onInvoiceCreated();
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
            content: Text('Failed to create invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  double _getDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
