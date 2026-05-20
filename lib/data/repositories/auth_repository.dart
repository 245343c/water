import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:uuid/uuid.dart';

class _StoredAccount {
  _StoredAccount({
    required this.user,
    required this.password,
  });

  final AppUser user;
  String password;
}

class _PendingPasswordReset {
  _PendingPasswordReset({
    required this.email,
    required this.otp,
    required this.expiresAt,
    required this.attemptsLeft,
  });

  final String email;
  final String otp;
  final DateTime expiresAt;
  int attemptsLeft;
}

/// Mock authentication until backend is connected.
class AuthRepository extends ChangeNotifier {
  AuthRepository() {
    _accounts.add(
      _StoredAccount(
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
    );
    _accounts.add(
      _StoredAccount(
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
    );
  }

  static const _uuid = Uuid();
  final List<_StoredAccount> _accounts = [];

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  List<AppUser> get driverAccounts => _accounts
      .where((a) => a.user.role == AppRole.driver)
      .map((a) => a.user)
      .toList();

  String? login({required String email, required String password}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 'Email is required';
    if (password.isEmpty) return 'Password is required';

    for (final account in _accounts) {
      if (account.user.email.toLowerCase() == normalized &&
          account.password == password) {
        if (account.user.role == AppRole.driver) {
          // Driver profile active check happens in UI via WaterPlantRepository.
        }
        _currentUser = account.user;
        notifyListeners();
        return null;
      }
    }
    return 'Invalid email or password';
  }

  String? register({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
  }) {
    final normalized = email.trim().toLowerCase();
    if (ownerName.trim().isEmpty) return 'Owner name is required';
    if (businessName.trim().isEmpty) return 'Business name is required';
    if (phone.trim().length < 10) return 'Valid phone number is required';
    if (normalized.isEmpty || !normalized.contains('@')) {
      return 'Valid email is required';
    }
    if (password.length < 6) return 'Password must be at least 6 characters';

    if (_accounts.any((a) => a.user.email.toLowerCase() == normalized)) {
      return 'An account with this email already exists';
    }

    final user = AppUser(
      id: _uuid.v4(),
      ownerName: ownerName.trim(),
      email: normalized,
      phone: phone.trim(),
      businessName: businessName.trim(),
      role: AppRole.admin,
    );
    _accounts.add(_StoredAccount(user: user, password: password));
    _currentUser = user;
    notifyListeners();
    return null;
  }

  /// Admin creates driver login linked to [driverId] from [WaterPlantRepository].
  String? createDriverAccount({
    required String driverId,
    required String name,
    required String phone,
    required String email,
    required String password,
  }) {
    final normalized = email.trim().toLowerCase();
    if (name.trim().isEmpty) return 'Name is required';
    if (phone.trim().length < 10) return 'Valid phone is required';
    if (normalized.isEmpty || !normalized.contains('@')) {
      return 'Valid email is required';
    }
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (_accounts.any((a) => a.user.email.toLowerCase() == normalized)) {
      return 'Email already used for another account';
    }
    if (_accounts.any((a) => a.user.driverId == driverId)) {
      return 'This driver already has login credentials';
    }

    final user = AppUser(
      id: _uuid.v4(),
      ownerName: name.trim(),
      email: normalized,
      phone: phone.trim(),
      businessName: 'Sri Sai RO Water Plant',
      role: AppRole.driver,
      driverId: driverId,
    );
    _accounts.add(_StoredAccount(user: user, password: password));
    notifyListeners();
    return null;
  }

  void updateDriverAccountEmail(String driverId, String newEmail) {
    final normalized = newEmail.trim().toLowerCase();
    final index = _accounts.indexWhere((a) => a.user.driverId == driverId);
    if (index < 0) return;
    final user = _accounts[index].user;
    _accounts[index] = _StoredAccount(
      user: AppUser(
        id: user.id,
        ownerName: user.ownerName,
        email: normalized,
        phone: user.phone,
        businessName: user.businessName,
        role: user.role,
        driverId: user.driverId,
      ),
      password: _accounts[index].password,
    );
    if (_currentUser?.driverId == driverId) {
      _currentUser = _accounts[index].user;
    }
    notifyListeners();
  }

  void resetDriverPassword(String driverId, String newPassword) {
    final index = _accounts.indexWhere((a) => a.user.driverId == driverId);
    if (index < 0) return;
    _accounts[index].password = newPassword;
    notifyListeners();
  }

  bool hasAccountForDriver(String driverId) =>
      _accounts.any((a) => a.user.driverId == driverId);

  AppUser? accountForDriver(String driverId) {
    try {
      return _accounts.firstWhere((a) => a.user.driverId == driverId).user;
    } catch (_) {
      return null;
    }
  }

  void logout() {
    _currentUser = null;
    _pendingCustomerOtp = null;
    notifyListeners();
  }

  _PendingCustomerOtp? _pendingCustomerOtp;

  /// Mock OTP — returns code for demo UI (Firebase phone auth later).
  String? requestCustomerOtp(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return null;
    const demoOtp = '123456';
    _pendingCustomerOtp = _PendingCustomerOtp(
      phone: digits,
      otp: demoOtp,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
    return demoOtp;
  }

  /// Returns error message or null on success.
  String? verifyCustomerOtp({
    required String phone,
    required String otp,
  }) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final pending = _pendingCustomerOtp;
    if (pending == null || pending.phone != digits) {
      return 'Send OTP to your phone first';
    }
    if (DateTime.now().isAfter(pending.expiresAt)) {
      _pendingCustomerOtp = null;
      return 'OTP expired. Request again';
    }
    if (otp.trim() != pending.otp) {
      return 'Invalid OTP';
    }
    _pendingCustomerOtp = null;

    final existing = _accounts.indexWhere(
      (a) =>
          a.user.role == AppRole.customer &&
          a.user.phone.replaceAll(RegExp(r'\D'), '') == digits,
    );

    if (existing >= 0) {
      _currentUser = _accounts[existing].user;
      notifyListeners();
      return null;
    }

    final user = AppUser(
      id: _uuid.v4(),
      ownerName: 'Customer',
      email: '',
      phone: digits,
      businessName: '',
      role: AppRole.customer,
      customerProfileComplete: false,
    );
    _accounts.add(_StoredAccount(user: user, password: ''));
    _currentUser = user;
    notifyListeners();
    return null;
  }

  /// Permanently removes the customer account (app store requirement).
  void deleteCustomerAccount(String userId) {
    _accounts.removeWhere((a) => a.user.id == userId);
    if (_currentUser?.id == userId) {
      _currentUser = null;
    }
    notifyListeners();
  }

  void markCustomerOnboardingComplete(String userId, {required String name}) {
    final index = _accounts.indexWhere((a) => a.user.id == userId);
    if (index < 0) return;
    final u = _accounts[index].user;
    _accounts[index] = _StoredAccount(
      user: AppUser(
        id: u.id,
        ownerName: name,
        email: u.email,
        phone: u.phone,
        businessName: u.businessName,
        role: u.role,
        customerProfileComplete: true,
      ),
      password: _accounts[index].password,
    );
    if (_currentUser?.id == userId) {
      _currentUser = _accounts[index].user;
    }
    notifyListeners();
  }

  _PendingPasswordReset? _pendingReset;
  static const _otpLifetime = Duration(minutes: 10);
  static const _maxOtpAttempts = 5;

  String? requestPasswordReset(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return 'Enter a valid email address';
    }

    final exists = _accounts.any((a) => a.user.email.toLowerCase() == normalized);
    if (exists) {
      final otp = _generateOtp();
      _pendingReset = _PendingPasswordReset(
        email: normalized,
        otp: otp,
        expiresAt: DateTime.now().add(_otpLifetime),
        attemptsLeft: _maxOtpAttempts,
      );
      return otp;
    }
    return null;
  }

  String? resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    final normalized = email.trim().toLowerCase();
    final pending = _pendingReset;

    if (pending == null || pending.email != normalized) {
      return 'Request a new reset code first';
    }
    if (DateTime.now().isAfter(pending.expiresAt)) {
      _pendingReset = null;
      return 'Code expired. Request a new one';
    }
    if (pending.attemptsLeft <= 0) {
      _pendingReset = null;
      return 'Too many attempts. Request a new code';
    }

    if (otp.trim() != pending.otp) {
      pending.attemptsLeft--;
      return 'Invalid code. ${pending.attemptsLeft} attempts left';
    }

    if (newPassword.length < 6) {
      return 'Password must be at least 6 characters';
    }

    final index = _accounts.indexWhere((a) => a.user.email.toLowerCase() == normalized);
    if (index < 0) {
      _pendingReset = null;
      return 'Account not found';
    }

    _accounts[index].password = newPassword;
    _pendingReset = null;
    notifyListeners();
    return null;
  }

  void cancelPasswordReset() => _pendingReset = null;

  String _generateOtp() {
    final n = DateTime.now().millisecondsSinceEpoch % 1000000;
    return n.toString().padLeft(6, '0');
  }
}

class _PendingCustomerOtp {
  _PendingCustomerOtp({
    required this.phone,
    required this.otp,
    required this.expiresAt,
  });

  final String phone;
  final String otp;
  final DateTime expiresAt;
}
