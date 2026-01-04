import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/models/vendor.dart';
import 'package:tailoring_web/features/purchase_management/screens/vendors/vendor_detail_screen.dart';

class VendorCard extends StatelessWidget {
  final Vendor vendor;

  const VendorCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (vendor.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorDetailScreen(vendorId: vendor.id!),
            ),
          );
        }
      },
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (vendor.businessName != null) ...[
                        const SizedBox(height: AppTheme.space1),
                        Text(
                          vendor.businessName!,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Outstanding',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      '₹${vendor.outstandingBalance}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: vendor.hasBalance
                            ? AppTheme.danger
                            : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.space1),
                Text(vendor.phone, style: AppTheme.bodySmall),
                if (vendor.email != null && vendor.email!.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.space3),
                  Icon(Icons.email, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: AppTheme.space1),
                  Expanded(
                    child: Text(
                      vendor.email!,
                      style: AppTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (_buildLocationText().isNotEmpty) ...[
              const SizedBox(height: AppTheme.space2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space1),
                  Expanded(
                    child: Text(
                      _buildLocationText(),
                      style: AppTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.space3),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: vendor.isActive
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    vendor.isActive ? 'Active' : 'Inactive',
                    style: AppTheme.bodySmall.copyWith(
                      color: vendor.isActive
                          ? AppTheme.success
                          : AppTheme.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (vendor.totalBills != null && vendor.totalBills! > 0) ...[
                  Text(
                    '${vendor.totalBills} bills',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Text(
                    '₹${vendor.totalPurchases}',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildLocationText() {
    final parts = <String>[];
    if (vendor.city != null && vendor.city!.isNotEmpty) parts.add(vendor.city!);
    if (vendor.state != null && vendor.state!.isNotEmpty)
      parts.add(vendor.state!);
    if (vendor.pincode != null && vendor.pincode!.isNotEmpty)
      parts.add(vendor.pincode!);
    return parts.join(', ');
  }
}
