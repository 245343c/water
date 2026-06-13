import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/core/services/firebase_backend.dart';
import 'package:sri_sai_ro_water/core/utils/input_validators.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:uuid/uuid.dart';

class _StoredAccount {
  _StoredAccount({required this.user, required this.password});

  final AppUser user;
  String password;
}

/// Firebase-backed authentication for admins, drivers, and customers.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    bool restoreFirebaseSession = true,
    bool useMockCustomerOtp = false,
  }) : _useMockCustomerOtp = useMockCustomerOtp {
    if (restoreFirebaseSession) {
      _restoreFirebaseSession();
    }
  }

  static const _uuid = Uuid();
  final List<_StoredAccount> _accounts = [];
  final bool _useMockCustomerOtp;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final candidates = _staffLoginEmails(email);
    if (candidates.isEmpty) return 'Email or mobile number is required';
    if (password.isEmpty) return 'Password is required';

    for (var i = 0; i < candidates.length; i++) {
      try {
        final credential = await firebase_auth.FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: candidates[i],
              password: password,
            );
        final user = await _appUserForFirebaseUser(credential.user);
        if (user == null) {
          await firebase_auth.FirebaseAuth.instance.signOut();
          return 'Account profile not found. Contact support.';
        }
        if (user.role == AppRole.customer) {
          await firebase_auth.FirebaseAuth.instance.signOut();
          return 'Customer app access is not available in this release';
        }
        if (user.role == AppRole.admin &&
            credential.user?.emailVerified != true &&
            credential.user?.phoneNumber == null) {
          await credential.user?.sendEmailVerification();
          await firebase_auth.FirebaseAuth.instance.signOut();
          return 'Verify your email or mobile first.';
        }
        _currentUser = user;
        notifyListeners();
        return null;
      } on firebase_auth.FirebaseAuthException catch (e) {
        final canTryNext =
            i < candidates.length - 1 &&
            (e.code == 'user-not-found' ||
                e.code == 'wrong-password' ||
                e.code == 'invalid-credential');
        if (!canTryNext) return _loginAuthErrorMessage(e);
      } catch (_) {
        return 'Could not sign in. Please try again';
      }
    }
    return 'Invalid login ID or password';
  }

  List<String> _staffLoginEmails(String value) {
    final cleaned = InputValidators.normalizeEmail(value);
    if (cleaned.contains('@')) {
      return InputValidators.isValidEmail(cleaned) ? [cleaned] : const [];
    }
    final digits = InputValidators.phoneDigits(cleaned);
    if (!InputValidators.isValidIndianMobile(digits)) return const [];
    return [_adminAuthEmail(digits), _driverAuthEmail(digits)];
  }

  String _adminAuthEmail(String phoneDigits) =>
      'admin_$phoneDigits@waterapp.local';

  String _driverAuthEmail(String phoneDigits) =>
      'driver_$phoneDigits@waterapp.local';

  Future<void> _restoreFirebaseSession() async {
    final user = await _appUserForFirebaseUser(
      firebase_auth.FirebaseAuth.instance.currentUser,
    );
    if (user == null) return;
    if (user.role == AppRole.customer) {
      await firebase_auth.FirebaseAuth.instance.signOut();
      return;
    }
    if (user.role == AppRole.admin &&
        firebase_auth.FirebaseAuth.instance.currentUser?.emailVerified !=
            true &&
        firebase_auth.FirebaseAuth.instance.currentUser?.phoneNumber == null) {
      await firebase_auth.FirebaseAuth.instance.signOut();
      return;
    }
    _currentUser = user;
    notifyListeners();
  }

  Future<AppUser?> _appUserForFirebaseUser(firebase_auth.User? user) async {
    if (user == null) return null;
    if (user.isAnonymous) return null;
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
      customerProfileComplete: data['customerProfileComplete'] as bool? ?? true,
      pricingSetupComplete: data['pricingSetupComplete'] as bool? ?? true,
    );
  }

  void markPricingSetupComplete() {
    final user = _currentUser;
    if (user == null || !user.isAdmin) return;
    _currentUser = AppUser(
      id: user.id,
      ownerName: user.ownerName,
      email: user.email,
      phone: user.phone,
      businessName: user.businessName,
      role: user.role,
      driverId: user.driverId,
      customerProfileComplete: user.customerProfileComplete,
      pricingSetupComplete: true,
    );
    notifyListeners();
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
  }) {
    return Future.value(
      'Use mobile OTP signup on the registration screen.',
    );
  }

  Future<String?> requestAdminRegistrationOtp({
    required String phone,
    required String email,
  }) async {
    final digits = InputValidators.phoneDigits(phone);
    final normalizedEmail = InputValidators.normalizeEmail(email);
    if (!InputValidators.isValidIndianMobile(digits)) {
      return 'Enter a valid 10-digit mobile number';
    }
    if (normalizedEmail.isNotEmpty &&
        !InputValidators.isValidEmail(normalizedEmail)) {
      return 'Enter a valid real email address';
    }

    try {
      await FirebaseBackend.functions
          .httpsCallable('checkAdminSignupAvailability')
          .call({'phone': digits, 'email': normalizedEmail});
    } on FirebaseException catch (e) {
      return _adminSignupFunctionErrorMessage(
        e,
        fallback: 'Could not check account details',
      );
    } catch (_) {
      return 'Could not check account details';
    }

    _clearPendingAdminOtp();
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      if (kIsWeb) {
        _adminWebPhoneConfirmation = await firebase_auth.FirebaseAuth.instance
            .signInWithPhoneNumber('+91$digits');
        _pendingAdminOtp = _PendingCustomerOtp(
          phone: digits,
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        return null;
      }

      final result = Completer<String?>();
      await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$digits',
        verificationCompleted: (credential) {
          _adminAutoVerifiedPhoneCredential = credential;
          _pendingAdminOtp ??= _PendingCustomerOtp(
            phone: digits,
            expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          );
          if (!result.isCompleted) result.complete(null);
        },
        verificationFailed: (error) {
          if (!result.isCompleted) {
            result.complete(_phoneAuthErrorMessage(error));
          }
        },
        codeSent: (verificationId, _) {
          _pendingAdminOtp = _PendingCustomerOtp(
            phone: digits,
            verificationId: verificationId,
            expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          );
          if (!result.isCompleted) result.complete(null);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          final pending = _pendingAdminOtp;
          if (pending != null && pending.verificationId == null) {
            _pendingAdminOtp = _PendingCustomerOtp(
              phone: digits,
              verificationId: verificationId,
              expiresAt: pending.expiresAt,
            );
          }
        },
      );
      return result.future;
    } on firebase_auth.FirebaseAuthException catch (e) {
      return _phoneAuthErrorMessage(e);
    } catch (_) {
      return 'Could not send OTP. Please try again';
    }
  }

  Future<String?> completeAdminRegistrationWithOtp({
    required String ownerName,
    required String businessName,
    required String phone,
    required String email,
    required String password,
    required String address,
    required double normalPrice,
    required double coolPrice,
    required bool homeDeliveryAvailable,
    required String otp,
  }) async {
    final digits = InputValidators.phoneDigits(phone);
    final normalizedEmail = InputValidators.normalizeEmail(email);
    final authEmail = normalizedEmail.isEmpty
        ? _adminAuthEmail(digits)
        : normalizedEmail;
    final pending = _pendingAdminOtp;
    if (pending == null || pending.phone != digits) {
      return 'Send OTP to your mobile first';
    }
    if (DateTime.now().isAfter(pending.expiresAt)) {
      _clearPendingAdminOtp();
      return 'OTP expired. Request again';
    }
    if (ownerName.trim().isEmpty) return 'Owner name is required';
    if (businessName.trim().isEmpty) return 'Business name is required';
    if (address.trim().length < 8) return 'Shop address is required';
    if (normalizedEmail.isNotEmpty &&
        !InputValidators.isValidEmail(normalizedEmail)) {
      return 'Enter a valid real email address';
    }
    if (password.length < 6) return 'Password must be at least 6 characters';

    try {
      final credential = await _confirmAdminOtp(otp.trim());
      final firebaseUser = credential.user;
      if (firebaseUser == null) return 'Could not verify mobile number';

      final emailCredential = firebase_auth.EmailAuthProvider.credential(
        email: authEmail,
        password: password,
      );
      try {
        await firebaseUser.linkWithCredential(emailCredential);
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code != 'provider-already-linked') rethrow;
      }

      final result = await FirebaseBackend.functions
          .httpsCallable('completeAdminRegistration')
          .call({
            'ownerName': ownerName.trim(),
            'businessName': businessName.trim(),
            'phone': digits,
            'email': normalizedEmail,
            'address': address.trim(),
            'normalPrice': normalPrice,
            'coolPrice': coolPrice,
            'homeDeliveryAvailable': homeDeliveryAvailable,
          });
      final data = Map<String, dynamic>.from(result.data as Map);
      final userData = Map<String, dynamic>.from(data['user'] as Map);
      final user = AppUser(
        id: userData['id'] as String? ?? firebaseUser.uid,
        ownerName: userData['ownerName'] as String? ?? ownerName.trim(),
        email: userData['email'] as String? ?? normalizedEmail,
        phone: userData['phone'] as String? ?? digits,
        businessName:
            userData['businessName'] as String? ?? businessName.trim(),
        role: AppRole.admin,
      );
      _accounts.add(_StoredAccount(user: user, password: password));
      _currentUser = null;
      _clearPendingAdminOtp();
      await firebase_auth.FirebaseAuth.instance.signOut();
      notifyListeners();
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      return _adminSignupAuthErrorMessage(e);
    } on FirebaseException catch (e) {
      return _adminSignupFunctionErrorMessage(
        e,
        fallback: 'Could not create account',
      );
    } catch (_) {
      return 'Could not create account. Please try again';
    }
  }

  String _loginAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email or mobile number';
      case 'user-disabled':
        return 'This account is disabled';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid login ID or password';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again';
      default:
        return e.message ?? 'Could not sign in';
    }
  }

  String _adminSignupAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'Email or mobile number already has an account';
      case 'invalid-verification-code':
        return 'Invalid OTP';
      case 'session-expired':
        return 'OTP expired. Request again';
      case 'invalid-email':
        return 'Enter a valid real email address';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again';
      default:
        return e.message ?? 'Could not create account';
    }
  }

  String _adminSignupFunctionErrorMessage(
    FirebaseException e, {
    required String fallback,
  }) {
    if (e.code == 'not-found') {
      return 'Firebase signup functions are not deployed yet. Deploy Cloud Functions and try again.';
    }
    if (e.code == 'already-exists') {
      return e.message ?? 'Email or mobile number already has an account';
    }
    if (e.code == 'invalid-argument') {
      return e.message ?? 'Check the entered account details';
    }
    if (e.code == 'permission-denied' || e.code == 'failed-precondition') {
      return e.message ?? 'Could not verify account details';
    }
    if (e.code == 'unavailable') {
      return 'Firebase is temporarily unavailable. Please try again';
    }
    return e.message ?? fallback;
  }

  /// Admin creates driver login linked to [driverId] from [WaterPlantRepository].
  String? createDriverAccount({
    required String driverId,
    required String name,
    required String phone,
    required String email,
    required String password,
  }) {
    final normalized = InputValidators.normalizeEmail(email);
    if (name.trim().isEmpty) return 'Name is required';
    if (!InputValidators.isValidIndianMobile(phone)) {
      return 'Enter a valid 10-digit mobile number';
    }
    if (!InputValidators.isValidEmail(normalized)) {
      return 'Enter a valid real email address';
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
      phone: InputValidators.phoneDigits(phone),
      businessName: 'Sri Sai RO Water Plant',
      role: AppRole.driver,
      driverId: driverId,
    );
    _accounts.add(_StoredAccount(user: user, password: password));
    notifyListeners();
    return null;
  }

  void updateDriverAccountEmail(String driverId, String newEmail) {
    final normalized = InputValidators.normalizeEmail(newEmail);
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
    final normalized = InputValidators.normalizeEmail(email);
    final index = _accounts.indexWhere((a) => a.user.driverId == driverId);
    if (index < 0) return;
    final user = _accounts[index].user;
    _accounts[index] = _StoredAccount(
      user: AppUser(
        id: user.id,
        ownerName: name.trim(),
        email: normalized,
        phone: InputValidators.phoneDigits(phone),
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
    _clearPendingCustomerOtp();
    _clearPendingAdminOtp();
    notifyListeners();
  }

  _PendingCustomerOtp? _pendingCustomerOtp;
  _PendingCustomerOtp? _pendingAdminOtp;

  firebase_auth.ConfirmationResult? _webPhoneConfirmation;
  firebase_auth.PhoneAuthCredential? _autoVerifiedPhoneCredential;
  firebase_auth.ConfirmationResult? _adminWebPhoneConfirmation;
  firebase_auth.PhoneAuthCredential? _adminAutoVerifiedPhoneCredential;

  /// Sends a Firebase SMS verification code to an Indian mobile number.
  Future<String?> requestCustomerOtp(String phone) async {
    final digits = InputValidators.phoneDigits(phone);
    if (!InputValidators.isValidIndianMobile(digits)) {
      return 'Enter a valid 10-digit mobile number';
    }
    if (_useMockCustomerOtp) {
      _pendingCustomerOtp = _PendingCustomerOtp(
        phone: digits,
        verificationId: 'mock',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
      return null;
    }
    final phoneNumber = '+91$digits';
    _clearPendingCustomerOtp();

    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      if (kIsWeb) {
        _webPhoneConfirmation = await firebase_auth.FirebaseAuth.instance
            .signInWithPhoneNumber(phoneNumber);
        _pendingCustomerOtp = _PendingCustomerOtp(
          phone: digits,
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        return null;
      }

      final result = Completer<String?>();
      await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          _autoVerifiedPhoneCredential = credential;
          _pendingCustomerOtp ??= _PendingCustomerOtp(
            phone: digits,
            expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          );
          if (!result.isCompleted) result.complete(null);
        },
        verificationFailed: (error) {
          if (!result.isCompleted) {
            result.complete(_phoneAuthErrorMessage(error));
          }
        },
        codeSent: (verificationId, _) {
          _pendingCustomerOtp = _PendingCustomerOtp(
            phone: digits,
            verificationId: verificationId,
            expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          );
          if (!result.isCompleted) result.complete(null);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          final pending = _pendingCustomerOtp;
          if (pending != null && pending.verificationId == null) {
            _pendingCustomerOtp = _PendingCustomerOtp(
              phone: digits,
              verificationId: verificationId,
              expiresAt: pending.expiresAt,
            );
          }
        },
      );
      return result.future;
    } on firebase_auth.FirebaseAuthException catch (e) {
      return _phoneAuthErrorMessage(e);
    } catch (_) {
      return 'Could not send OTP. Please try again';
    }
  }

  String _phoneAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
        return 'Enable Phone sign-in in Firebase Authentication';
      case 'invalid-phone-number':
        return 'Enter a valid 10-digit mobile number';
      case 'invalid-app-credential':
      case 'captcha-check-failed':
      case 'missing-app-credential':
        return kIsWeb
            ? 'Customer OTP cannot be tested from localhost. Use the Android APK or a hosted web domain.'
            : 'Phone verification failed. Please try again';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'OTP limit reached. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again';
      default:
        return e.message ?? 'Could not send OTP';
    }
  }

  Future<firebase_auth.UserCredential> _confirmCustomerOtp(String otp) {
    if (kIsWeb) {
      final confirmation = _webPhoneConfirmation;
      if (confirmation == null) {
        throw StateError('Send OTP to your phone first');
      }
      return confirmation.confirm(otp);
    }
    final pending = _pendingCustomerOtp;
    final credential =
        _autoVerifiedPhoneCredential ??
        firebase_auth.PhoneAuthProvider.credential(
          verificationId: pending?.verificationId ?? '',
          smsCode: otp,
        );
    return firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<firebase_auth.UserCredential> _confirmAdminOtp(String otp) {
    if (kIsWeb) {
      final confirmation = _adminWebPhoneConfirmation;
      if (confirmation == null) {
        throw StateError('Send OTP to your mobile first');
      }
      return confirmation.confirm(otp);
    }
    final pending = _pendingAdminOtp;
    final credential =
        _adminAutoVerifiedPhoneCredential ??
        firebase_auth.PhoneAuthProvider.credential(
          verificationId: pending?.verificationId ?? '',
          smsCode: otp,
        );
    return firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
  }

  void _clearPendingCustomerOtp() {
    _pendingCustomerOtp = null;
    _webPhoneConfirmation = null;
    _autoVerifiedPhoneCredential = null;
  }

  void _clearPendingAdminOtp() {
    _pendingAdminOtp = null;
    _adminWebPhoneConfirmation = null;
    _adminAutoVerifiedPhoneCredential = null;
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
    if (_useMockCustomerOtp) {
      if (otp.trim() != '123456') return 'Invalid OTP';
      final user = AppUser(
        id: 'customer-$digits',
        ownerName: 'Customer',
        email: '',
        phone: digits,
        businessName: '',
        role: AppRole.customer,
        customerProfileComplete: false,
      );
      _accounts.removeWhere((a) => a.user.id == user.id);
      _accounts.add(_StoredAccount(user: user, password: ''));
      _currentUser = user;
      _clearPendingCustomerOtp();
      notifyListeners();
      return null;
    }
    try {
      final credential = await _confirmCustomerOtp(otp.trim());
      final firebaseUser = credential.user;
      if (firebaseUser == null) return 'Could not create customer session';

      final user = AppUser(
        id: firebaseUser.uid,
        ownerName: 'Customer',
        email: '',
        phone: digits,
        businessName: '',
        role: AppRole.customer,
        customerProfileComplete: false,
      );
      _accounts.removeWhere((a) => a.user.id == user.id);
      _accounts.add(_StoredAccount(user: user, password: ''));
      _currentUser = user;
      _clearPendingCustomerOtp();
      notifyListeners();
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') return 'Invalid OTP';
      if (e.code == 'session-expired') return 'OTP expired. Request again';
      return _phoneAuthErrorMessage(e);
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

  Future<String?> requestPasswordReset(String loginId) async {
    final trimmed = loginId.trim();
    if (trimmed.isEmpty) {
      return 'Mobile number or email is required';
    }

    final candidates = _staffLoginEmails(trimmed);
    if (candidates.isEmpty) {
      final normalized = InputValidators.normalizeEmail(trimmed);
      if (!InputValidators.isValidEmail(normalized)) {
        return 'Enter a valid mobile number or email';
      }
    }

    final emails = candidates.isNotEmpty
        ? candidates
        : [InputValidators.normalizeEmail(trimmed)];

    for (var i = 0; i < emails.length; i++) {
      try {
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
          email: emails[i],
        );
        return null;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'invalid-email') {
          return 'Enter a valid mobile number or email';
        }
        if (e.code == 'network-request-failed') {
          return 'Network error. Check your connection and try again';
        }
        final canTryNext =
            i < emails.length - 1 &&
            (e.code == 'user-not-found' || e.code == 'invalid-credential');
        if (!canTryNext) {
          // Avoid exposing whether an account exists.
          return null;
        }
      }
    }
    return null;
  }
}

class _PendingCustomerOtp {
  _PendingCustomerOtp({
    required this.phone,
    required this.expiresAt,
    this.verificationId,
  });

  final String phone;
  final DateTime expiresAt;
  final String? verificationId;
}
