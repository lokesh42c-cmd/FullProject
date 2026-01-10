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
import 'features/items/providers/item_unit_provider.dart';
import 'features/items/services/item_unit_service.dart';
import 'package:tailoring_web/features/items/services/item_service.dart';
import 'package:tailoring_web/features/masters/screens/settings_screen.dart';
import 'package:tailoring_web/features/masters/providers/masters_provider.dart';

import 'package:tailoring_web/features/orders/providers/order_provider.dart';
import 'package:tailoring_web/features/orders/services/order_service.dart';
import 'package:tailoring_web/features/orders/screens/order_list_screen.dart';
import 'package:tailoring_web/features/orders/screens/order_detail_screen.dart';
import 'package:tailoring_web/features/orders/screens/create_order_screen.dart';
import 'package:tailoring_web/features/customer_payments/providers/payment_provider.dart';
import 'package:tailoring_web/features/customer_payments/services/payment_service.dart';
import 'package:tailoring_web/features/customer_payments/screens/payments_list_screen.dart';

// NEW: Purchase Management Imports
// import 'package:tailoring_web/features/purchase_management/providers/vendor_provider.dart';
// import 'package:tailoring_web/features/purchase_management/providers/bill_provider.dart';
// import 'package:tailoring_web/features/purchase_management/providers/expense_provider.dart';
// import 'package:tailoring_web/features/purchase_management/providers/payment_provider.dart'
//     as purchase;
// import 'package:tailoring_web/features/purchase_management/services/purchase_api_service.dart';
// import 'package:tailoring_web/features/purchase_management/screens/vendors/vendor_list_screen.dart';
// import 'package:tailoring_web/features/purchase_management/screens/bills/bill_list_screen.dart';
// import 'package:tailoring_web/features/purchase_management/screens/expenses/expense_list_screen.dart';
// import 'package:tailoring_web/features/purchase_management/screens/payments/payment_list_screen.dart';

void main() {
  runApp(const TailoringWebApp());
}

class TailoringWebApp extends StatelessWidget {
  const TailoringWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);
    // final purchaseApiService = PurchaseApiService(apiClient); // NEW

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => CustomerProvider(apiClient)),
        // ChangeNotifierProvider(
        //   create: (_) => CustomerDetailProvider(apiClient),
        // ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => MastersProvider()),
        // ChangeNotifierProvider(//   create: (_) => OrderProvider(OrderService(apiClient)),
        // ),
        // ChangeNotifierProvider(
        //   create: (_) => ItemProvider(ItemService(apiClient)),
        // ),
        // ChangeNotifierProvider(
        //   create: (_) => ItemUnitProvider(ItemUnitService(apiClient)),
        // ),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(PaymentService(apiClient)),
        ),

        // // NEW: Purchase Management Providers
        // ChangeNotifierProvider(
        //   create: (_) => VendorProvider(purchaseApiService),
        // ),
        // ChangeNotifierProvider(create: (_) => BillProvider(purchaseApiService)),
        // ChangeNotifierProvider(
        //   create: (_) => ExpenseProvider(purchaseApiService),
        // ),
        // ChangeNotifierProvider(
        //   create: (_) => purchase.PaymentProvider(purchaseApiService),
        // ),
      ],
      child: MaterialApp(
        title: 'Tailoring Web',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/customers/detail') {
            final customerId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) =>
                  CustomerDetailScreen(customerId: customerId),
            );
          }
          return null;
        },
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/items': (context) => const ItemListScreen(),
          '/customers': (context) => const CustomerListScreen(),
          '/customers/:id': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return CustomerDetailScreen(customerId: args?['customerId'] as int);
          },
          '/orders': (context) => const OrderListScreen(),
          '/orders/detail': (context) {
            final orderId = ModalRoute.of(context)!.settings.arguments as int;
            return OrderDetailScreen(orderId: orderId);
          },
          '/payments': (context) => const PaymentsListScreen(),

          // NEW: Purchase Management Routes
          // '/purchase/vendors': (context) => const VendorListScreen(),
          // '/purchase/bills': (context) => const BillListScreen(),
          // '/purchase/expenses': (context) => const ExpenseListScreen(),
          // '/purchase/payments': (context) => const PaymentListScreen(),
        },
      ),
    );
  }
}
