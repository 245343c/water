import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Device banners for delivery events (local mock until FCM backend).
class PushNotificationService {
  PushNotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _ready = true;
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
}
