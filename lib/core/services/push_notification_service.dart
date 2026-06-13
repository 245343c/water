import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sri_sai_ro_water/core/services/firebase_backend.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';

/// Local device banners for delivery events.
class PushNotificationService {
  PushNotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;
  bool _ready = false;
  String? _registeredUserId;
  String? _lastRegisteredToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  Future<void> initialize() async {
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    if (_fcmSupported) {
      await _messaging.requestPermission();
      _foregroundSub = FirebaseMessaging.onMessage.listen(_showRemoteMessage);
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        final userId = _registeredUserId;
        if (userId == null) return;
        _registerToken(token).catchError((Object e, StackTrace st) {
          if (kDebugMode) {
            debugPrint('FCM token refresh skipped: $e');
          }
        });
      });
    }

    _ready = true;
  }

  Future<void> syncForUser(AppUser? user) async {
    await initialize();
    if (!_fcmSupported) return;
    if (user == null) {
      _registeredUserId = null;
      _lastRegisteredToken = null;
      return;
    }
    if (_registeredUserId == user.id && _lastRegisteredToken != null) return;
    _registeredUserId = user.id;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token registration skipped: $e');
      }
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_fcmSupported) return;
    try {
      final token = _lastRegisteredToken ??
          await _messaging
              .getToken()
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (token == null || token.isEmpty) return;
      await FirebaseBackend.functions
          .httpsCallable('unregisterFcmToken')
          .call({'token': token})
          .timeout(const Duration(seconds: 3));
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token unregister skipped: ${e.code}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token unregister skipped: $e');
      }
    }
    _lastRegisteredToken = null;
    _registeredUserId = null;
  }

  Future<void> _registerToken(String token) async {
    await FirebaseBackend.functions.httpsCallable('registerFcmToken').call({
      'token': token,
      'platform': _platformName(),
    });
    _lastRegisteredToken = token;
  }

  Future<void> _showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null || body == null) return;
    await showDeliveryRecorded(
      title: title,
      body: body,
      payload: message.data['type'] as String?,
    );
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      _ => 'unknown',
    };
  }

  bool get _fcmSupported {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  Future<void> showDeliveryRecorded({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'deliveries',
        'Deliveries',
        channelDescription: 'Delivery updates for admin and customers',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Fire-and-forget — never blocks UI on notification errors.
  void showDeliveryRecordedSafe({
    required String title,
    required String body,
    String? payload,
  }) {
    showDeliveryRecorded(title: title, body: body, payload: payload).catchError(
      (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Push notification skipped: $e');
        }
      },
    );
  }

  void dispose() {
    unawaited(_tokenRefreshSub?.cancel());
    unawaited(_foregroundSub?.cancel());
  }
}
