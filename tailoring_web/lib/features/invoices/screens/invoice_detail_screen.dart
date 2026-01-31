import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../../../core/layouts/main_layout.dart';
import 'invoice_detail_tabs/invoice_details_tab.dart';
import 'invoice_detail_tabs/invoice_payments_tab.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _apiClient = ApiClient();
  Map<String, dynamic>? _invoiceData;
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.get(
        'invoicing/invoices/${widget.invoiceId}/',
      );
      setState(() {
        _invoiceData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/invoices',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoiceData == null
          ? const Center(child: Text('Invoice not found'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: AppTheme.space4),
        _buildTabs(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildHeader() {
    final status = _invoiceData!['status'] ?? 'DRAFT';
    final totalPaid = _invoiceData!['total_paid'] ?? 0;
    final canCancel = status != 'CANCELLED' && totalPaid == 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppTheme.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice Details', style: AppTheme.heading2),
              Text(
                _invoiceData!['invoice_number'] ?? 'N/A',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
          const Spacer(),
          _buildStatusBadge(),
          const SizedBox(width: AppTheme.space3),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Print invoice
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
          ),
          const SizedBox(width: AppTheme.space2),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Email invoice
            },
            icon: const Icon(Icons.email, size: 18),
            label: const Text('Email'),
          ),
          // ✅ NEW: Cancel Invoice Button
          if (canCancel) ...[
            const SizedBox(width: AppTheme.space2),
            OutlinedButton.icon(
              onPressed: _onCancelInvoice,
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Cancel Invoice'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = _invoiceData!['status'] ?? 'DRAFT';
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'ISSUED':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'PAID':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'CANCELLED':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        _invoiceData!['status_display'] ?? status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [_buildTab('Invoice Details', 0), _buildTab('Payments', 1)],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return InvoiceDetailsTab(invoiceData: _invoiceData!);
      case 1:
        return InvoicePaymentsTab(
          invoiceId: widget.invoiceId,
          invoiceData: _invoiceData!,
          onPaymentRecorded: _loadInvoiceDetails,
        );
      default:
        return const SizedBox();
    }
  }

  // ✅ NEW: Cancel Invoice Handler
  void _onCancelInvoice() async {
    // Check for payments first
    final totalPaid = _invoiceData!['total_paid'] ?? 0;

    if (totalPaid > 0) {
      _showPaymentsExistDialog();
      return;
    }

    // Show reason dialog
    final reason = await _showCancelReasonDialog();
    if (reason == null) return;

    // Cancel invoice
    try {
      await _apiClient.post(
        'invoicing/invoices/${widget.invoiceId}/cancel/',
        data: {'reason': reason},
      );

      await _loadInvoiceDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice cancelled successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel invoice: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  // ✅ NEW: Show dialog when payments exist
  void _showPaymentsExistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: AppTheme.warning),
            SizedBox(width: 12),
            Text('Cannot Cancel Invoice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This invoice has payments recorded. You must delete all payments before cancelling the invoice.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total Paid: ₹${_invoiceData!['total_paid']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedTabIndex = 1); // Switch to Payments tab
            },
            child: const Text('Go to Payments'),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Cancel Reason Dialog
  Future<String?> _showCancelReasonDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoice: ${_invoiceData!['invoice_number']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Amount: ₹${_invoiceData!['grand_total']}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '⚠️ This action cannot be undone',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Reason for cancellation *',
                  hintText: 'Enter reason...',
                  helperText: 'Required',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reason is required'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }
}
