import 'package:sri_sai_ro_water/core/services/api/api_auth_service.dart';
import 'package:sri_sai_ro_water/core/services/api/api_client.dart';
import 'package:sri_sai_ro_water/core/services/api/api_config.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:sri_sai_ro_water/data/repositories/i_auth_repository.dart';

/// Authentication repository — backend API only ([useBackend] must be true).
class AuthRepository extends IAuthRepository {
  AuthRepository() {
    assert(useBackend, 'AuthRepository requires useBackend = true');
    _api = ApiAuthService(ApiClient.instance);
    _sessionRestoreFuture = _restoreSession();
  }

  late final ApiAuthService _api;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  @override
  List<AppUser> get driverAccounts => const [];

  Future<void>? _sessionRestoreFuture;

  Future<void> ensureSessionRestored() {
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

  @override
  String? login({required String email, required String password}) {
    throw UnsupportedError('Use loginAsync — backend-only mode');
  }

  Future<String?> loginAsync({
    required String email,
    required String password,
  }) async {
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

  @override
  String? register({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
  }) {
    throw UnsupportedError('Use registerAsync — backend-only mode');
  }

  Future<String?> registerAsync({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
  }) async {
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

  Future<String?> requestPasswordResetAsync(String email) async {
    try {
      return await _api.forgotPassword(email.trim());
    } catch (e) {
      if (e is ApiException) return null;
      return null;
    }
  }

  Future<String?> resetPasswordWithOtpAsync({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
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

  Future<String?> createDriverAccountAsync({
    required String driverId,
    required String name,
    required String phone,
    required String email,
    required String password,
    String? shopId,
  }) async {
    return _api.createDriverAccount(
      driverId: driverId,
      name: name,
      phone: phone,
      email: email,
      password: password,
      shopId: shopId,
    );
  }

  @override
  String? createDriverAccount({
    required String driverId,
    required String name,
    required String phone,
    required String email,
    required String password,
  }) {
    throw UnsupportedError('Use createDriverAccountAsync — backend-only mode');
  }

  @override
  void updateDriverAccountEmail(String driverId, String newEmail) {
    throw UnsupportedError('Driver email is managed on the server');
  }

  void updateDriverAccount({
    required String driverId,
    required String name,
    required String phone,
    required String email,
  }) {
    throw UnsupportedError('Driver account updates are handled via drivers API');
  }

  void deleteDriverAccount(String driverId) {
    throw UnsupportedError('Driver account deletion is handled via drivers API');
  }

  @override
  void resetDriverPassword(String driverId, String newPassword) {
    throw UnsupportedError('Use admin password reset flow on the server');
  }

  @override
  bool hasAccountForDriver(String driverId) {
    throw UnsupportedError('Use WaterPlantRepository.driverHasLoginAccount');
  }

  @override
  AppUser? accountForDriver(String driverId) => null;

  void logout() {
    _api.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Dev/demo OTP in app memory — production uses API ([requestCustomerOtpAsync]).
  @override
  String? requestCustomerOtp(String phone) {
    throw UnsupportedError('Use requestCustomerOtpAsync — backend-only mode');
  }

  Future<String?> requestCustomerOtpAsync(String phone) async {
    try {
      return await _api.requestCustomerOtp(phone);
    } catch (e) {
      if (e is ApiException) rethrow;
      return null;
    }
  }

  @override
  String? verifyCustomerOtp({
    required String phone,
    required String otp,
  }) {
    throw UnsupportedError('Use verifyCustomerOtpAsync — backend-only mode');
  }

  Future<String?> verifyCustomerOtpAsync({
    required String phone,
    required String otp,
  }) async {
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

  /// Google Sign-In — call when Flutter [google_sign_in] provides an idToken.
  Future<String?> loginWithGoogleAsync({
    required String idToken,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final result = await _api.loginWithGoogle(
        idToken: idToken,
        name: name,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
      );
      _currentUser = result.user;
      notifyListeners();
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }
  }

  @override
  void deleteCustomerAccount(String userId) {
    if (_currentUser?.id == userId) {
      _currentUser = null;
      notifyListeners();
    }
  }

  @override
  void markCustomerOnboardingComplete(String userId, {required String name}) {
    if (_currentUser?.id == userId) {
      final u = _currentUser!;
      _currentUser = AppUser(
        id: u.id,
        ownerName: name,
        email: u.email,
        phone: u.phone,
        businessName: u.businessName,
        role: u.role,
        driverId: u.driverId,
        customerProfileComplete: true,
      );
      notifyListeners();
    }
    _api
        .updateMe(name: name, profileCompleted: true)
        .catchError((_) {});
  }

  @override
  String? requestPasswordReset(String email) {
    throw UnsupportedError('Use requestPasswordResetAsync — backend-only mode');
  }

  @override
  String? resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    throw UnsupportedError('Use resetPasswordWithOtpAsync — backend-only mode');
  }

  @override
  void cancelPasswordReset() {}
}
