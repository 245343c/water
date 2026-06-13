import 'package:sri_sai_ro_water/core/auth/app_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.role,
    this.driverId,
    this.customerProfileComplete = true,
    this.pricingSetupComplete = true,
  });

  final String id;
  final String ownerName;
  final String email;
  final String phone;
  final String businessName;
  final AppRole role;

  /// Links to [Driver.id] when [role] is [AppRole.driver].
  final String? driverId;

  /// False until customer finishes address + map onboarding.
  final bool customerProfileComplete;

  /// False until new admin saves default product rates after signup.
  final bool pricingSetupComplete;

  bool get isAdmin => role == AppRole.admin;
  bool get isDriver => role == AppRole.driver;
  bool get isCustomer => role == AppRole.customer;
}
