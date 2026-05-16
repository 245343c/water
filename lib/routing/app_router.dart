import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/features/bills/monthly_bill_screen.dart';
import 'package:sri_sai_ro_water/features/bills/monthly_summary_screen.dart';
import 'package:sri_sai_ro_water/features/customers/add_edit_customer_screen.dart';
import 'package:sri_sai_ro_water/features/customers/customer_detail_screen.dart';
import 'package:sri_sai_ro_water/features/customers/customers_screen.dart';
import 'package:sri_sai_ro_water/features/dashboard/dashboard_screen.dart';
import 'package:sri_sai_ro_water/features/deliveries/add_delivery_screen.dart';
import 'package:sri_sai_ro_water/features/deliveries/deliveries_screen.dart';
import 'package:sri_sai_ro_water/features/deliveries/delivery_history_screen.dart';
import 'package:sri_sai_ro_water/features/deliveries/delivery_success_screen.dart';
import 'package:sri_sai_ro_water/features/more/more_screen.dart';
import 'package:sri_sai_ro_water/features/more/settings_screen.dart';
import 'package:sri_sai_ro_water/features/payments/record_payment_screen.dart';
import 'package:sri_sai_ro_water/features/reports/reports_screen.dart';
import 'package:sri_sai_ro_water/features/shell/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const dashboard = '/';
  static const customers = '/customers';
  static const deliveries = '/deliveries';
  static const more = '/more';
  static const reports = '/reports';
}

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customers,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CustomersScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.deliveries,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DeliveriesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MoreScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/customers/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddEditCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AddEditCustomerScreen(
          customerId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/customers/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CustomerDetailScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customers/:id/delivery',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AddDeliveryScreen(
          customerId: state.pathParameters['id']!,
        ),
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
        builder: (context, state) => DeliveryHistoryScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customers/:id/summary',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => MonthlySummaryScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customers/:id/bill',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => MonthlyBillScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customers/:id/payment',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => RecordPaymentScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.reports,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
