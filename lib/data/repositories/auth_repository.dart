import 'package:flutter/foundation.dart';
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
        ),
        password: 'admin123',
      ),
    );
  }

  static const _uuid = Uuid();
  final List<_StoredAccount> _accounts = [];

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String? login({required String email, required String password}) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 'Email is required';
    if (password.isEmpty) return 'Password is required';

    for (final account in _accounts) {
      if (account.user.email.toLowerCase() == normalized &&
          account.password == password) {
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
    );
    _accounts.add(_StoredAccount(user: user, password: password));
    _currentUser = user;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  _PendingPasswordReset? _pendingReset;
  static const _otpLifetime = Duration(minutes: 10);
  static const _maxOtpAttempts = 5;

  /// Always succeeds from the UI perspective (does not reveal if email exists).
  /// Returns a demo OTP only when the email is registered (mock — replace with email/SMS API).
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
