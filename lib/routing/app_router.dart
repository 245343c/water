import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/features/admin/drivers_screen.dart';
import 'package:sri_sai_ro_water/features/admin/promotions_admin_screen.dart';
import 'package:sri_sai_ro_water/features/auth/forgot_password_screen.dart';
import 'package:sri_sai_ro_water/features/auth/login_screen.dart';
import 'package:sri_sai_ro_water/features/auth/register_screen.dart';
import 'package:sri_sai_ro_water/features/auth/reset_password_screen.dart';
import 'package:sri_sai_ro_water/features/bills/monthly_bill_screen.dart';
import 'package:sri_sai_ro_water/features/bills/monthly_summary_screen.dart';
import 'package:sri_sai_ro_water/features/bills/bills_screen.dart';
import 'package:sri_sai_ro_water/features/customers/add_edit_customer_screen.dart';
import 'package:sri_sai_ro_water/features/customers/customer_detail_screen.dart';
import 'package:sri_sai_ro_water/features/customers/customers_screen.dart';
import 'package:sri_sai_ro_water/features/dashboard/dashboard_screen.dart';
import 'package:sri_sai_ro_water/features/deliveries/add_delivery_screen.dart';
import 'package:sri_sai_ro_water/features/deliveries/delivery_history_screen.dart';
import 'package:sri_sai_ro_water/features/deliveries/delivery_success_screen.dart';
import 'package:sri_sai_ro_water/features/driver/driver_customer_detail_screen.dart';
import 'package:sri_sai_ro_water/features/driver/driver_customers_screen.dart';
import 'package:sri_sai_ro_water/features/driver/driver_profile_screen.dart';
import 'package:sri_sai_ro_water/features/driver/driver_route_screen.dart';
import 'package:sri_sai_ro_water/features/more/more_screen.dart';
import 'package:sri_sai_ro_water/features/more/settings_screen.dart';
import 'package:sri_sai_ro_water/features/orders/orders_screen.dart';
import 'package:sri_sai_ro_water/features/payments/payment_history_screen.dart';
import 'package:sri_sai_ro_water/features/payments/record_payment_screen.dart';
import 'package:sri_sai_ro_water/features/products/add_product_screen.dart';
import 'package:sri_sai_ro_water/features/products/edit_product_screen.dart';
import 'package:sri_sai_ro_water/features/products/product_detail_screen.dart';
import 'package:sri_sai_ro_water/features/products/products_screen.dart';
import 'package:sri_sai_ro_water/features/reports/reports_screen.dart';
import 'package:sri_sai_ro_water/features/auth/role_picker_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_month_readonly_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_monthly_bill_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_login_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_onboarding_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_shop_screen.dart';
import 'package:sri_sai_ro_water/features/shell/customer_shell.dart';
import 'package:sri_sai_ro_water/features/shell/driver_shell.dart';
import 'package:sri_sai_ro_water/features/shell/main_shell.dart';
import 'package:sri_sai_ro_water/features/subscription/subscription_screen.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/routing/route_guard.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();
final driverShellNavigatorKey = GlobalKey<NavigatorState>();
final customerShellNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const welcome = '/welcome';
  static const customerLogin = '/customer/login';
  static const customerOnboarding = '/customer/onboarding';
  static const customerHome = '/customer/home';
  static const customerAccount = '/customer/account';
  static const customerOrders = '/customer/orders';
  static const customerPromotions = '/customer/promotions';
  static const customerProfile = '/customer/profile';
  static const customerMonthDetail = '/customer/month';
  static const customerMonthlyBill = '/customer/monthly-bill';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const dashboard = '/';
  static const customers = '/customers';
  static const orders = '/orders';
  static const products = '/products';
  static const more = '/more';
  static const reports = '/reports';
  static const bills = '/bills';
  static const promotionsAdmin = '/admin/promotions';
  static const drivers = '/drivers';
  static const subscription = '/subscription';

  static const driverRoute = '/driver/route';

  /// Legacy paths — redirected to [driverRoute].
  static const driverToday = '/driver/today';
  static const driverOrders = '/driver/orders';
  static const driverCustomers = '/driver/customers';
  static const driverProfile = '/driver/profile';
}

GoRouter createAppRouter(AuthRepository auth, WaterPlantRepository plant) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    refreshListenable: auth,
    redirect: (context, state) => redirectForRole(
      user: auth.currentUser,
      location: state.matchedLocation,
      customerProfile: plant.customerProfileByUserId,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const RolePickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerLogin,
        builder: (context, state) => const CustomerLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerOnboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CustomerOnboardingScreen(),
      ),
      GoRoute(
        path: '/customer/shop/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CustomerShopScreen(
          shopId: state.pathParameters['id']!,
          orderId: state.uri.queryParameters['orderId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.customerMonthDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'] ?? '';
          final shopId = state.uri.queryParameters['shopId'];
          final year = int.tryParse(state.uri.queryParameters['year'] ?? '');
          final month = int.tryParse(state.uri.queryParameters['month'] ?? '');
          DateTime? initial;
          if (year != null && month != null && month >= 1 && month <= 12) {
            initial = DateTime(year, month);
          }
          return CustomerMonthReadonlyScreen(
            customerId: customerId,
            shopId: shopId,
            initialMonth: initial,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerMonthlyBill,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'] ?? '';
          final shopId =
              state.uri.queryParameters['shopId'] ??
              WaterPlantRepository.defaultShopId;
          final year = int.tryParse(state.uri.queryParameters['year'] ?? '');
          final month = int.tryParse(state.uri.queryParameters['month'] ?? '');
          DateTime? initial;
          if (year != null && month != null && month >= 1 && month <= 12) {
            initial = DateTime(year, month);
          }
          return CustomerMonthlyBillScreen(
            customerId: customerId,
            shopId: shopId,
            initialMonth: initial,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (context, state) => CustomerShell(location: state.uri),
      ),
      GoRoute(
        path: AppRoutes.customerAccount,
        builder: (context, state) => CustomerShell(location: state.uri),
      ),
      GoRoute(
        path: AppRoutes.customerOrders,
        builder: (context, state) => CustomerShell(location: state.uri),
      ),
      GoRoute(
        path: AppRoutes.customerPromotions,
        builder: (context, state) => CustomerShell(location: state.uri),
      ),
      GoRoute(
        path: AppRoutes.customerProfile,
        builder: (context, state) => CustomerShell(location: state.uri),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: Uri.decodeComponent(email));
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customers,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CustomersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: OrdersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProductsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MoreScreen()),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DriverShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverRoute,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverRouteScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverCustomers,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverCustomersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverProfile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/driver/customers/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            DriverCustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddEditCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            AddEditCustomerScreen(customerId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/customers/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            CustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/delivery',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            AddDeliveryScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/delivery/success',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final delivery = state.extra as Delivery;
          return DeliverySuccessScreen(
            customerId: state.pathParameters['id']!,
            delivery: delivery,
          );
        },
      ),
      GoRoute(
        path: '/customers/:id/history',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            DeliveryHistoryScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/summary',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final year = int.tryParse(state.uri.queryParameters['year'] ?? '');
          final month = int.tryParse(state.uri.queryParameters['month'] ?? '');
          DateTime? initialMonth;
          if (year != null && month != null && month >= 1 && month <= 12) {
            initialMonth = DateTime(year, month);
          }
          return MonthlySummaryScreen(
            customerId: state.pathParameters['id']!,
            initialMonth: initialMonth,
          );
        },
      ),
      GoRoute(
        path: '/customers/:id/bill',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            MonthlyBillScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/payment',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            RecordPaymentScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/payments',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            PaymentHistoryScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/products/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            EditProductScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/products/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.reports,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.bills,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BillsScreen(),
      ),
      GoRoute(
        path: AppRoutes.promotionsAdmin,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PromotionsAdminScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.drivers,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DriversScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
}
