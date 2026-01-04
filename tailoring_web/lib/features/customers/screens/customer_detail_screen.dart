import 'package:flutter/material.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/customers/models/customer.dart';
import 'package:tailoring_web/features/customers/widgets/add_edit_customer_dialog.dart';
import 'package:tailoring_web/features/customers/widgets/measurement_dialog.dart';
import 'package:tailoring_web/features/customers/widgets/view_measurements_dialog.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _apiClient = ApiClient();
  Customer? _customer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get(
        'orders/customers/${widget.customerId}/',
      );
      setState(() {
        _customer = Customer.fromJson(response.data);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load customer details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/customers',
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(width: 12),
                Text(
                  _customer?.name ?? 'Customer Details',
                  style: AppTheme.heading2,
                ),
                const Spacer(),
                if (_customer != null)
                  ElevatedButton.icon(
                    onPressed: _handleEditCustomer,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Customer'),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.danger,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCustomer,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_customer == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Customer Info | Address | Measurements (Equal Heights)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Information - Compact
                Expanded(flex: 2, child: _buildCustomerInfoCard()),
                const SizedBox(width: 16),

                // Address
                Expanded(flex: 1, child: _buildAddressCard()),
                const SizedBox(width: 16),

                // Measurements
                Expanded(flex: 1, child: _buildMeasurementsCard()),
              ],
            ),
          ),

          // Business Info (if applicable) - Full Width
          if (_customer!.isBusiness) ...[
            const SizedBox(height: 16),
            _buildBusinessInfoCard(),
          ],

          // Orders Section - Full Width with More Space
          const SizedBox(height: 16),
          _buildOrdersCard(),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              const Text('Customer Information', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          // Compact 2-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactInfoRow('Name', _customer!.name),
                    const SizedBox(height: 12),
                    _buildCompactInfoRow('Phone', _customer!.phone),
                    const SizedBox(height: 12),
                    if (_customer!.whatsappNumber != null)
                      _buildCompactInfoRow(
                        'WhatsApp',
                        _customer!.whatsappNumber!,
                      )
                    else
                      _buildCompactInfoRow('WhatsApp', '-'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_customer!.email != null)
                      _buildCompactInfoRow('Email', _customer!.email!)
                    else
                      _buildCompactInfoRow('Email', '-'),
                    const SizedBox(height: 12),
                    if (_customer!.gender != null)
                      _buildCompactInfoRow('Gender', _customer!.gender!)
                    else
                      _buildCompactInfoRow('Gender', '-'),
                    const SizedBox(height: 12),
                    _buildCompactInfoRow(
                      'Type',
                      _customer!.customerType == 'BUSINESS'
                          ? 'Business'
                          : 'Individual',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.danger, size: 18),
              const SizedBox(width: 8),
              const Text('Address', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _customer!.fullAddress.isNotEmpty
                ? _customer!.fullAddress
                : 'No address provided',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsCard() {
    final hasMeasurements = _customer!.hasMeasurements;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.straighten,
                color: hasMeasurements ? AppTheme.success : AppTheme.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Measurements', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                hasMeasurements ? Icons.check_circle : Icons.warning_amber,
                size: 16,
                color: hasMeasurements ? AppTheme.success : AppTheme.warning,
              ),
              const SizedBox(width: 6),
              Text(
                hasMeasurements ? 'Available' : 'Not Available',
                style: AppTheme.bodySmall.copyWith(
                  color: hasMeasurements ? AppTheme.success : AppTheme.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasMeasurements)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleViewMeasurements,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('View', style: AppTheme.bodySmall),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleAddMeasurements,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Edit', style: AppTheme.bodySmall),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleAddMeasurements,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Add', style: AppTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business,
                color: AppTheme.accentOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Business Information', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoRow(
                  'Business Name',
                  _customer!.businessName ?? '-',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCompactInfoRow('GSTIN', _customer!.gstin ?? '-'),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCompactInfoRow('PAN', _customer!.pan ?? '-'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, color: AppTheme.info, size: 18),
              const SizedBox(width: 8),
              const Text('Orders', style: AppTheme.heading3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_customer!.totalOrders ?? 0}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Orders will be displayed here
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No orders yet',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders placed by this customer will appear here',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
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

  Widget _buildCompactInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _handleEditCustomer() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditCustomerDialog(
        customerId: widget.customerId,
        customerData: _customer!.toJson(),
      ),
    );

    if (result == true) {
      _loadCustomer();
    }
  }

  Future<void> _handleViewMeasurements() async {
    if (_customer == null) return;

    final shouldEdit = await showDialog<bool>(
      context: context,
      builder: (context) => ViewMeasurementsDialog(customer: _customer!),
    );

    if (shouldEdit == true) {
      _handleAddMeasurements();
    }
  }

  Future<void> _handleAddMeasurements() async {
    if (_customer == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MeasurementDialog(customer: _customer!),
    );

    if (result == true) {
      _loadCustomer();
    }
  }
}
