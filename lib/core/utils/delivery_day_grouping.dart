import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';

/// One ledger row per calendar day — merges multiple deliveries on the same date.
List<Delivery> groupDeliveriesByDay(List<Delivery> deliveries) {
  if (deliveries.isEmpty) return [];

  final sorted = List<Delivery>.from(deliveries)
    ..sort((a, b) => a.date.compareTo(b.date));

  final buckets = <DateTime, List<Delivery>>{};
  for (final d in sorted) {
    final day = DateTime(d.date.year, d.date.month, d.date.day);
    buckets.putIfAbsent(day, () => []).add(d);
  }

  final days = buckets.keys.toList()..sort();
  return [for (final day in days) _mergeDay(day, buckets[day]!)];
}

Delivery _mergeDay(DateTime day, List<Delivery> group) {
  final merged = <String, DeliveryLineItem>{};

  for (final d in group) {
    for (final line in d.lines) {
      final key = '${line.kind.name}|${line.label}|${line.unitPrice}';
      final existing = merged[key];
      if (existing == null) {
        merged[key] = line;
      } else {
        merged[key] = DeliveryLineItem(
          kind: existing.kind,
          label: existing.label,
          quantity: existing.quantity + line.quantity,
          unitPrice: existing.unitPrice,
          productId: existing.productId,
        );
      }
    }
  }

  return Delivery(
    id: 'day-${day.millisecondsSinceEpoch}',
    customerId: group.first.customerId,
    date: day,
    lines: merged.values.toList(),
    createdAt: group.last.createdAt,
  );
}
