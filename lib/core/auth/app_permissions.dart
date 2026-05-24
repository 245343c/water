import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';

/// Central permission checks — keep in sync with [docs/PRODUCT_ARCHITECTURE.md].
abstract final class AppPermissions {
  static bool can(AppUser? user, String permission) {
    if (user == null) return false;
    return _rolePermissions(user.role).contains(permission);
  }

  static Set<String> _rolePermissions(AppRole role) => switch (role) {
        AppRole.admin => {
            'dashboard',
            'reports',
            'settings',
            'products',
            'promotions.manage',
            'drivers.manage',
            'customers.read',
            'customers.write',
            'orders.read',
            'orders.respond',
            'delivery.create',
            'payments',
            'bills',
          },
        AppRole.driver => {
            'customers.read',
            'orders.read',
            'delivery.create',
          },
        AppRole.customer => {
            'orders.read.own',
          },
      };

  static bool isAdmin(AppUser? user) => user?.role.isAdmin ?? false;
  static bool isDriver(AppUser? user) => user?.role.isDriver ?? false;
}
