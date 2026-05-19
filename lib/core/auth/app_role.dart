/// User roles for the single-app multi-persona model.
enum AppRole {
  admin,
  driver,

  /// Reserved for customer portal (phase 3).
  customer,
}

extension AppRoleX on AppRole {
  String get label => switch (this) {
        AppRole.admin => 'Admin',
        AppRole.driver => 'Driver',
        AppRole.customer => 'Customer',
      };

  bool get isAdmin => this == AppRole.admin;
  bool get isDriver => this == AppRole.driver;
}
