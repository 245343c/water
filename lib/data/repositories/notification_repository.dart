import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/app_notification.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:uuid/uuid.dart';

class NotificationRepository extends ChangeNotifier {
  static const _uuid = Uuid();
  final List<AppNotification> _items = [];
  final Set<String> _remoteAdminIds = {};
  final Set<String> _remoteDriverIds = {};
  final Map<String, Set<String>> _remoteCustomerIdsByCustomer = {};
  final Map<String, DocumentReference<Map<String, dynamic>>>
      _remoteNotificationRefs = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _subscriptions = [];

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

  Future<void> syncForUser(
    AppUser? user,
    WaterPlantRepository plant,
  ) async {
    await _cancelSubscriptions();
    _remoteAdminIds.clear();
    _remoteDriverIds.clear();
    _remoteCustomerIdsByCustomer.clear();
    _remoteNotificationRefs.clear();

    if (user == null) {
      clear();
      return;
    }

    if (user.role == AppRole.admin) {
      final shopId = await plant.firebaseShopIdForCurrentUser();
      if (shopId == null) return;
      final sub = FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('notifications')
          .where('audience', isEqualTo: 'admin')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) => _applyAdminSnapshot(snapshot));
      _subscriptions.add(sub);
      return;
    }

    if (user.role == AppRole.customer) {
      for (final customer in plant.linkedCrmCustomersForAppUser(
        user.id,
        phone: user.phone,
      )) {
        final shopId = plant.shopIdForCustomer(customer.id);
        final sub = FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('notifications')
            .where('audience', isEqualTo: 'customer')
            .where('customerId', isEqualTo: customer.id)
            .limit(100)
            .snapshots()
            .listen((snapshot) => _applyCustomerSnapshot(customer.id, snapshot));
        _subscriptions.add(sub);
      }
      return;
    }

    if (user.role == AppRole.driver && user.driverId != null) {
      final shop = plant.shopForDriver(user.driverId);
      if (shop == null) return;
      final sub = FirebaseFirestore.instance
          .collection('shops')
          .doc(shop.id)
          .collection('notifications')
          .where('audience', isEqualTo: 'driver')
          .limit(100)
          .snapshots()
          .listen(_applyDriverSnapshot);
      _subscriptions.add(sub);
    }
  }

  void _applyAdminSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _items.removeWhere(
      (n) => n.audience == AppRole.admin && _remoteAdminIds.contains(n.id),
    );
    _remoteAdminIds
      ..clear()
      ..addAll(snapshot.docs.map((doc) => doc.id));

    for (final doc in snapshot.docs) {
      final notification = _notificationFromFirestore(doc);
      if (notification == null) continue;
      if (_hasDeliveryNotification(
        notification.deliveryId,
        AppRole.admin,
      )) {
        continue;
      }
      _upsertNotification(notification);
    }
    notifyListeners();
  }

  void _applyCustomerSnapshot(
    String customerId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final remoteIds =
        _remoteCustomerIdsByCustomer.putIfAbsent(customerId, () => {});
    _items.removeWhere(
      (n) =>
          n.audience == AppRole.customer &&
          n.customerId == customerId &&
          remoteIds.contains(n.id),
    );
    remoteIds
      ..clear()
      ..addAll(snapshot.docs.map((doc) => doc.id));

    for (final doc in snapshot.docs) {
      final notification = _notificationFromFirestore(doc);
      if (notification == null) continue;
      if (_hasDeliveryNotification(
        notification.deliveryId,
        AppRole.customer,
      )) {
        continue;
      }
      _upsertNotification(notification);
    }
    notifyListeners();
  }

  void _applyDriverSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _items.removeWhere(
      (n) => n.audience == AppRole.driver && _remoteDriverIds.contains(n.id),
    );
    _remoteDriverIds
      ..clear()
      ..addAll(snapshot.docs.map((doc) => doc.id));

    for (final doc in snapshot.docs) {
      final notification = _notificationFromFirestore(doc);
      if (notification != null) _upsertNotification(notification);
    }
    notifyListeners();
  }

  void _upsertNotification(AppNotification notification) {
    final index = _items.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      _items[index] = notification;
    } else {
      _items.insert(0, notification);
    }
  }

  bool _hasDeliveryNotification(String? deliveryId, AppRole audience) {
    if (deliveryId == null) return false;
    return _items.any(
      (n) =>
          n.deliveryId == deliveryId &&
          n.audience == audience &&
          n.type == AppNotificationType.deliveryRecorded,
    );
  }

  AppNotification? _notificationFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    _remoteNotificationRefs[doc.id] = doc.reference;
    return AppNotification(
      id: doc.id,
      type: _notificationTypeFromString(data['type'] as String?),
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      audience: _audienceFromString(data['audience'] as String?),
      customerId: data['customerId'] as String?,
      deliveryId: data['deliveryId'] as String?,
      orderId: data['orderId'] as String?,
      driverId: data['driverId'] as String?,
      driverName: data['driverName'] as String?,
      read: data['read'] as bool? ?? false,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  AppNotificationType _notificationTypeFromString(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AppNotificationType.deliveryRecorded,
    );
  }

  AppRole _audienceFromString(String? value) {
    return AppRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppRole.admin,
    );
  }

  Future<void> _cancelSubscriptions() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  void markAllReadForDriver() {
    final ids = <String>[];
    for (final n in _items) {
      if (n.audience == AppRole.driver) {
        n.read = true;
        ids.add(n.id);
      }
    }
    _persistRead(ids);
    notifyListeners();
  }

  void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _items[i].read = true;
    _persistRead([id]);
    notifyListeners();
  }

  void markAllReadForAdmin() {
    final ids = <String>[];
    for (final n in _items) {
      if (n.audience == AppRole.admin) {
        n.read = true;
        ids.add(n.id);
      }
    }
    _persistRead(ids);
    notifyListeners();
  }

  void markAllReadForCustomer(String customerId) {
    final ids = <String>[];
    for (final n in _items) {
      if (n.audience == AppRole.customer && n.customerId == customerId) {
        n.read = true;
        ids.add(n.id);
      }
    }
    _persistRead(ids);
    notifyListeners();
  }

  void _persistRead(Iterable<String> ids) {
    final refs = ids
        .map((id) => _remoteNotificationRefs[id])
        .whereType<DocumentReference<Map<String, dynamic>>>()
        .toList();
    if (refs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final ref in refs) {
      batch.set(
        ref,
        {
          'read': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    unawaited(batch.commit());
  }

  void recordDelivery({
    required Delivery delivery,
    required Customer customer,
    required String driverName,
    String? driverId,
  }) {
    if (_hasDeliveryNotification(delivery.id, AppRole.admin) &&
        _hasDeliveryNotification(delivery.id, AppRole.customer)) {
      return;
    }

    final summary = delivery.cansSummary;
    final amount = delivery.totalAmount;

    if (!_hasDeliveryNotification(delivery.id, AppRole.admin)) {
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
    }

    if (!_hasDeliveryNotification(delivery.id, AppRole.customer)) {
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
    }

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

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
