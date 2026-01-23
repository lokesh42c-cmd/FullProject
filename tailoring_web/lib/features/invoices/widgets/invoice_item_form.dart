import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import '../models/invoice.dart';

class InvoiceItemForm extends StatefulWidget {
  final InvoiceItem item;
  final Function(InvoiceItem) onChanged;
  final VoidCallback onDelete;

  const InvoiceItemForm({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<InvoiceItemForm> createState() => _InvoiceItemFormState();
}

class _InvoiceItemFormState extends State<InvoiceItemForm> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late double _gstRate;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.item.itemDescription,
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice.toString(),
    );
    _gstRate = widget.item.gstRate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final updatedItem = InvoiceItem(
      id: widget.item.id,
      item: widget.item.item,
      itemName: widget.item.itemName,
      itemDescription: _descriptionController.text,
      hsnSacCode: widget.item.hsnSacCode,
      itemType: widget.item.itemType,
      quantity: double.tryParse(_quantityController.text) ?? 0.0,
      unitPrice: double.tryParse(_priceController.text) ?? 0.0,
      gstRate: _gstRate,
    );
    widget.onChanged(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    final subtotal =
        (double.tryParse(_quantityController.text) ?? 0.0) *
        (double.tryParse(_priceController.text) ?? 0.0);
    final tax = (subtotal * _gstRate) / 100;
    final total = subtotal + tax;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Description
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Item Description *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _notifyChange(),
                  ),
                ),

                const SizedBox(width: 12),

                // Quantity
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Qty *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      _notifyChange();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Unit Price
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '₹',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      _notifyChange();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // GST Rate
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: _gstRate,
                    decoration: const InputDecoration(
                      labelText: 'GST %',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 0.0, child: Text('0%')),
                      DropdownMenuItem(value: 5.0, child: Text('5%')),
                      DropdownMenuItem(value: 12.0, child: Text('12%')),
                      DropdownMenuItem(value: 18.0, child: Text('18%')),
                      DropdownMenuItem(value: 28.0, child: Text('28%')),
                    ],
                    onChanged: (value) {
                      setState(() => _gstRate = value!);
                      _notifyChange();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Delete Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.danger,
                  ),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Item',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Calculation Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal: ₹${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Tax: ₹${tax.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Total: ₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
