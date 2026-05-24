import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/core/services/api/api_config.dart';
import 'package:sri_sai_ro_water/core/services/api/api_data_service.dart';
import 'package:sri_sai_ro_water/core/services/api/api_client.dart';
import 'package:sri_sai_ro_water/data/models/app_notification.dart';

class NotificationRepository extends ChangeNotifier {
  final List<AppNotification> _items = [];
  late final ApiDataService _apiService = ApiDataService(ApiClient.instance);

  /// Fetch notifications from backend (server creates them on order/delivery events).
  Future<void> loadFromBackend() async {
    if (!useBackend) return;
    try {
      final data = await _apiService.listNotifications();
      final list = data['notifications'] as List<dynamic>? ?? [];
      _items.clear();
      for (final n in list) {
        final map = n as Map<String, dynamic>;
        final typeStr = map['type'] as String? ?? 'orderPlaced';
        final type = switch (typeStr) {
          'orderAccepted' => AppNotificationType.orderAccepted,
          'orderRejected' => AppNotificationType.orderRejected,
          'deliveryRecorded' => AppNotificationType.deliveryRecorded,
          'paymentReceived' => AppNotificationType.paymentReceived,
          _ => AppNotificationType.orderPlaced,
        };
        final audienceStr = map['audience'] as String? ?? 'admin';
        final audience = switch (audienceStr) {
          'driver' => AppRole.driver,
          'customer' => AppRole.customer,
          _ => AppRole.admin,
        };
        _items.add(AppNotification(
          id: map['notificationId'] as String? ?? map['_id'] as String,
          type: type,
          title: map['title'] as String? ?? '',
          body: map['body'] as String? ?? '',
          audience: audience,
          customerId: map['customerId'] as String?,
          orderId: map['orderId'] as String?,
          deliveryId: map['deliveryId'] as String?,
          driverId: map['driverId'] as String?,
          read: map['read'] as bool? ?? false,
          createdAt: map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : DateTime.now(),
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('loadNotificationsFromBackend error: $e');
    }
  }

  List<AppNotification> get all => List.unmodifiable(_items);

  List<AppNotification> forAdmin() =>
      _items.where((n) => n.audience == AppRole.admin).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<AppNotification> forCustomer(String customerId) =>
      _items
          .where(
            (n) => n.audience == AppRole.customer && n.customerId == customerId,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int unreadCountForAdmin() =>
      _items.where((n) => n.audience == AppRole.admin && !n.read).length;

  int unreadCountForCustomer(String customerId) => _items
      .where(
        (n) =>
            n.audience == AppRole.customer &&
            n.customerId == customerId &&
            !n.read,
      )
      .length;

  List<AppNotification> forDriver() =>
      _items.where((n) => n.audience == AppRole.driver).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int unreadCountForDriver() =>
      _items.where((n) => n.audience == AppRole.driver && !n.read).length;

  void markAllReadForDriver() {
    for (final n in _items) {
      if (n.audience == AppRole.driver) n.read = true;
    }
    notifyListeners();

    if (useBackend) {
      _apiService.markAllNotificationsRead().then((_) {}).catchError((Object e) {
        debugPrint('markAllNotificationsRead API error: $e');
      });
    }
  }

  void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _items[i].read = true;
    notifyListeners();

    if (useBackend) {
      _apiService.markNotificationRead(id).then((_) {}).catchError((Object e) {
        debugPrint('markNotificationRead API error: $e');
      });
    }
  }

  void markAllReadForAdmin() {
    for (final n in _items) {
      if (n.audience == AppRole.admin) n.read = true;
    }
    notifyListeners();

    if (useBackend) {
      _apiService.markAllNotificationsRead().then((_) {}).catchError((Object e) {
        debugPrint('markAllNotificationsRead API error: $e');
      });
    }
  }

  void markAllReadForCustomer(String customerId) {
    for (final n in _items) {
      if (n.audience == AppRole.customer && n.customerId == customerId) {
        n.read = true;
      }
    }
    notifyListeners();

    if (useBackend) {
      _apiService.markAllNotificationsRead().then((_) {}).catchError((Object e) {
        debugPrint('markAllNotificationsRead API error: $e');
      });
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
