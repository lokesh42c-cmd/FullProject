import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/orders/widgets/dialogs/edit_order_details_dialog.dart';
import 'dart:html' as html;

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool isLocked;
  final Future<void> Function() onRefresh;

  const OverviewTab({
    super.key,
    required this.orderData,
    required this.isLocked,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _orderDetailsCard(context),
            const SizedBox(height: 16),
            _notesSection(context),
            const SizedBox(height: 16),
            _bottomSection(context),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // ORDER DETAILS CARD
  // ─────────────────────────────
  Widget _orderDetailsCard(BuildContext context) {
    // ✅ CHANGE 4: Check if can edit after invoice
    final hasInvoice = orderData['invoice_id'] != null;
    final canEdit = !isLocked || (hasInvoice && _canEditAfterInvoice());

    return Card(
      color: Colors.white,
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
            Row(
              children: [
                const Icon(Icons.description, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Order Details',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // ✅ FIXED: Edit button - allow editing certain fields even after invoice
                if (canEdit)
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    onPressed: () => _onEditOrderDetails(context),
                    tooltip: 'Edit Order Details',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            _row(
              'Customer',
              orderData['customer_name'],
              'Phone',
              orderData['customer_phone'],
            ),
            _row(
              'Status',
              orderData['order_status_display'],
              'Delivery',
              orderData['delivery_status_display'],
            ),
            _row(
              'Order Date',
              orderData['order_date'],
              'Expected',
              orderData['expected_delivery_date'],
            ),
            _row(
              'Actual',
              orderData['actual_delivery_date'] ?? 'Not Delivered',
              'Priority',
              orderData['priority'],
              isChip: true,
            ),
            _row(
              'Invoice',
              orderData['invoice_number'] ?? 'Not Created',
              'Assigned',
              orderData['assigned_to_name'] ?? 'Not Assigned',
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Check if can edit after invoice
  bool _canEditAfterInvoice() {
    // Can edit status, dates, priority, assigned, change requests after invoice
    return orderData['invoice_id'] != null;
  }

  // ─────────────────────────────
  // NOTES SECTION
  // ─────────────────────────────
  Widget _notesSection(BuildContext context) {
    return Column(
      children: [
        _expandTile(
          context,
          title: 'Order Notes',
          content: orderData['order_summary'],
          showEdit: false,
        ),
        const SizedBox(height: 8),
        _expandTile(
          context,
          title: 'Change Requests',
          content: orderData['customer_instructions'],
          showEdit: true,
          onEdit: () => _onEditChangeRequests(context),
        ),
      ],
    );
  }

  // ─────────────────────────────
  // BOTTOM SECTION - WITH REFERENCE PHOTOS
  // ─────────────────────────────
  Widget _bottomSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ CHANGE 5: ADD REFERENCE PHOTOS SECTION
        _buildReferencePhotosSection(context),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      Icon(Icons.qr_code, size: 80),
                      SizedBox(height: 8),
                      Text('Tap to view'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              fit: FlexFit.loose,
              child: Card(
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
                      _recordRow(
                        'Created By',
                        orderData['created_by']?.toString(),
                      ),
                      _recordRow('Created At', orderData['created_at']),
                      const SizedBox(height: 8),
                      if (orderData['updated_at'] != null) ...[
                        _recordRow(
                          'Updated By',
                          orderData['updated_by']?.toString(),
                        ),
                        _recordRow('Updated At', orderData['updated_at']),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ NEW: Reference Photos Section
  Widget _buildReferencePhotosSection(BuildContext context) {
    final referencePhotos = orderData['reference_photos'] as List? ?? [];

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
            Row(
              children: [
                const Icon(Icons.photo_library, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Reference Photos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Upload button - can upload even after invoice
                if (!isLocked || _canEditAfterInvoice())
                  ElevatedButton.icon(
                    onPressed: () => _onUploadPhoto(context),
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Upload Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (referencePhotos.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.photo, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No reference photos uploaded',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: referencePhotos.length,
                itemBuilder: (context, index) {
                  final photo = referencePhotos[index];

                  // ✅ FIXED: Use photo_url not url, and add base URL
                  final photoUrl = photo['photo_url'] ?? '';
                  final fullUrl = photoUrl.startsWith('http')
                      ? photoUrl
                      : 'http://localhost:8000$photoUrl';

                  return GestureDetector(
                    onTap: () => _onViewPhoto(context, fullUrl),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Failed to load',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // HELPERS
  // ─────────────────────────────
  Widget _row(
    String l1,
    String? v1,
    String l2,
    String? v2, {
    bool isChip = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: _kv(l1, v1)),
          Expanded(child: _kv(l2, v2, isChip: isChip)),
        ],
      ),
    );
  }

  Widget _kv(String label, String? value, {bool isChip = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        if (isChip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(value).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _getPriorityColor(value).withOpacity(0.3),
              ),
            ),
            child: Text(
              value ?? '-',
              style: TextStyle(
                color: _getPriorityColor(value),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Flexible(child: Text(value ?? '-', overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'HIGH':
        return AppTheme.danger;
      case 'MEDIUM':
        return AppTheme.warning;
      case 'LOW':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _recordRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value ?? '-'),
        ],
      ),
    );
  }

  Widget _expandTile(
    BuildContext context, {
    required String title,
    required String? content,
    bool showEdit = false,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (showEdit && (!isLocked || _canEditAfterInvoice()))
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: onEdit,
                tooltip: 'Edit $title',
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text((content == null || content.isEmpty) ? '-' : content),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // ACTION HANDLERS
  // ─────────────────────────────

  /// ✅ Opens dialog to edit order details (dates, priority, payment terms)
  void _onEditOrderDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditOrderDetailsDialog(
        orderData: orderData,
        onSaved: () async {
          await onRefresh();
        },
      ),
    );
  }

  /// ✅ Opens dialog to edit change requests (customer instructions)
  void _onEditChangeRequests(BuildContext context) {
    final ApiClient apiClient = ApiClient();
    final TextEditingController controller = TextEditingController(
      text: orderData['customer_instructions'] ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Change Requests'),
            content: SizedBox(
              width: 500,
              child: TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Customer Instructions',
                  hintText: 'Enter any special requests or changes...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);

                        try {
                          await apiClient.patch(
                            'orders/orders/${orderData['id']}/',
                            data: {
                              'customer_instructions': controller.text.trim(),
                            },
                          );

                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            await onRefresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Change requests updated successfully',
                                ),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } on ApiException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.message),
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update: $e'),
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => isSaving = false);
                          }
                        }
                      },
                child: isSaving
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
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ✅ NEW: Upload photo handler
  void _onUploadPhoto(BuildContext context) async {
    final apiClient = ApiClient();

    try {
      // Create file input element
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      await input.onChange.first;

      if (input.files!.isEmpty) return;

      final file = input.files!.first;
      final reader = html.FileReader();

      reader.readAsDataUrl(file);
      await reader.onLoad.first;

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading photo...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Upload to server
      final formData = {
        'order': orderData['id'],
        'photo': reader.result,
        'photo_name': file.name,
      };

      await apiClient.post(
        'orders/orders/${orderData['id']}/upload_photo/',
        data: formData,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        await onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  /// ✅ NEW: View photo in full screen
  void _onViewPhoto(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(photoUrl))),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
