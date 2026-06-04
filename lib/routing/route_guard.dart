import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/customer_app_profile.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

bool isAuthRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.forgotPassword;

bool isPublicEntryRoute(String location) =>
    location == AppRoutes.welcome ||
    location == AppRoutes.customerLogin ||
    isAuthRoute(location);

bool isCustomerOnboardingRoute(String location) =>
    location == AppRoutes.customerOnboarding;

bool isCustomerShellRoute(String location) =>
    location.startsWith('/customer/home') ||
    location.startsWith('/customer/account') ||
    location.startsWith('/customer/orders') ||
    location.startsWith('/customer/profile');

bool isCustomerRoute(String location) =>
    isCustomerShellRoute(location) ||
    isCustomerOnboardingRoute(location) ||
    location.startsWith('/customer/shop/') ||
    location.startsWith('/customer/month') ||
    location.startsWith('/customer/monthly-bill');

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

bool isAdminCustomerDetailRoute(String location) {
  final match = RegExp(r'^/customers/[^/]+$').hasMatch(location);
  return match;
}

/// Optional: pass profile from redirect caller when repo is not available in redirect.
typedef CustomerProfileLookup = CustomerAppProfile? Function(String userId);

String? redirectForRole({
  required AppUser? user,
  required String location,
  CustomerProfileLookup? customerProfile,
}) {
  final loggedIn = user != null;

  if (!loggedIn) {
    return isPublicEntryRoute(location) ? null : AppRoutes.welcome;
  }

  if (isPublicEntryRoute(location)) {
    return homeRouteForRole(user, customerProfile: customerProfile);
  }

  if (location == AppRoutes.driverToday || location == AppRoutes.driverOrders) {
    return AppRoutes.driverCustomers;
  }

  return switch (user.role) {
    AppRole.admin => _adminRedirect(location),
    AppRole.driver => _driverRedirect(location),
    AppRole.customer => _customerRedirect(
      location,
      user,
      customerProfile: customerProfile,
    ),
  };
}

String homeRouteForRole(
  AppUser user, {
  CustomerProfileLookup? customerProfile,
}) {
  return switch (user.role) {
    AppRole.admin => AppRoutes.dashboard,
    AppRole.driver => AppRoutes.driverCustomers,
    AppRole.customer => _customerHomeRoute(
      user,
      customerProfile: customerProfile,
    ),
  };
}

String _customerHomeRoute(
  AppUser user, {
  CustomerProfileLookup? customerProfile,
}) {
  final profile = customerProfile?.call(user.id);
  final needsOnboarding =
      !user.customerProfileComplete ||
      (profile != null && !profile.onboardingComplete);
  return needsOnboarding
      ? AppRoutes.customerOnboarding
      : AppRoutes.customerHome;
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
  if (isAdminOnlyRoute(location)) return AppRoutes.driverRoute;
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

String? _customerRedirect(
  String location,
  AppUser user, {
  CustomerProfileLookup? customerProfile,
}) {
  final home = _customerHomeRoute(user, customerProfile: customerProfile);

  if (isAdminOnlyRoute(location) ||
      isDriverShellRoute(location) ||
      location == AppRoutes.dashboard ||
      location == AppRoutes.customers) {
    return home;
  }

  if (home == AppRoutes.customerOnboarding && isCustomerShellRoute(location)) {
    return AppRoutes.customerOnboarding;
  }

  if (home == AppRoutes.customerHome && isCustomerOnboardingRoute(location)) {
    return AppRoutes.customerHome;
  }

  return null;
}
