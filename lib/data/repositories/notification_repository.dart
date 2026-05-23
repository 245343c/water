import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/core/services/api/api_config.dart';
import 'package:sri_sai_ro_water/core/services/api/api_data_service.dart';
import 'package:sri_sai_ro_water/core/services/api/api_client.dart';
import 'package:sri_sai_ro_water/data/models/app_notification.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:uuid/uuid.dart';

class NotificationRepository extends ChangeNotifier {
  static const _uuid = Uuid();
  final List<AppNotification> _items = [];
  late final ApiDataService _apiService = ApiDataService(ApiClient.instance);

  /// Fetch notifications from backend (called when useBackend = true).
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
  }

  void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _items[i].read = true;
    notifyListeners();

    if (useBackend) {
      _apiService.markNotificationRead(id)
          .then((_) {}).catchError((Object e) { debugPrint('markNotificationRead API error: $e'); });
    }
  }

  void markAllReadForAdmin() {
    for (final n in _items) {
      if (n.audience == AppRole.admin) n.read = true;
    }
    notifyListeners();
  }

  void markAllReadForCustomer(String customerId) {
    for (final n in _items) {
      if (n.audience == AppRole.customer && n.customerId == customerId) {
        n.read = true;
      }
    }
    notifyListeners();
  }

  void recordDelivery({
    required Delivery delivery,
    required Customer customer,
    required String driverName,
    String? driverId,
  }) {
    final summary = delivery.cansSummary;
    final amount = delivery.totalAmount;

    _items.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: AppNotificationType.deliveryRecorded,
        title: 'Delivery recorded',
        body:
            '$driverName delivered $summary to ${customer.name}. Bill ₹${amount.toStringAsFixed(0)} updated.',
        audience: AppRole.admin,
        customerId: customer.id,
        deliveryId: delivery.id,
        driverId: driverId,
        driverName: driverName,
        createdAt: DateTime.now(),
      ),
    );

    _items.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: AppNotificationType.deliveryRecorded,
        title: 'Water delivered today',
        body:
            '$summary delivered to your address. Amount ₹${amount.toStringAsFixed(0)} added to your account.',
        audience: AppRole.customer,
        customerId: customer.id,
        deliveryId: delivery.id,
        driverId: driverId,
        driverName: driverName,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void notifyAdminOrderPlaced({
    required CustomerOrder order,
    required String customerName,
    required String shopName,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: AppNotificationType.orderPlaced,
        title: 'New water request',
        body:
            '$customerName requested ${order.cansSummary} from $shopName. Accept or decline from Orders.',
        audience: AppRole.admin,
        customerId: order.customerId,
        orderId: order.id,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void notifyDriverOrderAccepted({
    required CustomerOrder order,
    required String customerName,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: AppNotificationType.orderAccepted,
        title: 'Go deliver — $customerName',
        body:
            'Admin confirmed: ${order.cansSummary}. Ask customer & record actual cans delivered.',
        audience: AppRole.driver,
        customerId: order.customerId,
        orderId: order.id,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void notifyAdminOrderAccepted({
    required CustomerOrder order,
    required String customerName,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: AppNotificationType.orderAccepted,
        title: 'Order sent to driver',
        body: '$customerName · ${order.cansSummary} — driver notified',
        audience: AppRole.admin,
        customerId: order.customerId,
        orderId: order.id,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void notifyCustomerOrderAccepted({
    required CustomerOrder order,
    required String shopName,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: AppNotificationType.orderAccepted,
        title: 'Request accepted',
        body:
            '$shopName confirmed ${order.cansSummary}. Driver will deliver soon.',
        audience: AppRole.customer,
        customerId: order.customerId,
        orderId: order.id,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void notifyCustomerOrderRejected({
    required CustomerOrder order,
    required String shopName,
    required String reason,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: AppNotificationType.orderRejected,
        title: 'Request declined',
        body: '$shopName declined your request. Reason: $reason',
        audience: AppRole.customer,
        customerId: order.customerId,
        orderId: order.id,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
