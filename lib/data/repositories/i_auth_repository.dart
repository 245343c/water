import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';

/// Abstract contract for authentication.
/// Concrete implementations: [AuthRepository] (mock), ApiAuthRepository (backend).
abstract class IAuthRepository extends ChangeNotifier {
  AppUser? get currentUser;
  bool get isAuthenticated;
  List<AppUser> get driverAccounts;

  String? login({required String email, required String password});

  String? register({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
  });

  String? createDriverAccount({
    required String driverId,
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  void updateDriverAccountEmail(String driverId, String newEmail);
  void resetDriverPassword(String driverId, String newPassword);
  bool hasAccountForDriver(String driverId);
  AppUser? accountForDriver(String driverId);

  void logout();

  String? requestCustomerOtp(String phone);
  String? verifyCustomerOtp({required String phone, required String otp});
  void deleteCustomerAccount(String userId);
  void markCustomerOnboardingComplete(String userId, {required String name});

  String? requestPasswordReset(String email);
  String? resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  });
  void cancelPasswordReset();
}
