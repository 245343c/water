import 'package:sri_sai_ro_water/data/models/order_status.dart';

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.customerId,
    required this.normalQty,
    required this.coolQty,
    required this.status,
    this.customerNote,
    this.adminResponse,
    DateTime? createdAt,
    this.respondedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String customerId;
  final int normalQty;
  final int coolQty;
  OrderStatus status;
  final String? customerNote;
  String? adminResponse;
  final DateTime createdAt;
  DateTime? respondedAt;

  int get totalCans => normalQty + coolQty;

  String get cansSummary {
    final parts = <String>[];
    if (normalQty > 0) parts.add('$normalQty Normal');
    if (coolQty > 0) parts.add('$coolQty Cool');
    return parts.isEmpty ? 'No cans' : parts.join(' · ');
  }

  bool get isPending => status == OrderStatus.pending;
}
