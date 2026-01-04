import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/providers/vendor_provider.dart';
import 'package:tailoring_web/features/purchase_management/screens/vendors/add_edit_vendor_dialog.dart';
import 'package:tailoring_web/features/purchase_management/screens/bills/bill_detail_screen.dart';
import 'package:intl/intl.dart';

class VendorDetailScreen extends StatefulWidget {
  final int vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd-MMM-yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchVendor(widget.vendorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProvider>();
    final vendor = provider.currentVendor;

    return MainLayout(
      currentRoute: '/purchase/vendors',
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : vendor == null
          ? const Center(child: Text('Vendor not found'))
          : Column(
              children: [
                Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vendor.name, style: AppTheme.heading2),
                            if (vendor.businessName != null)
                              Text(vendor.businessName!, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _handleEditVendor(provider),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: AppTheme.space2),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') _handleDeleteVendor(provider);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: AppTheme.danger),
                                SizedBox(width: 8),
                                Text('Delete Vendor'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFinancialSummary(vendor),
                        const SizedBox(height: AppTheme.space5),
                        _buildContactInfo(vendor),
                        const SizedBox(height: AppTheme.space5),
                        _buildRecentBills(vendor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFinancialSummary(vendor) {
    final totalPurchases = double.tryParse(vendor.totalPurchases) ?? 0.0;
    final totalPaid = double.tryParse(vendor.totalPaid) ?? 0.0;
    final outstanding = double.tryParse(vendor.outstandingBalance) ?? 0.0;
    final hasOutstanding = outstanding > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Financial Summary', style: AppTheme.heading3),
        const SizedBox(height: AppTheme.space3),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Purchases', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: AppTheme.space2),
                    Text(_currencyFormat.format(totalPurchases), style: AppTheme.heading2),
                    const SizedBox(height: AppTheme.space1),
                    Text('${vendor.totalBills ?? 0} bills', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Paid', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: AppTheme.space2),
                    Text(_currencyFormat.format(totalPaid), style: AppTheme.heading2.copyWith(color: AppTheme.success)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  color: hasOutstanding ? AppTheme.danger.withOpacity(0.1) : AppTheme.backgroundWhite,
                  border: Border.all(color: hasOutstanding ? AppTheme.danger : AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: AppTheme.space2),
                    Text(_currencyFormat.format(outstanding), style: AppTheme.heading2.copyWith(color: hasOutstanding ? AppTheme.danger : AppTheme.textPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo(vendor) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.space3),
          _buildInfoRow(Icons.phone, 'Phone', vendor.phone),
          if (vendor.alternatePhone != null) _buildInfoRow(Icons.phone_android, 'Alternate Phone', vendor.alternatePhone!),
          if (vendor.email != null) _buildInfoRow(Icons.email, 'Email', vendor.email!),
          if (vendor.addressLine1 != null || vendor.city != null) ...[
            const Divider(height: AppTheme.space4),
            _buildInfoRow(Icons.location_on, 'Address', [vendor.addressLine1, vendor.addressLine2, vendor.city, vendor.state, vendor.pincode].where((e) => e != null && e.isNotEmpty).join(', ')),
          ],
          if (vendor.gstin != null || vendor.pan != null) ...[
            const Divider(height: AppTheme.space4),
            if (vendor.gstin != null) _buildInfoRow(Icons.receipt_long, 'GSTIN', vendor.gstin!),
            if (vendor.pan != null) _buildInfoRow(Icons.credit_card, 'PAN', vendor.pan!),
          ],
          if (vendor.paymentTermsDays != null) ...[
            const Divider(height: AppTheme.space4),
            _buildInfoRow(Icons.schedule, 'Payment Terms', '${vendor.paymentTermsDays} days'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: AppTheme.space2),
          SizedBox(width: 120, child: Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: AppTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildRecentBills(vendor) {
    final bills = vendor.recentBills ?? [];
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent Bills', style: AppTheme.heading3),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          if (bills.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(AppTheme.space4), child: Text('No bills yet')))
          else
            ...bills.map((bill) {
              return InkWell(
                onTap: () async {
                  if (bill.id != null) {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => BillDetailScreen(billId: bill.id!)));
                    context.read<VendorProvider>().fetchVendor(widget.vendorId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space3),
                  margin: const EdgeInsets.only(bottom: AppTheme.space2),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.borderLight), borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(bill.billNumber, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(width: AppTheme.space2),
                                _buildStatusBadge(bill.paymentStatus),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space1),
                            Text(_dateFormat.format(bill.billDate), style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_currencyFormat.format(bill.billAmountDouble), style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          if (bill.balanceAmountDouble > 0) Text('Bal: ${_currencyFormat.format(bill.balanceAmountDouble)}', style: AppTheme.bodySmall.copyWith(color: AppTheme.danger)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'UNPAID':
        color = AppTheme.danger;
        break;
      case 'PARTIALLY_PAID':
        color = AppTheme.warning;
        break;
      case 'FULLY_PAID':
        color = AppTheme.success;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.replaceAll('_', ' '), style: AppTheme.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }

  Future<void> _handleEditVendor(VendorProvider provider) async {
    final updated = await showDialog<bool>(context: context, builder: (context) => AddEditVendorDialog(vendor: provider.currentVendor));
    if (updated == true && mounted) provider.fetchVendor(widget.vendorId);
  }

  Future<void> _handleDeleteVendor(VendorProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: const Text('Are you sure you want to delete this vendor? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await provider.deleteVendor(widget.vendorId);
      if (success && mounted) Navigator.pop(context);
    }
  }
}
