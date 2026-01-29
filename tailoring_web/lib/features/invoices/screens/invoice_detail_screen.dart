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
      currentSection: 'invoices',
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
}
