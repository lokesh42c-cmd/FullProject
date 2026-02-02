import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Invoice Details Row Widget
/// Displays invoice number (locked with edit button), dates, tax type, and order reference
class InvoiceDetailsRow extends StatefulWidget {
  final TextEditingController invoiceNumberController;
  final DateTime invoiceDate;
  final DateTime? deliveryDate;
  final String? orderReference;
  final String taxType;
  final Function(DateTime?) onInvoiceDateChanged;
  final Function(DateTime?) onDeliveryDateChanged;
  final Function(String) onTaxTypeChanged;
  final bool isFromOrder;
  final bool isTaxInclusive;

  const InvoiceDetailsRow({
    super.key,
    required this.invoiceNumberController,
    required this.invoiceDate,
    this.deliveryDate,
    this.orderReference,
    required this.taxType,
    required this.onInvoiceDateChanged,
    required this.onDeliveryDateChanged,
    required this.onTaxTypeChanged,
    this.isFromOrder = false,
    this.isTaxInclusive = false,
  });

  @override
  State<InvoiceDetailsRow> createState() => _InvoiceDetailsRowState();
}

class _InvoiceDetailsRowState extends State<InvoiceDetailsRow> {
  bool _isInvoiceNumberLocked = true;

  @override
  Widget build(BuildContext context) {
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
                Icons.receipt_long,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Invoice Details',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 1: Invoice Number & Invoice Date
          Row(
            children: [
              // Invoice Number with Lock/Unlock
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.invoiceNumberController,
                        readOnly: _isInvoiceNumberLocked,
                        decoration: InputDecoration(
                          labelText: 'Invoice Number',
                          hintText: 'Auto-generated',
                          prefixIcon: Icon(
                            _isInvoiceNumberLocked
                                ? Icons.lock
                                : Icons.lock_open,
                            size: 20,
                            color: _isInvoiceNumberLocked
                                ? AppTheme.textMuted
                                : AppTheme.primaryBlue,
                          ),
                          filled: _isInvoiceNumberLocked,
                          fillColor: _isInvoiceNumberLocked
                              ? AppTheme.backgroundGrey
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit/Lock button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isInvoiceNumberLocked = !_isInvoiceNumberLocked;
                        });
                      },
                      icon: Icon(
                        _isInvoiceNumberLocked ? Icons.edit : Icons.check,
                        size: 20,
                      ),
                      tooltip: _isInvoiceNumberLocked ? 'Edit' : 'Lock',
                      style: IconButton.styleFrom(
                        backgroundColor: _isInvoiceNumberLocked
                            ? AppTheme.primaryBlue.withOpacity(0.1)
                            : AppTheme.success.withOpacity(0.1),
                        foregroundColor: _isInvoiceNumberLocked
                            ? AppTheme.primaryBlue
                            : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Invoice Date
              Expanded(
                child: _buildDateField(
                  context: context,
                  label: 'Invoice Date *',
                  date: widget.invoiceDate,
                  onDateSelected: widget.onInvoiceDateChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Order Reference & Tax Type
          Row(
            children: [
              // Order Reference (if from order)
              if (widget.isFromOrder && widget.orderReference != null)
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Order Reference',
                      hintText: 'ORD-XXX',
                      prefixIcon: const Icon(Icons.link, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundGrey,
                    ),
                    controller: TextEditingController(
                      text: widget.orderReference,
                    ),
                  ),
                )
              else
                // Delivery Date (for walk-in)
                Expanded(
                  child: _buildDateField(
                    context: context,
                    label: 'Delivery Date',
                    date: widget.deliveryDate,
                    onDateSelected: widget.onDeliveryDateChanged,
                    canClear: true,
                  ),
                ),

              const SizedBox(width: 16),

              // Tax Type Dropdown (locked if from order)
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.taxType,
                  decoration: InputDecoration(
                    labelText: 'Tax Type *',
                    prefixIcon: const Icon(Icons.percent, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: widget.isFromOrder,
                    fillColor: widget.isFromOrder
                        ? AppTheme.backgroundGrey
                        : null,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'INTRASTATE',
                      child: Text('Intrastate (CGST + SGST)'),
                    ),
                    DropdownMenuItem(
                      value: 'INTERSTATE',
                      child: Text('Interstate (IGST)'),
                    ),
                    DropdownMenuItem(value: 'ZERO', child: Text('Zero-rated')),
                  ],
                  onChanged: widget.isFromOrder
                      ? null // Locked if from order
                      : (value) {
                          if (value != null) {
                            widget.onTaxTypeChanged(value);
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
    bool canClear = false,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          suffixIcon: canClear && date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onDateSelected(null),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: Text(
          date != null ? DateFormat('dd-MM-yyyy').format(date) : 'Select date',
          style: date != null
              ? AppTheme.bodyMedium
              : AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
