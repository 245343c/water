import 'package:sri_sai_ro_water/core/auth/app_role.dart';

enum AppNotificationType {
  deliveryRecorded,
  orderAccepted,
  orderRejected,
  orderPlaced,
  paymentReceived,
}

/// In-app + push notification payload (mock until backend FCM).
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.audience,
    required this.createdAt,
    this.customerId,
    this.deliveryId,
    this.orderId,
    this.driverId,
    this.driverName,
    this.read = false,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final AppRole audience;
  final String? customerId;
  final String? deliveryId;
  final String? orderId;
  final String? driverId;
  final String? driverName;
  final DateTime createdAt;
  bool read;
}
