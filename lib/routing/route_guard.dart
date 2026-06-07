import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

bool isAuthRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.forgotPassword;

bool isPublicEntryRoute(String location) => isAuthRoute(location);

bool isCustomerRoute(String location) => location.startsWith('/customer/');

/// Driver shell lives under `/driver/...` (note trailing slash — not `/drivers`).
bool isDriverShellRoute(String location) => location.startsWith('/driver/');

bool isDriverCustomerRoute(String location) =>
    location.startsWith('/driver/customers/');

/// Routes only admins may open.
bool isAdminOnlyRoute(String location) {
  if (location == AppRoutes.dashboard ||
      location == AppRoutes.products ||
      location == AppRoutes.more ||
      location == AppRoutes.reports ||
      location.startsWith('/notifications') ||
      location.startsWith('/settings') ||
      location.startsWith('/drivers') ||
      location.startsWith('/routes') ||
      location.startsWith('/products')) {
    return true;
  }
  if (location == '/customers/add' || location.contains('/edit')) return true;
  if (location.contains('/payment') ||
      location.contains('/payments') ||
      location.contains('/summary') ||
      location.contains('/bill')) {
    return true;
  }
  if (location == AppRoutes.register) return true;
  return false;
}

bool isAdminCustomerDetailRoute(String location) =>
    RegExp(r'^/customers/[^/]+$').hasMatch(location);

String? redirectForRole({required AppUser? user, required String location}) {
  final loggedIn = user != null;

  if (!loggedIn) {
    return isPublicEntryRoute(location) ? null : AppRoutes.login;
  }

  if (isPublicEntryRoute(location)) {
    final home = homeRouteForRole(user);
    return home == location ? null : home;
  }

  if (location == AppRoutes.driverToday || location == AppRoutes.driverOrders) {
    return AppRoutes.driverRoute;
  }

  return switch (user.role) {
    AppRole.admin => _adminRedirect(location),
    AppRole.driver => _driverRedirect(location),
    AppRole.customer => _customerRedirect(location),
  };
}

String homeRouteForRole(AppUser user) {
  return switch (user.role) {
    AppRole.admin => AppRoutes.dashboard,
    AppRole.driver => AppRoutes.driverCustomers,
    AppRole.customer => AppRoutes.login,
  };
}

String? _adminRedirect(String location) {
  if (isDriverShellRoute(location) || isDriverCustomerRoute(location)) {
    return AppRoutes.dashboard;
  }
  if (isCustomerRoute(location) || location == AppRoutes.welcome) {
    return AppRoutes.dashboard;
  }
  return null;
}

String? _driverRedirect(String location) {
  if (isAdminOnlyRoute(location)) return AppRoutes.driverCustomers;
  if (isAdminCustomerDetailRoute(location)) {
    final id = RegExp(r'^/customers/([^/]+)$').firstMatch(location)?.group(1);
    if (id != null) return '/driver/customers/$id';
  }
  if (location == AppRoutes.customers || location == AppRoutes.orders) {
    return AppRoutes.driverCustomers;
  }
  if (location == AppRoutes.dashboard) return AppRoutes.driverCustomers;
  if (isCustomerRoute(location) || location == AppRoutes.welcome) {
    return AppRoutes.driverCustomers;
  }
  return null;
}

String? _customerRedirect(String location) {
  return location == AppRoutes.login ? null : AppRoutes.login;
}
