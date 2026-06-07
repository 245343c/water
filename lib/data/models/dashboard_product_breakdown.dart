import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';

class DashboardProductBreakdown {
  const DashboardProductBreakdown({
    required this.label,
    required this.quantity,
    required this.unit,
    required this.amount,
  });

  final String label;
  final int quantity;
  final DeliveryQuantityUnit unit;
  final double amount;

  String get quantityLabel {
    return switch (unit) {
      DeliveryQuantityUnit.liter => '$quantity L',
      DeliveryQuantityUnit.load => quantity == 1 ? '1 load' : '$quantity loads',
      DeliveryQuantityUnit.can => quantity == 1 ? '1 can' : '$quantity cans',
      DeliveryQuantityUnit.unit => quantity == 1 ? '1 unit' : '$quantity units',
    };
  }
}
