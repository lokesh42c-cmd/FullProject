import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/features/invoices/providers/invoice_provider.dart';
import 'package:tailoring_web/features/invoices/models/invoice.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  final _apiClient = ApiClient();

  String _statusFilter = 'ALL';
  int? _selectedCustomerId;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchInvoices(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final response = await _apiClient.get('orders/customers/');
      if (response.data is List) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(response.data);
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      print('Error loading customers: $e');
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _applyFilters() {
    final provider = context.read<InvoiceProvider>();
    if (_statusFilter != 'ALL') {
      provider.setStatusFilter(_statusFilter);
    }
    provider.fetchInvoices(refresh: true);
  }

  List<Invoice> get _filteredInvoices {
    final provider = context.watch<InvoiceProvider>();

    List<Invoice> invoices = [];
    for (var item in provider.invoices) {
      if (item is Invoice) {
        invoices.add(item);
      } else if (item is Map<String, dynamic>) {
        invoices.add(Invoice.fromJson(item));
      }
    }

    if (_selectedCustomerId != null) {
      invoices = invoices
          .where((inv) => inv.customer == _selectedCustomerId)
          .toList();
    }

    if (_startDate != null && _endDate != null) {
      invoices = invoices.where((inv) {
        try {
          final invDate = DateTime.parse(inv.invoiceDate);
          return invDate.isAfter(
                _startDate!.subtract(const Duration(days: 1)),
              ) &&
              invDate.isBefore(_endDate!.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    return invoices;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    return MainLayout(
      currentRoute: '/invoices',
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                ? _buildEmptyState()
                : _buildInvoicesTable(),
          ),
        ],
      ),
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
          const Text('Invoices', style: AppTheme.heading2),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/invoices/create'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Invoice'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    style: AppTheme.bodySmall,
                    decoration: const InputDecoration(
                      hintText: 'Search by invoice # or customer...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      context.read<InvoiceProvider>().setSearchQuery(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),

              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    style: AppTheme.bodySmall,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                      DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'PARTIAL',
                        child: Text('Partial'),
                      ),
                      DropdownMenuItem(value: 'UNPAID', child: Text('Unpaid')),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _statusFilter = value!);
                      _applyFilters();
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),

              Container(
                height: 40,
                width: 200,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedCustomerId,
                    style: AppTheme.bodySmall,
                    isDense: true,
                    hint: const Text('All Customers'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Customers'),
                      ),
                      ..._customers.map((customer) {
                        return DropdownMenuItem<int?>(
                          value: customer['id'],
                          child: Text(
                            customer['name'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCustomerId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),

              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _startDate != null && _endDate != null
                      ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                      : 'Date Range',
                  style: AppTheme.bodySmall,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),

              if (_startDate != null && _endDate != null) ...[
                const SizedBox(width: AppTheme.space2),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clearDateRange,
                  tooltip: 'Clear date filter',
                ),
              ],

              const SizedBox(width: AppTheme.space3),

              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  context.read<InvoiceProvider>().fetchInvoices(refresh: true);
                },
                tooltip: 'Refresh',
              ),
            ],
          ),

          if (_statusFilter != 'ALL' ||
              _selectedCustomerId != null ||
              _startDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text('Active Filters: ', style: AppTheme.bodySmall),
                  if (_statusFilter != 'ALL')
                    _buildFilterChip('Status: $_statusFilter', () {
                      setState(() => _statusFilter = 'ALL');
                      _applyFilters();
                    }),
                  if (_selectedCustomerId != null)
                    _buildFilterChip(
                      'Customer: ${_customers.firstWhere((c) => c['id'] == _selectedCustomerId, orElse: () => {'name': 'Unknown'})['name']}',
                      () {
                        setState(() => _selectedCustomerId = null);
                      },
                    ),
                  if (_startDate != null)
                    _buildFilterChip(
                      'Date: ${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                      _clearDateRange,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onClear) {
    return Chip(
      label: Text(label, style: AppTheme.bodySmall),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onClear,
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildInvoicesTable() {
    final invoices = _filteredInvoices;

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.all(AppTheme.space5),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1040),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: AppTheme.backgroundGrey,
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 160,
                        child: Text('INVOICE #', style: AppTheme.tableHeader),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text('CUSTOMER', style: AppTheme.tableHeader),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text('ORDER #', style: AppTheme.tableHeader),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          'INVOICE DATE',
                          style: AppTheme.tableHeader,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text('TOTAL', style: AppTheme.tableHeader),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text('PAID', style: AppTheme.tableHeader),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text('BALANCE', style: AppTheme.tableHeader),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text('STATUS', style: AppTheme.tableHeader),
                      ),
                    ],
                  ),
                ),
                ...invoices
                    .map((invoice) => _buildInvoiceRow(invoice))
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(Invoice invoice) {
    final isCancelled = invoice.status == 'CANCELLED';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: InkWell(
        onTap: () {
          if (invoice.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    InvoiceDetailScreen(invoiceId: invoice.id!),
              ),
            ).then((_) {
              context.read<InvoiceProvider>().fetchInvoices(refresh: true);
            });
          }
        },
        hoverColor: AppTheme.backgroundGrey.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  invoice.invoiceNumber,
                  style: AppTheme.bodyMediumBold.copyWith(
                    color: isCancelled
                        ? AppTheme.textMuted
                        : AppTheme.primaryBlue,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.customerName ?? 'Unknown',
                      style: AppTheme.bodyMedium.copyWith(
                        decoration: isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (invoice.customerPhone != null)
                      Text(
                        invoice.customerPhone!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              SizedBox(
                width: 140,
                child: Text(
                  invoice.orderNumber ?? '-',
                  style: AppTheme.bodyMedium.copyWith(
                    color: invoice.orderNumber != null
                        ? AppTheme.primaryBlue
                        : AppTheme.textMuted,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(
                width: 110,
                child: Text(
                  _formatDate(DateTime.parse(invoice.invoiceDate)),
                  style: AppTheme.bodyMedium,
                ),
              ),

              SizedBox(
                width: 110,
                child: Text(
                  '₹${invoice.grandTotal.toStringAsFixed(0)}',
                  style: AppTheme.bodyMediumBold,
                  textAlign: TextAlign.right,
                ),
              ),

              SizedBox(
                width: 110,
                child: Text(
                  '₹${invoice.totalPaid.toStringAsFixed(0)}',
                  style: AppTheme.bodyMediumBold.copyWith(
                    color: AppTheme.success,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              SizedBox(
                width: 110,
                child: Text(
                  '₹${invoice.remainingBalance.toStringAsFixed(0)}',
                  style: AppTheme.bodyMediumBold.copyWith(
                    color: invoice.remainingBalance > 0
                        ? AppTheme.warning
                        : AppTheme.success,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              SizedBox(
                width: 120,
                child: _buildStatusBadge(invoice.paymentStatus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'PAID':
        bgColor = AppTheme.success.withOpacity(0.1);
        textColor = AppTheme.success;
        label = 'PAID';
        break;
      case 'PARTIAL':
        bgColor = AppTheme.warning.withOpacity(0.1);
        textColor = AppTheme.warning;
        label = 'PARTIAL';
        break;
      case 'CANCELLED':
        bgColor = AppTheme.danger.withOpacity(0.1);
        textColor = AppTheme.danger;
        label = 'CANCELLED';
        break;
      default:
        bgColor = AppTheme.textMuted.withOpacity(0.1);
        textColor = AppTheme.textMuted;
        label = 'UNPAID';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        label,
        style: AppTheme.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'No invoices found',
            style: AppTheme.heading3.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            'Create your first invoice to get started',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.space5),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/invoices/create'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Invoice'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
