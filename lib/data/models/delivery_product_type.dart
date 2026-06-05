import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';

/// Fixed delivery catalog types — always shown on Products; toggled per customer.
enum DeliveryProductType {
  normalCan(
    title: 'Normal Can',
    subtitle: '20 Litre',
    icon: Icons.water_drop_outlined,
    rateLabel: 'per can',
  ),
  coolCan(
    title: 'Cool Can',
    subtitle: '20 Litre',
    icon: Icons.ac_unit_rounded,
    rateLabel: 'per can',
  ),
  lorryLiters(
    title: 'Lorry in Liters',
    subtitle: '1000 – 5000 Litre',
    icon: Icons.local_shipping_outlined,
    rateLabel: 'per litre',
  ),
  fullLorry(
    title: 'Full Lorry',
    subtitle: 'Full Load',
    icon: Icons.fire_truck_outlined,
    rateLabel: 'per load',
  ),
  autoLiters(
    title: 'Auto in Liters',
    subtitle: '20 – 200 Litre',
    icon: Icons.electric_rickshaw_outlined,
    rateLabel: 'per litre',
  ),
  autoCans(
    title: 'Auto Cans',
    subtitle: '2 – 10 Cans',
    icon: Icons.electric_rickshaw,
    rateLabel: 'per can',
  );

  const DeliveryProductType({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rateLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String rateLabel;

  static const List<DeliveryProductType> catalog = values;

  String get productId => switch (this) {
        DeliveryProductType.normalCan ||
        DeliveryProductType.coolCan =>
          CustomerPricingKeys.canProductId,
        _ => CustomerPricingKeys.channelProductId,
      };

  String get variantId => switch (this) {
        DeliveryProductType.normalCan => CustomerPricingKeys.normalVariantId,
        DeliveryProductType.coolCan => CustomerPricingKeys.coolVariantId,
        DeliveryProductType.lorryLiters =>
          CustomerPricingKeys.lorryLitersVariantId,
        DeliveryProductType.fullLorry => CustomerPricingKeys.fullLorryVariantId,
        DeliveryProductType.autoLiters =>
          CustomerPricingKeys.autoLitersVariantId,
        DeliveryProductType.autoCans => CustomerPricingKeys.autoCansVariantId,
      };

  String get pricingKey => '$productId|$variantId';

  /// Quantity is litres (keyboard entry), not count via (+/−).
  bool get quantityIsVolumeLiters =>
      this == DeliveryProductType.lorryLiters ||
      this == DeliveryProductType.autoLiters;

  static DeliveryProductType? fromPricingKey({
    required String productId,
    required String variantId,
  }) {
    for (final type in values) {
      if (type.productId == productId && type.variantId == variantId) {
        return type;
      }
    }
    return null;
  }
}
