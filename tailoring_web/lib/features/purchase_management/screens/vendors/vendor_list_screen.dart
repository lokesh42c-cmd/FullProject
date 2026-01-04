import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/providers/vendor_provider.dart';
import 'package:tailoring_web/features/purchase_management/widgets/vendor_card.dart';
import 'package:tailoring_web/features/purchase_management/screens/vendors/add_edit_vendor_dialog.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().fetchVendors(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProvider>();

    return MainLayout(
      currentRoute: '/purchase/vendors',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Text('Vendors', style: AppTheme.heading2),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const AddEditVendorDialog(),
                    );
                    provider.refresh();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Vendor'),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.vendors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.vendors.isEmpty
                ? const Center(child: Text('No vendors found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.space5),
                    itemCount: provider.vendors.length,
                    itemBuilder: (context, index) {
                      final vendor = provider.vendors[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space3),
                        child: VendorCard(vendor: vendor),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
