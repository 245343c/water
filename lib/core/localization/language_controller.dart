import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';

class LanguageController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  String? _loadedUserId;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  AppStrings get strings => AppStrings(_language);

  Future<void> syncForUser(AppUser? user) async {
    if (user == null) {
      _loadedUserId = null;
      return;
    }
    if (_loadedUserId == user.id) return;
    _loadedUserId = user.id;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .get();
    final code = snap.data()?['languageCode'] as String?;
    if (code == null || code.trim().isEmpty) {
      unawaited(saveForCurrentUser(user));
      return;
    }
    _setLanguage(AppLanguage.fromCode(code), notify: true);
  }

  Future<void> setLanguage(AppLanguage language, {AppUser? user}) async {
    _setLanguage(language, notify: true);
    if (user != null) {
      await saveForCurrentUser(user);
    }
  }

  Future<void> saveForCurrentUser(AppUser user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).set({
      'languageCode': _language.code,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _setLanguage(AppLanguage language, {required bool notify}) {
    if (_language == language) return;
    _language = language;
    if (notify) notifyListeners();
  }
}
