import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'api_client.dart';

class ApiAuthResult {
  const ApiAuthResult({required this.user, required this.token});
  final AppUser user;
  final String token;
}

class ApiAuthService {
  const ApiAuthService(this._client);
  final ApiClient _client;

  AppUser _parseUser(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'customer';
    final role = switch (roleStr) {
      'shop_admin' => AppRole.admin,
      'driver' => AppRole.driver,
      _ => AppRole.customer,
    };
    return AppUser(
      id: json['uid'] as String,
      ownerName: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      businessName: '',
      role: role,
      driverId: json['driverId'] as String?,
      customerProfileComplete: json['profileCompleted'] as bool? ?? false,
    );
  }

  Future<ApiAuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/login',
      {'email': email, 'password': password},
      requireAuth: false,
    );
    final token = data['token'] as String;
    await _client.saveToken(token);
    return ApiAuthResult(user: _parseUser(data['user'] as Map<String, dynamic>), token: token);
  }

  Future<ApiAuthResult> register({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/register',
      {
        'name': ownerName,
        'businessName': businessName,
        'phone': phone,
        'email': email,
        'password': password,
      },
      requireAuth: false,
    );
    final token = data['token'] as String;
    await _client.saveToken(token);
    return ApiAuthResult(user: _parseUser(data['user'] as Map<String, dynamic>), token: token);
  }

  Future<String?> requestCustomerOtp(String phone) async {
    try {
      final data = await _client.post(
        '/auth/customer/request-otp',
        {'phone': phone},
        requireAuth: false,
      );
      return data['otp'] as String?;
    } catch (e) {
      if (e is ApiException) rethrow;
      return null;
    }
  }

  Future<ApiAuthResult> verifyCustomerOtp({
    required String phone,
    required String otp,
  }) async {
    final data = await _client.post(
      '/auth/customer/verify-otp',
      {'phone': phone, 'otp': otp},
      requireAuth: false,
    );
    final token = data['token'] as String;
    await _client.saveToken(token);
    return ApiAuthResult(user: _parseUser(data['user'] as Map<String, dynamic>), token: token);
  }

  Future<void> updateMe({String? name, bool? profileCompleted}) async {
    await _client.patch('/auth/me', {
      if (name != null) 'name': name,
      if (profileCompleted != null) 'profileCompleted': profileCompleted,
    });
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout', {});
    } catch (_) {}
    await _client.clearToken();
  }

  Future<AppUser?> getMe() async {
    try {
      final data = await _client.get('/auth/me');
      return _parseUser(data['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final data = await _client.post(
        '/auth/forgot-password',
        {'email': email},
        requireAuth: false,
      );
      return data['otp'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        '/auth/reset-password',
        {'email': email, 'otp': otp, 'newPassword': newPassword},
        requireAuth: false,
      );
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }
  }

  Future<ApiAuthResult> loginWithGoogle({
    required String idToken,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    final data = await _client.post(
      '/auth/customer/google',
      {
        'idToken': idToken,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
      requireAuth: false,
    );
    final token = data['token'] as String;
    await _client.saveToken(token);
    return ApiAuthResult(
      user: _parseUser(data['user'] as Map<String, dynamic>),
      token: token,
    );
  }

  Future<String?> createDriverAccount({
    required String driverId,
    required String name,
    required String phone,
    required String email,
    required String password,
    String? shopId,
  }) async {
    try {
      await _client.post(
        '/auth/driver',
        {
          'driverId': driverId,
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          if (shopId != null) 'shopId': shopId,
        },
      );
      return null;
    } catch (e) {
      if (e is ApiException) return e.message;
      return e.toString();
    }
  }
}
