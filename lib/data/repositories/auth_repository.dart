import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
    _restoreFirebaseSession();
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

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 'Email is required';
    if (password.isEmpty) return 'Password is required';

    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: normalized, password: password);
      final user = await _appUserForFirebaseUser(credential.user);
      if (user == null) {
        await firebase_auth.FirebaseAuth.instance.signOut();
        return 'Account profile not found. Contact support.';
      }
      if (user.role == AppRole.customer) {
        await firebase_auth.FirebaseAuth.instance.signOut();
        return 'Use Order water for customer login';
      }
      _currentUser = user;
      notifyListeners();
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      final localError = _loginMockDriver(normalized, password);
      if (localError == null) return null;
      return _loginAuthErrorMessage(e);
    } catch (_) {
      final localError = _loginMockDriver(normalized, password);
      if (localError == null) return null;
      return 'Could not sign in. Please try again';
    }
  }

  String? _loginMockDriver(String normalizedEmail, String password) {
    for (final account in _accounts) {
      if (account.user.email.toLowerCase() == normalizedEmail &&
          account.password == password) {
        _currentUser = account.user;
        notifyListeners();
        return null;
      }
    }
    return 'Invalid email or password';
  }

  Future<void> _restoreFirebaseSession() async {
    final user = await _appUserForFirebaseUser(
      firebase_auth.FirebaseAuth.instance.currentUser,
    );
    if (user == null || user.role == AppRole.customer) return;
    _currentUser = user;
    notifyListeners();
  }

  Future<AppUser?> _appUserForFirebaseUser(firebase_auth.User? user) async {
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return null;
    final role = _roleFromFirestore(data['role'] as String?);
    if (role == null) return null;
    return AppUser(
      id: user.uid,
      ownerName: data['name'] as String? ?? user.displayName ?? '',
      email: data['email'] as String? ?? user.email ?? '',
      phone: data['phone'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      role: role,
      driverId: data['driverId'] as String?,
      customerProfileComplete:
          data['customerProfileComplete'] as bool? ?? true,
    );
  }

  AppRole? _roleFromFirestore(String? role) {
    return switch (role) {
      'admin' => AppRole.admin,
      'driver' => AppRole.driver,
      'customer' => AppRole.customer,
      _ => null,
    };
  }

  Future<String?> register({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
    required String address,
    required double normalPrice,
    required double coolPrice,
    required bool homeDeliveryAvailable,
  }) async {
    final normalized = email.trim().toLowerCase();
    final cleanOwnerName = ownerName.trim();
    final cleanBusinessName = businessName.trim();
    final cleanPhone = phone.trim();
    final cleanAddress = address.trim();
    if (ownerName.trim().isEmpty) return 'Owner name is required';
    if (businessName.trim().isEmpty) return 'Business name is required';
    if (phone.trim().length < 10) return 'Valid phone number is required';
    if (cleanAddress.length < 8) return 'Shop address is required';
    if (normalized.isEmpty || !normalized.contains('@')) {
      return 'Valid email is required';
    }
    if (password.length < 6) return 'Password must be at least 6 characters';

    if (_accounts.any((a) => a.user.email.toLowerCase() == normalized)) {
      return 'An account with this email already exists';
    }

    firebase_auth.User? firebaseUser;
    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: normalized,
            password: password,
          );
      firebaseUser = credential.user;
      if (firebaseUser == null) return 'Could not create Firebase account';

      await firebaseUser.updateDisplayName(cleanOwnerName);

      final shopId = _uuid.v4();
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(firebaseUser.uid);
      final shopRef = db.collection('shops').doc(shopId);
      final now = FieldValue.serverTimestamp();

      final batch = db.batch();
      batch.set(userRef, {
        'role': 'admin',
        'name': cleanOwnerName,
        'email': normalized,
        'phone': cleanPhone,
        'businessName': cleanBusinessName,
        'shopId': shopId,
        'customerProfileComplete': true,
        'active': true,
        'createdAt': now,
        'updatedAt': now,
      });
      batch.set(shopRef, {
        'ownerUid': firebaseUser.uid,
        'name': cleanBusinessName,
        'address': cleanAddress,
        'phone': cleanPhone,
        'email': normalized,
        'normalPrice': normalPrice,
        'coolPrice': coolPrice,
        'homeDeliveryAvailable': homeDeliveryAvailable,
        'subscriptionStatus': 'trial',
        'trialEndsAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'active': true,
        'isListed': homeDeliveryAvailable,
        'createdAt': now,
        'updatedAt': now,
      });
      await batch.commit();

      final user = AppUser(
        id: firebaseUser.uid,
        ownerName: cleanOwnerName,
        email: normalized,
        phone: cleanPhone,
        businessName: cleanBusinessName,
        role: AppRole.admin,
      );
      _accounts.add(_StoredAccount(user: user, password: password));
      _currentUser = user;
      notifyListeners();
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } on FirebaseException catch (e) {
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {
          // If rollback fails, Firebase console cleanup may be needed.
        }
      }
      return e.message ?? 'Could not save account details';
    } catch (_) {
      return 'Could not create account. Please try again';
    }
  }

  String _authErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'Valid email is required';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again';
      default:
        return e.message ?? 'Could not create account';
    }
  }

  String _loginAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email';
      case 'user-disabled':
        return 'This account is disabled';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again';
      default:
        return e.message ?? 'Could not sign in';
    }
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

  void updateDriverAccount({
    required String driverId,
    required String name,
    required String phone,
    required String email,
  }) {
    final normalized = email.trim().toLowerCase();
    final index = _accounts.indexWhere((a) => a.user.driverId == driverId);
    if (index < 0) return;
    final user = _accounts[index].user;
    _accounts[index] = _StoredAccount(
      user: AppUser(
        id: user.id,
        ownerName: name.trim(),
        email: normalized,
        phone: phone.trim(),
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

  void deleteDriverAccount(String driverId) {
    _accounts.removeWhere((a) => a.user.driverId == driverId);
    if (_currentUser?.driverId == driverId) {
      _currentUser = null;
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

  Future<void> logout() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
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
  Future<String?> verifyCustomerOtp({
    required String phone,
    required String otp,
  }) async {
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

    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      final credential =
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();
      final firebaseUser = credential.user;
      if (firebaseUser == null) return 'Could not create customer session';

      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();
      await db.collection('users').doc(firebaseUser.uid).set({
        'role': 'customer',
        'name': 'Customer',
        'email': '',
        'phone': digits,
        'normalizedPhone': digits,
        'businessName': '',
        'customerProfileComplete': false,
        'active': true,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
      await db.collection('appCustomers').doc(firebaseUser.uid).set({
        'phone': digits,
        'normalizedPhone': digits,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      final user = AppUser(
        id: firebaseUser.uid,
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        return 'Enable Anonymous sign-in in Firebase Authentication';
      }
      return e.message ?? 'Could not verify OTP';
    } on FirebaseException catch (e) {
      return e.message ?? 'Could not save customer session';
    } catch (_) {
      return 'Could not verify OTP. Please try again';
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
