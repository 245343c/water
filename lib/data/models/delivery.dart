import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';

class Delivery {
  Delivery({
    required this.id,
    required this.customerId,
    required this.date,
    required this.lines,
    this.emptyNormalReturned = 0,
    this.emptyCoolReturned = 0,
    this.driverId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String customerId;
  DateTime date;
  final List<DeliveryLineItem> lines;
  final int emptyNormalReturned;
  final int emptyCoolReturned;

  /// Staff who recorded this delivery (driver or admin user id).
  final String? driverId;
  final DateTime createdAt;

  /// Legacy mock / can-only deliveries.
  factory Delivery.fromLegacyCans({
    required String id,
    required String customerId,
    required DateTime date,
    required int normalQty,
    required int coolQty,
    required double normalUnitPrice,
    required double coolUnitPrice,
    String? driverId,
    DateTime? createdAt,
  }) {
    final lines = <DeliveryLineItem>[];
    if (normalQty > 0) {
      lines.add(
        DeliveryLineItem(
          kind: DeliveryItemKind.normalCan,
          label: 'Normal Can',
          quantity: normalQty,
          unitPrice: normalUnitPrice,
        ),
      );
    }
    if (coolQty > 0) {
      lines.add(
        DeliveryLineItem(
          kind: DeliveryItemKind.coolCan,
          label: 'Cool Can',
          quantity: coolQty,
          unitPrice: coolUnitPrice,
        ),
      );
    }
    return Delivery(
      id: id,
      customerId: customerId,
      date: date,
      lines: lines,
      emptyNormalReturned: 0,
      emptyCoolReturned: 0,
      driverId: driverId,
      createdAt: createdAt,
    );
  }

  int get normalQty => _sumKind(DeliveryItemKind.normalCan);

  int get coolQty => _sumKind(DeliveryItemKind.coolCan);

  int get bottleQty => _sumKind(DeliveryItemKind.bottle);

  int _sumKind(DeliveryItemKind kind) =>
      lines.where((l) => l.kind == kind).fold(0, (s, l) => s + l.quantity);

  double get totalAmount => lines.fold<double>(0, (s, l) => s + l.lineTotal);

  bool get isEmptyReturnOnly => lines.isEmpty && totalEmptyReturned > 0;

  String get itemsSummary {
    if (isEmptyReturnOnly) {
      final parts = <String>[];
      if (emptyNormalReturned > 0) {
        parts.add('$emptyNormalReturned empty normal');
      }
      if (emptyCoolReturned > 0) {
        parts.add('$emptyCoolReturned empty cool');
      }
      return 'Empty return (${parts.join(', ')})';
    }
    if (lines.isEmpty) return 'No items';
    return lines.map((l) => '${l.quantity} ${l.label}').join(', ');
  }

  /// Backward-compatible alias.
  String get cansSummary => itemsSummary;

  int get totalEmptyReturned => emptyNormalReturned + emptyCoolReturned;

  /// Official monthly bill — description column.
  String get billTableDescription {
    final bottles = lines.where((l) => l.kind == DeliveryItemKind.bottle).toList();
    if (bottles.isEmpty) return 'Delivery';
    final detail = bottles.map((l) => '${l.quantity}×${l.label}').join(', ');
    return 'Delivery ($detail)';
  }

  Delivery copyWith({
    DateTime? date,
    List<DeliveryLineItem>? lines,
    int? emptyNormalReturned,
    int? emptyCoolReturned,
  }) {
    return Delivery(
      id: id,
      customerId: customerId,
      date: date ?? this.date,
      lines: lines ?? this.lines,
      emptyNormalReturned: emptyNormalReturned ?? this.emptyNormalReturned,
      emptyCoolReturned: emptyCoolReturned ?? this.emptyCoolReturned,
      driverId: driverId,
      createdAt: createdAt,
    );
  }
}
