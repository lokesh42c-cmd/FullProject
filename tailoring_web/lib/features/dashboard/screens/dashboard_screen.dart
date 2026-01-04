import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/auth/providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return MainLayout(
      currentRoute: '/dashboard',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: AppTheme.heading1),
                    SizedBox(height: AppTheme.space1),
                    Text(
                      'Welcome back, ${authProvider.userName}!',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/orders');
                  },
                  icon: Icon(Icons.add, size: 16),
                  label: Text('New Order'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.space4,
                      vertical: AppTheme.space2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space6),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Total Customers',
                    value: '0',
                    change: '+0%',
                    isPositive: true,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(width: AppTheme.space4),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.shopping_bag,
                    title: 'Active Orders',
                    value: '0',
                    change: '+0%',
                    isPositive: true,
                    color: AppTheme.accentOrange,
                  ),
                ),
                SizedBox(width: AppTheme.space4),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.currency_rupee,
                    title: 'Revenue (Month)',
                    value: '₹0',
                    change: '+0%',
                    isPositive: true,
                    color: AppTheme.success,
                  ),
                ),
                SizedBox(width: AppTheme.space4),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_actions,
                    title: 'Pending Tasks',
                    value: '0',
                    change: '-0%',
                    isPositive: false,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space6),

            // Quick Actions & Recent Activity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Actions', style: AppTheme.heading3),
                          SizedBox(height: AppTheme.space4),
                          _buildQuickActionButton(
                            context,
                            icon: Icons.person_add,
                            label: 'New Customer',
                            onTap: () =>
                                Navigator.pushNamed(context, '/customers'),
                          ),
                          SizedBox(height: AppTheme.space2),
                          _buildQuickActionButton(
                            context,
                            icon: Icons.add_shopping_cart,
                            label: 'New Order',
                            onTap: () =>
                                Navigator.pushNamed(context, '/orders'),
                          ),
                          SizedBox(height: AppTheme.space2),
                          _buildQuickActionButton(
                            context,
                            icon: Icons.receipt,
                            label: 'New Invoice',
                            onTap: () =>
                                Navigator.pushNamed(context, '/invoices'),
                          ),
                          SizedBox(height: AppTheme.space2),
                          _buildQuickActionButton(
                            context,
                            icon: Icons.inventory,
                            label: 'Add Item',
                            onTap: () =>
                                Navigator.pushNamed(context, '/inventory'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.space4),

                // Recent Activity
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent Activity', style: AppTheme.heading3),
                          SizedBox(height: AppTheme.space4),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.space8),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 48,
                                    color: AppTheme.textMuted,
                                  ),
                                  SizedBox(height: AppTheme.space3),
                                  Text(
                                    'No recent activity',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive ? AppTheme.success : AppTheme.danger,
                      ),
                      SizedBox(width: 2),
                      Text(
                        change,
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 10,
                          color: isPositive
                              ? AppTheme.success
                              : AppTheme.danger,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space3),
            Text(
              value,
              style: AppTheme.heading1.copyWith(fontSize: 24, color: color),
            ),
            SizedBox(height: AppTheme.space1),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: EdgeInsets.all(AppTheme.space3),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryBlue),
            SizedBox(width: AppTheme.space3),
            Text(label, style: AppTheme.bodyMedium),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
