import 'package:sri_sai_ro_water/data/models/order_status.dart';

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.customerId,
    required this.normalQty,
    required this.coolQty,
    required this.status,
    this.shopId,
    this.placedByAppUserId,
    this.customerNote,
    this.adminResponse,
    DateTime? createdAt,
    this.respondedAt,
    this.driverAcceptedAt,
    this.deliveryStartedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String customerId;
  final String? shopId;
  final String? placedByAppUserId;
  int normalQty;
  int coolQty;
  OrderStatus status;
  String? customerNote;
  String? adminResponse;
  final DateTime createdAt;
  DateTime? respondedAt;
  DateTime? driverAcceptedAt;
  DateTime? deliveryStartedAt;

  int get totalCans => normalQty + coolQty;

  String get cansSummary {
    final parts = <String>[];
    if (normalQty > 0) parts.add('$normalQty Normal');
    if (coolQty > 0) parts.add('$coolQty Cool');
    return parts.isEmpty ? 'No cans' : parts.join(' · ');
  }

  bool get isPending => status == OrderStatus.pending;

  bool get canCustomerEdit => status == OrderStatus.pending;

  bool get canCustomerCancel => status == OrderStatus.pending;

  bool get isDriverAssigned => driverAcceptedAt != null;

  bool get isOutForDelivery => deliveryStartedAt != null;
}
