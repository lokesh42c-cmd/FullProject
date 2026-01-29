import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';

class PrintInternalDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PrintInternalDialog({super.key, required this.orderData});

  @override
  State<PrintInternalDialog> createState() => _PrintInternalDialogState();
}

class _PrintInternalDialogState extends State<PrintInternalDialog> {
  final _apiClient = ApiClient();
  Map<String, dynamic>? _customerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      final customerId = widget.orderData['customer'];
      final response = await _apiClient.get('orders/customers/$customerId/');
      setState(() {
        _customerData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 900,
        height: 900,
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShopHeader(),
                          const SizedBox(height: 32),
                          _buildOrderInfo(),
                          const SizedBox(height: 32),
                          _buildCustomerInfo(),
                          const SizedBox(height: 32),
                          _buildReferencePhotos(),
                          const SizedBox(height: 32),
                          _buildItemsTable(),
                          const SizedBox(height: 32),
                          _buildFinancialSummary(),
                          const SizedBox(height: 32),
                          _buildMeasurements(),
                          const SizedBox(height: 32),
                          _buildOrderNotes(),
                          const SizedBox(height: 32),
                          _buildChangeRequests(),
                          const SizedBox(height: 32),
                          _buildFooter(),
                        ],
                      ),
                    ),
            ),
            _buildPrintActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Text('Print - Internal Copy', style: AppTheme.heading2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TAILORING SHOP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Shop Address Line 1'),
          const Text('Shop Address Line 2'),
          const Text('Phone: +91 XXXXXXXXXX'),
          const SizedBox(height: 16),
          const Divider(color: Colors.black),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER: ${widget.orderData['order_number'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${widget.orderData['customer_details']?['name'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.orderData['order_status']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.orderData['order_status_display'] ?? 'DRAFT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER INFORMATION',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _printField(
                  'Order Date',
                  widget.orderData['order_date'] ?? 'N/A',
                ),
              ),
              Expanded(
                child: _printField(
                  'Expected Delivery',
                  widget.orderData['expected_delivery_date'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _printField(
                  'Priority',
                  widget.orderData['priority_display'] ?? 'MEDIUM',
                ),
              ),
              Expanded(
                child: _printField(
                  'Delivery Status',
                  widget.orderData['delivery_status_display'] ?? 'Not Started',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final customer = widget.orderData['customer_details'] ?? {};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMER INFORMATION',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _printField('Name', customer['name'] ?? 'N/A'),
          _printField('Phone', customer['phone'] ?? 'N/A'),
          if (customer['email'] != null)
            _printField('Email', customer['email']),
          if (customer['full_address'] != null)
            _printField('Address', customer['full_address']),
          if (_customerData?['notes'] != null &&
              _customerData!['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Customer Notes:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _customerData!['notes'].toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferencePhotos() {
    final photos = widget.orderData['reference_photos'] as List? ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_library, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'REFERENCE PHOTOS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: photos.map((photo) {
              return Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: photo['photo_url'] != null
                      ? Image.network(
                          photo['photo_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    final items = widget.orderData['items'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ITEM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'QTY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PRICE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['item_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item['item_description'] != null)
                          Text(
                            item['item_description'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item['quantity'] ?? 0}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${(item['unit_price'] ?? 0).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${(item['total_price'] ?? 0).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildFinancialSummary() {
    final items = widget.orderData['items'] as List? ?? [];
    double subtotal = 0;
    double totalTax = 0;
    double totalDiscount = 0;

    for (var item in items) {
      subtotal += (item['subtotal'] ?? 0).toDouble();
      totalTax += (item['tax_amount'] ?? 0).toDouble();
      totalDiscount += (item['discount'] ?? 0).toDouble();
    }

    final grandTotal = items.fold(
      0.0,
      (sum, item) => sum + (item['total_price'] ?? 0).toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', subtotal),
          if (totalDiscount > 0)
            _summaryRow('Discount', totalDiscount, isNegative: true),
          _summaryRow('Tax', totalTax),
          const Divider(color: Colors.black, thickness: 2),
          _summaryRow('GRAND TOTAL', grandTotal, isBold: true, fontSize: 18),
        ],
      ),
    );
  }

  Widget _buildMeasurements() {
    if (_customerData == null) return const SizedBox.shrink();

    final measurements = [
      if (_customerData!['height'] != null)
        {'label': 'Height', 'value': _customerData!['height'], 'unit': 'cm'},
      if (_customerData!['weight'] != null)
        {'label': 'Weight', 'value': _customerData!['weight'], 'unit': 'kg'},
      if (_customerData!['bust_chest'] != null)
        {
          'label': 'Bust/Chest',
          'value': _customerData!['bust_chest'],
          'unit': 'inch',
        },
      if (_customerData!['waist'] != null)
        {'label': 'Waist', 'value': _customerData!['waist'], 'unit': 'inch'},
      if (_customerData!['hip'] != null)
        {'label': 'Hip', 'value': _customerData!['hip'], 'unit': 'inch'},
      if (_customerData!['shoulder_width'] != null)
        {
          'label': 'Shoulder',
          'value': _customerData!['shoulder_width'],
          'unit': 'inch',
        },
      if (_customerData!['sleeve_length'] != null)
        {
          'label': 'Sleeve',
          'value': _customerData!['sleeve_length'],
          'unit': 'inch',
        },
      if (_customerData!['garment_length'] != null)
        {
          'label': 'Length',
          'value': _customerData!['garment_length'],
          'unit': 'inch',
        },
      if (_customerData!['armhole'] != null)
        {
          'label': 'Armhole',
          'value': _customerData!['armhole'],
          'unit': 'inch',
        },
      if (_customerData!['upper_arm_bicep'] != null)
        {
          'label': 'Upper Arm',
          'value': _customerData!['upper_arm_bicep'],
          'unit': 'inch',
        },
    ];

    if (measurements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEASUREMENTS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: measurements
                .map(
                  (m) => _measurementField(
                    m['label'] as String,
                    m['value'],
                    m['unit'] as String,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotes() {
    final notes = widget.orderData['notes'];
    if (notes == null || notes.toString().isEmpty)
      return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER NOTES:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(notes.toString()),
        ],
      ),
    );
  }

  Widget _buildChangeRequests() {
    final changeRequests = widget.orderData['change_requests'] as List? ?? [];
    if (changeRequests.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.change_circle, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'CHANGE REQUESTS:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...changeRequests.map(
            (cr) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getChangeRequestColor(cr['status']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cr['status_display'] ?? cr['status'] ?? 'PENDING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Requested: ${cr['requested_date'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cr['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: Colors.black, thickness: 2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Signature:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.black),
                ],
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Authorized Signature:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Thank you for your business!',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildPrintActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print functionality coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Widget _printField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isNegative = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: isNegative ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementField(String label, dynamic value, String unit) {
    return SizedBox(
      width: 140,
      child: Text('$label: $value $unit', style: const TextStyle(fontSize: 12)),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'READY':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getChangeRequestColor(String? status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
