import 'package:shared_preferences/shared_preferences.dart';

/// Persists daily dismiss for the dashboard trial banner (per shop).
abstract final class SubscriptionBannerPrefs {
  static const _prefix = 'trial_banner_dismiss_';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static Future<bool> wasDismissedToday(String shopId) async {
    if (shopId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$shopId') == _todayKey();
  }

  static Future<void> dismissForToday(String shopId) async {
    if (shopId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$shopId', _todayKey());
  }
}
