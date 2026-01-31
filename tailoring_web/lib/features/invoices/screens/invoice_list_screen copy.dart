import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final TextEditingController _searchController = TextEditingController();

  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = false;
  String _selectedStatusFilter = 'ALL';
  String _selectedPaymentFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().get('invoices/invoices/');

      if (response.data is List) {
        final invoices = (response.data as List)
            .map((json) => Invoice.fromJson(json))
            .toList();

        setState(() {
          _invoices = invoices;
          _applyFilters();
        });
      }
    } catch (e) {
      print('Error loading invoices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load invoices: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Invoice> filtered = _invoices;

    // Status filter
    if (_selectedStatusFilter != 'ALL') {
      filtered = filtered
          .where((invoice) => invoice.status == _selectedStatusFilter)
          .toList();
    }

    // Payment status filter
    if (_selectedPaymentFilter != 'ALL') {
      filtered = filtered
          .where((invoice) => invoice.paymentStatus == _selectedPaymentFilter)
          .toList();
    }

    // Search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        return invoice.invoiceNumber.toLowerCase().contains(searchQuery) ||
            (invoice.customerName?.toLowerCase().contains(searchQuery) ??
                false) ||
            (invoice.orderNumber?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    setState(() {
      _filteredInvoices = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _onCreateInvoice,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by invoice, customer, or order...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => _applyFilters(),
                ),

                const SizedBox(height: 16),

                // Filter Row
                Row(
                  children: [
                    const Text(
                      'Filters:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),

                    // Status Filter
                    DropdownButton<String>(
                      value: _selectedStatusFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                        DropdownMenuItem(
                          value: 'ISSUED',
                          child: Text('Issued'),
                        ),
                        DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                        DropdownMenuItem(
                          value: 'CANCELLED',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatusFilter = value!);
                        _applyFilters();
                      },
                    ),

                    const SizedBox(width: 20),

                    // Payment Status Filter
                    DropdownButton<String>(
                      value: _selectedPaymentFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Payment Status'),
                        ),
                        DropdownMenuItem(
                          value: 'UNPAID',
                          child: Text('Unpaid'),
                        ),
                        DropdownMenuItem(
                          value: 'PARTIAL',
                          child: Text('Partial'),
                        ),
                        DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPaymentFilter = value!);
                        _applyFilters();
                      },
                    ),

                    const Spacer(),

                    // Result Count
                    Text(
                      '${_filteredInvoices.length} invoice(s)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Refresh Button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadInvoices,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Invoice List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                ? _buildEmptyState()
                : _buildInvoiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchController.text.isNotEmpty ||
        _selectedStatusFilter != 'ALL' ||
        _selectedPaymentFilter != 'ALL';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No invoices found' : 'No invoices yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your filters'
                : 'Create your first invoice',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (!hasFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onCreateInvoice,
              icon: const Icon(Icons.add),
              label: const Text('Create Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredInvoices.length,
        itemBuilder: (context, index) {
          final invoice = _filteredInvoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _onViewInvoice(invoice),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Invoice Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryBlue,
                ),
              ),

              const SizedBox(width: 16),

              // Invoice Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(invoice.status),
                        const SizedBox(width: 8),
                        _buildPaymentStatusBadge(invoice.paymentStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          invoice.customerName ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        if (invoice.orderNumber != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.shopping_bag,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invoice.orderNumber!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 16),
                          Text(
                            'Walk-in',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          invoice.invoiceDate,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${invoice.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  if (invoice.remainingBalance > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Due: ₹${invoice.remainingBalance.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, color: AppTheme.danger),
                    ),
                  ],
                ],
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'DRAFT':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'ISSUED':
        color = AppTheme.primaryBlue;
        label = 'Issued';
        break;
      case 'PAID':
        color = AppTheme.success;
        label = 'Paid';
        break;
      case 'CANCELLED':
        color = AppTheme.danger;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String paymentStatus) {
    Color color;
    String label;

    switch (paymentStatus) {
      case 'UNPAID':
        color = AppTheme.danger;
        label = 'Unpaid';
        break;
      case 'PARTIAL':
        color = AppTheme.warning;
        label = 'Partial';
        break;
      case 'PAID':
        color = AppTheme.success;
        label = 'Paid';
        break;
      default:
        color = Colors.grey;
        label = paymentStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _onCreateInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
    ).then((_) => _loadInvoices());
  }

  void _onViewInvoice(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoiceId: invoice.id!),
      ),
    ).then((_) => _loadInvoices());
  }
}
