import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

List<Delivery> seedDeliveries({
  required DateTime now,
  required double normalPrice,
  required double coolPrice,
  required List<Shop> shops,
}) {
  final deliveries = <Delivery>[];
  final thisMonth = DateTime(now.year, now.month);
  final prev1 = DateTime(thisMonth.year, thisMonth.month - 1);
  final prev2 = DateTime(thisMonth.year, thisMonth.month - 2);

  void addCans(
    String customerId,
    int day,
    int normal,
    int cool, {
    int hour = 10,
    String? driverId,
    DateTime? month,
  }) {
    final m = month ?? thisMonth;
    deliveries.add(
      Delivery.fromLegacyCans(
        id: _uuid.v4(),
        customerId: customerId,
        date: DateTime(m.year, m.month, day, hour),
        normalQty: normal,
        coolQty: cool,
        normalUnitPrice: normalPrice,
        coolUnitPrice: coolPrice,
        driverId: driverId,
      ),
    );
  }

  // Current month — core customers
  addCans('c1', 5, 2, 3);
  addCans('c1', 12, 1, 2);
  addCans('c2', 8, 3, 1);
  addCans('c2', 18, 2, 0);
  addCans('c3', 10, 0, 4);
  addCans('c4', 15, 4, 2);
  addCans('c4', 22, 2, 1);

  // Previous months
  addCans('c1', 10, 2, 2, month: prev1);
  addCans('c2', 14, 3, 1, month: prev1);
  addCans('c4', 20, 2, 3, month: prev1);
  addCans('c1', 8, 1, 1, month: prev2);
  addCans('c3', 16, 2, 2, month: prev2);

  // Abi multi-shop deliveries
  final shopPairs = [
    ('c1-shop2', 'shop-2'),
    ('c1-shop3', 'shop-3'),
    ('c1-shop4', 'shop-4'),
  ];
  for (final (customerId, shopId) in shopPairs) {
    Shop? shop;
    try {
      shop = shops.firstWhere((s) => s.id == shopId);
    } catch (_) {
      continue;
    }
    deliveries.addAll([
      Delivery.fromLegacyCans(
        id: _uuid.v4(),
        customerId: customerId,
        date: DateTime(thisMonth.year, thisMonth.month, 3 + customerId.hashCode % 5, 10),
        normalQty: 2,
        coolQty: 1,
        normalUnitPrice: shop.normalPrice,
        coolUnitPrice: shop.coolPrice,
      ),
      Delivery.fromLegacyCans(
        id: _uuid.v4(),
        customerId: customerId,
        date: DateTime(thisMonth.year, thisMonth.month, 10 + customerId.hashCode % 4, 10),
        normalQty: 3,
        coolQty: 2,
        normalUnitPrice: shop.normalPrice,
        coolUnitPrice: shop.coolPrice,
      ),
      Delivery.fromLegacyCans(
        id: _uuid.v4(),
        customerId: customerId,
        date: DateTime(thisMonth.year, thisMonth.month, 18 + customerId.hashCode % 3, 10),
        normalQty: 1,
        coolQty: 0,
        normalUnitPrice: shop.normalPrice,
        coolUnitPrice: shop.coolPrice,
      ),
      Delivery.fromLegacyCans(
        id: _uuid.v4(),
        customerId: customerId,
        date: DateTime(prev1.year, prev1.month, 8, 10),
        normalQty: 4,
        coolQty: 2,
        normalUnitPrice: shop.normalPrice,
        coolUnitPrice: shop.coolPrice,
      ),
      Delivery.fromLegacyCans(
        id: _uuid.v4(),
        customerId: customerId,
        date: DateTime(prev1.year, prev1.month, 20, 10),
        normalQty: 2,
        coolQty: 1,
        normalUnitPrice: shop.normalPrice,
        coolUnitPrice: shop.coolPrice,
      ),
    ]);
  }

  // Driver demo — today delivery for c2
  final today = DateTime(now.year, now.month, now.day, 9, 30);
  deliveries.add(
    Delivery.fromLegacyCans(
      id: _uuid.v4(),
      customerId: 'c2',
      date: today,
      normalQty: 2,
      coolQty: 0,
      normalUnitPrice: normalPrice,
      coolUnitPrice: coolPrice,
      driverId: 'driver-1',
    ),
  );

  return deliveries;
}
