import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

class Sidebar extends StatefulWidget {
  final String currentRoute;

  const Sidebar({super.key, required this.currentRoute});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isSalesExpanded = true;
  bool _isPurchaseExpanded = true; // NEW

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 218,
      color: const Color(0xFF283342),
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.checkroom,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TailoringWeb',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  route: '/dashboard',
                  hasSubmenu: false,
                ),
                const SizedBox(height: 4),
                _buildExpandableSection(
                  context,
                  icon: Icons.shopping_cart_outlined,
                  label: 'Sales',
                  isExpanded: _isSalesExpanded,
                  onTap: () {
                    setState(() {
                      _isSalesExpanded = !_isSalesExpanded;
                    });
                  },
                  children: [
                    _buildSubNavItem(context, 'Customers', '/customers'),
                    _buildSubNavItem(context, 'Items', '/items'),
                    _buildSubNavItem(context, 'Orders', '/orders'),
                    _buildSubNavItem(context, 'Invoices', '/invoices'),
                    _buildSubNavItem(context, 'Payments Received', '/payments'),
                  ],
                ),
                const SizedBox(height: 4),
                // NEW: Purchase Management
                _buildExpandableSection(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Purchase',
                  isExpanded: _isPurchaseExpanded,
                  onTap: () {
                    setState(() {
                      _isPurchaseExpanded = !_isPurchaseExpanded;
                    });
                  },
                  children: [
                    _buildSubNavItem(context, 'Vendors', '/purchase/vendors'),
                    _buildSubNavItem(context, 'Bills', '/purchase/bills'),
                    _buildSubNavItem(context, 'Expenses', '/purchase/expenses'),
                    _buildSubNavItem(context, 'Payments', '/purchase/payments'),
                  ],
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: 'Inventory',
                  route: '/inventory',
                  hasSubmenu: false,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Employees',
                  route: '/employees',
                  hasSubmenu: false,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  route: '/settings',
                  hasSubmenu: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool hasSubmenu,
  }) {
    final isActive = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (route != widget.currentRoute) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4285F4) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildSubNavItem(BuildContext context, String label, String route) {
    final isActive = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (route != widget.currentRoute) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 32,
            padding: const EdgeInsets.only(left: 38, right: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4285F4) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
