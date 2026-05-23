import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/core/services/api/api_auth_service.dart';
import 'package:sri_sai_ro_water/core/services/api/api_client.dart';
import 'package:sri_sai_ro_water/core/services/api/api_config.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:sri_sai_ro_water/data/mock/mock_auth_accounts.dart';
import 'package:sri_sai_ro_water/data/repositories/i_auth_repository.dart';
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

/// Authentication repository.
/// Uses the backend API when [useBackend] is true, otherwise uses mock in-memory data.
class AuthRepository extends IAuthRepository {
  AuthRepository() {
    _api = ApiAuthService(ApiClient.instance);
    if (!useBackend) {
      for (final seed in seedAuthAccounts()) {
        _accounts.add(_StoredAccount(user: seed.user, password: seed.password));
      }
    }
    if (useBackend) {
      _sessionRestoreFuture = _restoreSession();
    }
  }

  late final ApiAuthService _api;
  static const _uuid = Uuid();
  final List<_StoredAccount> _accounts = [];

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void>? _sessionRestoreFuture;

  Future<void> ensureSessionRestored() {
    if (!useBackend) return Future.value();
    _sessionRestoreFuture ??= _restoreSession();
    return _sessionRestoreFuture!;
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _api.getMe();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (_) {}
  }

  List<AppUser> get driverAccounts => _accounts
      .where((a) => a.user.role == AppRole.driver)
      .map((a) => a.user)
      .toList();

  String? login({required String email, required String password}) {
    if (useBackend) {
      // Async login via backend — call loginAsync instead for backend mode
      return 'Use loginAsync when backend is enabled';
    }
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

  /// Async login for backend mode. Returns null on success, error string on failure.
  Future<String?> loginAsync({required String email, required String password}) async {
    if (!useBackend) {
      return login(email: email, password: password);
    }
    try {
      final result = await _api.login(email: email, password: password);
      _currentUser = result.user;
      notifyListeners();
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }
  }

  /// Async register for backend mode.
  Future<String?> registerAsync({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (!useBackend) {
      return register(
        ownerName: ownerName,
        businessName: businessName,
        phone: phone,
        email: email,
        password: password,
      );
    }
    try {
      final result = await _api.register(
        ownerName: ownerName,
        businessName: businessName,
        phone: phone,
        email: email,
        password: password,
      );
      _currentUser = result.user;
      notifyListeners();
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }
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

  /// Request password reset OTP (backend or mock).
  Future<String?> requestPasswordResetAsync(String email) async {
    if (!useBackend) {
      return requestPasswordReset(email);
    }
    try {
      return await _api.forgotPassword(email.trim());
    } catch (e) {
      if (e is ApiException) return null;
      return null;
    }
  }

  /// Reset password with OTP (backend or mock).
  Future<String?> resetPasswordWithOtpAsync({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (!useBackend) {
      return resetPasswordWithOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
    }
    try {
      return await _api.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
    } catch (e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }
  }

  /// Admin creates driver login linked to [driverId] from [WaterPlantRepository].
  Future<String?> createDriverAccountAsync({
    required String driverId,
    required String name,
    required String phone,
    required String email,
    required String password,
    String? shopId,
  }) async {
    if (!useBackend) {
      return createDriverAccount(
        driverId: driverId,
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
    }
    return _api.createDriverAccount(
      driverId: driverId,
      name: name,
      phone: phone,
      email: email,
      password: password,
      shopId: shopId,
    );
  }

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
    if (useBackend) {
      _api.logout();
    }
    _currentUser = null;
    _pendingCustomerOtp = null;
    notifyListeners();
  }

  /// Google sign-in for customer. In backend mode, calls `/auth/customer/google`.
  /// In mock mode, creates a demo customer session from email/name.
  Future<String?> loginWithGoogleAsync({
    required String email,
    required String name,
    String? phone,
    String? photoUrl,
    String? idToken,
  }) async {
    if (useBackend) {
      try {
        final result = await _api.loginWithGoogle(
          email: email,
          name: name,
          phone: phone,
          photoUrl: photoUrl,
          idToken: idToken,
        );
        _currentUser = result.user;
        notifyListeners();
        return null;
      } catch (e) {
        return e.toString();
      }
    }
    // Mock: create customer user from provided details
    final existing = _accounts.where((a) => a.user.email == email.toLowerCase().trim()).toList();
    if (existing.isNotEmpty) {
      _currentUser = existing.first.user;
    } else {
      final user = AppUser(
        id: _uuid.v4(),
        ownerName: name,
        email: email.trim().toLowerCase(),
        phone: phone ?? '',
        businessName: '',
        role: AppRole.customer,
      );
      _accounts.add(_StoredAccount(user: user, password: ''));
      _currentUser = user;
    }
    notifyListeners();
    return null;
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

  Future<String?> requestCustomerOtpAsync(String phone) async {
    if (!useBackend) return requestCustomerOtp(phone);
    try {
      return await _api.requestCustomerOtp(phone);
    } catch (e) {
      if (e is ApiException) rethrow;
      return null;
    }
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

  Future<String?> verifyCustomerOtpAsync({
    required String phone,
    required String otp,
  }) async {
    if (!useBackend) {
      return verifyCustomerOtp(phone: phone, otp: otp);
    }
    try {
      final result = await _api.verifyCustomerOtp(phone: phone, otp: otp);
      _currentUser = result.user;
      notifyListeners();
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }
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
