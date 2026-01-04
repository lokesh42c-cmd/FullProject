import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/auth/providers/auth_provider.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Container(
      height: AppTheme.topbarHeight,
      decoration: BoxDecoration(
        color: AppTheme.topbarWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 8),

          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
            onPressed: () {
              // Refresh action
            },
            tooltip: 'Refresh',
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          SizedBox(width: 8),

          // Search bar (Zoho style)
          Container(
            width: 300,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: Row(
              children: [
                SizedBox(width: 10),
                Icon(Icons.search, color: AppTheme.textMuted, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: AppTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
          ),

          Spacer(),

          // Organization/Tenant dropdown
          Container(
            height: 32,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight, width: 1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authProvider.tenantName ?? 'Organization',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),

          SizedBox(width: 12),

          // Add button (blue circle with +)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white, size: 18),
              onPressed: () {
                // Quick add
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),

          SizedBox(width: 12),

          // People icon
          IconButton(
            icon: Icon(
              Icons.people_outline,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            onPressed: () {},
            tooltip: 'People',
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          // Notifications with red dot
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () {},
                tooltip: 'Notifications',
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          // Settings
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          SizedBox(width: 4),

          // User profile menu
          PopupMenuButton<String>(
            offset: Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    radius: 14,
                    child: Text(
                      authProvider.userName?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              // User info
              PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.userName ?? 'User',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: AppTheme.fontSemibold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      authProvider.userEmail ?? '',
                      style: AppTheme.bodySmall,
                    ),
                    SizedBox(height: 8),
                    Divider(height: 1),
                  ],
                ),
              ),

              // Profile
              PopupMenuItem<String>(
                value: 'profile',
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 12),
                    Text('My Profile', style: AppTheme.bodySmall),
                  ],
                ),
              ),

              // Settings
              PopupMenuItem<String>(
                value: 'settings',
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 12),
                    Text('Settings', style: AppTheme.bodySmall),
                  ],
                ),
              ),

              PopupMenuItem<String>(
                enabled: false,
                height: 1,
                padding: EdgeInsets.zero,
                child: Divider(height: 1),
              ),

              // Logout
              PopupMenuItem<String>(
                value: 'logout',
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: AppTheme.danger),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile page coming soon')),
                  );
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'logout':
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                  break;
              }
            },
          ),

          SizedBox(width: 8),

          // Apps menu (grid icon)
          IconButton(
            icon: Icon(Icons.apps, color: AppTheme.textSecondary, size: 20),
            onPressed: () {},
            tooltip: 'Apps',
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          SizedBox(width: 12),
        ],
      ),
    );
  }
}
