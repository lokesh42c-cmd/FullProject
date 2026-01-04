import 'package:flutter/material.dart';
import 'package:tailoring_web/core/layouts/sidebar.dart';
import 'package:tailoring_web/core/layouts/top_bar.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';

/// Main Layout
/// Fixed sidebar on left, topbar on top, content area on right
class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String? pageTitle;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Fixed Sidebar (always visible)TopBar
          Sidebar(currentRoute: currentRoute),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // TopBar
                TopBar(),

                // Content
                Expanded(
                  child: Container(
                    color: AppTheme.backgroundWhite, // Pure white!
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
