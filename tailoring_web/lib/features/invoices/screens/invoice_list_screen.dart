import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/features/invoices/models/invoice.dart';
import 'package:tailoring_web/features/invoices/providers/invoice_provider.dart';
import 'package:tailoring_web/features/invoices/screens/create_invoice_screen.dart';
import 'package:tailoring_web/features/invoices/screens/invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/invoices',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
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
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invoices', style: AppTheme.heading2),
              Text(
                'Manage customer invoices',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
              );
              if (result == true && mounted) {
                context.read<InvoiceProvider>().fetchInvoices(refresh: true);
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Invoice'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: 20),
          Expanded(child: _buildInvoiceTable()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by invoice number, customer...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (value) {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.filter_list, size: 18),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                DropdownMenuItem(value: 'ISSUED', child: Text('Issued')),
                DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                context.read<InvoiceProvider>().setStatusFilter(value);
                context.read<InvoiceProvider>().fetchInvoices(refresh: true);
              },
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _searchController.clear();
              });
              context.read<InvoiceProvider>().clearFilters();
              context.read<InvoiceProvider>().fetchInvoices(refresh: true);
            },
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTable() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.invoices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.danger,
                ),
                const SizedBox(height: 16),
                Text(provider.errorMessage!, style: AppTheme.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchInvoices(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No invoices found',
                  style: AppTheme.heading3.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.invoices.length,
                  itemBuilder: (context, index) {
                    return _buildInvoiceRow(provider.invoices[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: AppTheme.backgroundGrey),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text('INVOICE', style: AppTheme.tableHeader),
          ),
          Expanded(flex: 2, child: Text('ORDER', style: AppTheme.tableHeader)),
          Expanded(
            flex: 2,
            child: Text('CUSTOMER', style: AppTheme.tableHeader),
          ),
          Expanded(flex: 2, child: Text('TOTAL', style: AppTheme.tableHeader)),
          Expanded(
            flex: 2,
            child: Text('PAID', style: AppTheme.tableHeader),
          ), // Column added
          Expanded(
            flex: 2,
            child: Text('BALANCE', style: AppTheme.tableHeader),
          ), // Column added
          Expanded(flex: 2, child: Text('STATUS', style: AppTheme.tableHeader)),
          SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(Invoice invoice) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id!),
          ),
        );
        if (mounted) {
          context.read<InvoiceProvider>().fetchInvoices(refresh: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            // Invoice
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: AppTheme.fontSemibold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(DateTime.parse(invoice.invoiceDate)),
                    style: AppTheme.bodyXSmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Order Number
            Expanded(
              flex: 2,
              child: Text(
                invoice.orderNumber ?? 'Walk-in',
                style: AppTheme.bodySmall,
              ),
            ),

            // Customer
            Expanded(
              flex: 2,
              child: Text(
                invoice.customerName ?? 'N/A',
                style: AppTheme.bodySmall,
              ),
            ),

            // Grand Total
            Expanded(
              flex: 2,
              child: Text(
                '₹${invoice.grandTotal.toStringAsFixed(2)}',
                style: AppTheme.bodySmall,
              ),
            ),

            // Paid Amount - Pulling from invoice.totalPaid
            Expanded(
              flex: 2,
              child: Text(
                '₹${invoice.totalPaid.toStringAsFixed(2)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.success,
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ),

            // Remaining Balance - Pulling from invoice.remainingBalance
            Expanded(
              flex: 2,
              child: Text(
                '₹${invoice.remainingBalance.toStringAsFixed(2)}',
                style: AppTheme.bodySmall.copyWith(
                  color: invoice.remainingBalance > 0
                      ? AppTheme.danger
                      : AppTheme.success,
                  fontWeight: AppTheme.fontSemibold,
                ),
              ),
            ),

            // Status Badge
            Expanded(flex: 2, child: _buildStatusBadge(invoice.status)),

            // Actions
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InvoiceDetailScreen(invoiceId: invoice.id!),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'DRAFT':
        color = AppTheme.textMuted;
        break;
      case 'ISSUED':
        color = AppTheme.info;
        break;
      case 'PAID':
        color = AppTheme.success;
        break;
      case 'CANCELLED':
        color = AppTheme.danger;
        break;
      default:
        color = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          status,
          style: AppTheme.bodyXSmall.copyWith(
            color: color,
            fontWeight: AppTheme.fontSemibold,
          ),
        ),
      ),
    );
  }
}
