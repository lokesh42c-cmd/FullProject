import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/auth/providers/auth_provider.dart';
import 'package:tailoring_web/features/auth/screens/splash_screen.dart';
import 'package:tailoring_web/features/auth/screens/login_screen.dart';
import 'package:tailoring_web/features/auth/screens/register_screen.dart';
import 'package:tailoring_web/features/auth/services/auth_service.dart';
import 'package:tailoring_web/features/dashboard/screens/dashboard_screen.dart';
import 'package:tailoring_web/features/customers/providers/customer_provider.dart';
import 'package:tailoring_web/features/customers/screens/customer_list_screen.dart';
import 'package:tailoring_web/features/customers/screens/customer_detail_screen.dart';
import 'package:tailoring_web/features/items/providers/item_provider.dart';
import 'package:tailoring_web/features/items/screens/item_list_screen.dart';
import 'package:tailoring_web/features/masters/screens/settings_screen.dart';
import 'package:tailoring_web/features/masters/providers/masters_provider.dart';
import 'package:tailoring_web/features/orders/providers/order_provider.dart';
import 'package:tailoring_web/features/orders/screens/order_list_screen.dart';
import 'package:tailoring_web/features/orders/screens/order_detail_screen.dart';
// import 'package:tailoring_web/features/customer_payments/providers/payment_provider.dart';
// import 'package:tailoring_web/features/customer_payments/services/payment_service.dart';
// import 'package:tailoring_web/features/customer_payments/screens/payments_list_screen.dart';
import 'package:tailoring_web/features/financials/screens/all_payments_screen.dart';
import 'package:tailoring_web/features/financials/providers/payment_transaction_provider.dart';
import 'package:tailoring_web/features/financials/services/payment_transaction_service.dart';

// ✅ Invoice Imports
import 'package:tailoring_web/features/invoices/providers/invoice_provider.dart';
import 'package:tailoring_web/features/invoices/screens/invoice_list_screen.dart';
import 'package:tailoring_web/features/invoices/screens/invoice_detail_screen.dart';
import 'package:tailoring_web/features/invoices/screens/create_invoice_screen.dart';

void main() {
  runApp(const TailoringWebApp());
}

class TailoringWebApp extends StatelessWidget {
  const TailoringWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => CustomerProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => MastersProvider()),
        // ChangeNotifierProvider(
        //   create: (_) => PaymentProvider(PaymentService(apiClient)),
        // ),
        ChangeNotifierProvider(
          create: (context) => PaymentTransactionProvider(
            // Ensure you pass the existing apiClient instance here
            PaymentTransactionService(apiClient),
          ),
        ),

        // ✅ Added InvoiceProvider to match the others
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: MaterialApp(
        title: 'Tailoring Web',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          print('🔍 Route requested: ${settings.name}');

          // Customer detail route logic
          if (settings.name == '/customers/detail') {
            final customerId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) =>
                  CustomerDetailScreen(customerId: customerId),
            );
          }

          // ✅ Updated Invoice detail route logic (Matches Customer/Order style)
          if (settings.name == '/invoices/detail') {
            final invoiceId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoiceId: invoiceId),
              settings: settings,
            );
          }

          return null;
        },
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/items': (context) => const ItemListScreen(),
          '/customers': (context) => const CustomerListScreen(),
          '/orders': (context) => const OrderListScreen(),

          // Order Detail logic (Using arguments pattern)
          '/orders/detail': (context) {
            final orderId = ModalRoute.of(context)!.settings.arguments as int;
            return OrderDetailScreen(orderId: orderId);
          },

          '/payments-received': (context) => const AllPaymentsScreen(),

          // ✅ Simplified Invoice Routes
          '/invoices': (context) => const InvoiceListScreen(),
          '/invoices/create': (context) => const CreateInvoiceScreen(),
        },
      ),
    );
  }
}
