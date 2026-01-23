import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

class OrderQrDialog extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderQrDialog({Key? key, required this.orderData}) : super(key: key);

  String _generateQrData() {
    // Generate QR data with order information
    final orderNumber = orderData['order_number'] ?? 'N/A';
    final customerName = orderData['customer_name'] ?? 'N/A';
    final total = orderData['estimated_total'] ?? 0.0;
    final status = orderData['status'] ?? 'PENDING';

    // Create a simple text format for QR code
    // In production, this could be a URL like: https://yourapp.com/orders/ORD-123
    return '''
ORDER: $orderNumber
CUSTOMER: $customerName
AMOUNT: ₹${total.toStringAsFixed(2)}
STATUS: $status
'''
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = orderData['order_number'] ?? 'N/A';
    final customerName = orderData['customer_name'] ?? 'N/A';
    final total = (orderData['estimated_total'] ?? 0.0).toDouble();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Order QR Code', style: AppTheme.heading2),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Order Info Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Order Number', orderNumber, Icons.tag),
                  const SizedBox(height: 8),
                  _buildInfoRow('Customer', customerName, Icons.person),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Total Amount',
                    '₹${total.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight, width: 2),
              ),
              child: QrImageView(
                data: _generateQrData(),
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
            const SizedBox(height: 16),

            // Helper text
            Text(
              'Scan this QR code to view order details',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Download feature coming soon!'),
                          backgroundColor: AppTheme.primaryBlue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement print functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Print feature coming soon!'),
                          backgroundColor: AppTheme.primaryBlue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
