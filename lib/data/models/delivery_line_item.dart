import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';

enum DeliveryItemKind { normalCan, coolCan, bottle }

enum DeliveryQuantityUnit { can, liter, load, unit }

class DeliveryLineItem {
  const DeliveryLineItem({
    required this.kind,
    required this.label,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.variantId,
  });

  final DeliveryItemKind kind;
  final String label;
  final int quantity;
  final double unitPrice;
  final String? productId;
  final String? variantId;

  double get lineTotal => quantity * unitPrice;

  DeliveryProductType? get deliveryType {
    if (productId == null || variantId == null) return null;
    return DeliveryProductType.fromPricingKey(
      productId: productId!,
      variantId: variantId!,
    );
  }

  DeliveryQuantityUnit get quantityUnit {
    final type = deliveryType;
    if (type == DeliveryProductType.lorryLiters ||
        type == DeliveryProductType.autoLiters) {
      return DeliveryQuantityUnit.liter;
    }
    if (type == DeliveryProductType.fullLorry) {
      return DeliveryQuantityUnit.load;
    }
    if (kind == DeliveryItemKind.normalCan ||
        kind == DeliveryItemKind.coolCan ||
        type == DeliveryProductType.normalCan ||
        type == DeliveryProductType.coolCan ||
        type == DeliveryProductType.autoCans) {
      return DeliveryQuantityUnit.can;
    }
    return DeliveryQuantityUnit.unit;
  }
}

/// Bottle line when recording a delivery from the product catalog.
class BottleDeliveryInput {
  const BottleDeliveryInput({
    required this.label,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.variantId,
  });

  final String label;
  final int quantity;
  final double unitPrice;
  final String? productId;
  final String? variantId;
}
