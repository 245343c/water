import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';

class MockAuthAccount {
  const MockAuthAccount({required this.user, required this.password});
  final AppUser user;
  final String password;
}

List<MockAuthAccount> seedAuthAccounts() => [
  MockAuthAccount(
    user: const AppUser(
      id: 'admin-1',
      ownerName: 'Shop Owner',
      email: 'admin@srisai.com',
      phone: '+91 98765 43210',
      businessName: 'Sri Sai RO Water Plant',
      role: AppRole.admin,
    ),
    password: 'admin123',
  ),
  MockAuthAccount(
    user: const AppUser(
      id: 'user-driver-1',
      ownerName: 'Rajesh Kumar',
      email: 'driver@srisai.com',
      phone: '+91 91234 56780',
      businessName: 'Sri Sai RO Water Plant',
      role: AppRole.driver,
      driverId: 'driver-1',
    ),
    password: 'driver123',
  ),
];
