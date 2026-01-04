import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/auth/providers/auth_provider.dart';
import 'package:tailoring_web/features/auth/screens/login_screen.dart';
import 'package:tailoring_web/features/dashboard/screens/dashboard_screen.dart';

/// Splash screen that checks authentication status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit for splash screen to show
    await Future.delayed(Duration(seconds: 1));

    if (!mounted) return;

    // Check if user is logged in
    await context.read<AuthProvider>().checkAuthStatus();

    if (!mounted) return;

    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;

    if (isAuthenticated) {
      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      // Navigate to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom, size: 100, color: Colors.white),
            SizedBox(height: AppTheme.space6),
            Text(
              'Tailoring Web',
              style: AppTheme.heading1.copyWith(color: Colors.white),
            ),
            SizedBox(height: AppTheme.space4),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
