import 'dart:async';

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

/// Firebase-backed authentication for admins, drivers, and customers.
class AuthRepository extends ChangeNotifier {
  AuthRepository() {
    _restoreFirebaseSession();
  }

  static const _uuid = Uuid();
  final List<_StoredAccount> _accounts = [];

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalized = _staffLoginEmail(email);
    if (normalized.isEmpty) return 'Email or mobile number is required';
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
      return _loginAuthErrorMessage(e);
    } catch (_) {
      return 'Could not sign in. Please try again';
    }
  }

  String _staffLoginEmail(String value) {
    final cleaned = value.trim().toLowerCase();
    if (cleaned.contains('@')) return cleaned;
    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return '';
    return 'driver_$digits@waterapp.local';
  }

  Future<void> _restoreFirebaseSession() async {
    final user = await _appUserForFirebaseUser(
      firebase_auth.FirebaseAuth.instance.currentUser,
    );
    if (user == null) return;
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
    _clearPendingCustomerOtp();
    notifyListeners();
  }

  _PendingCustomerOtp? _pendingCustomerOtp;

  firebase_auth.ConfirmationResult? _webPhoneConfirmation;
  firebase_auth.PhoneAuthCredential? _autoVerifiedPhoneCredential;

  /// Sends a Firebase SMS verification code to an Indian mobile number.
  Future<String?> requestCustomerOtp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
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
    final credential = _autoVerifiedPhoneCredential ??
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

  Future<String?> requestPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return 'Enter a valid email address';
    }

    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: normalized,
      );
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') return 'Enter a valid email address';
      if (e.code == 'network-request-failed') {
        return 'Network error. Check your connection and try again';
      }
      // Avoid exposing whether an email address is registered.
      return null;
    }
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
