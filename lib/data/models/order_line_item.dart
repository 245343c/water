import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';

/// One product line on a dispatch request.
class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.variantId,
    required this.label,
    required this.quantity,
  });

  final String productId;
  final String variantId;
  final String label;
  final int quantity;

  DeliveryProductType? get deliveryType => DeliveryProductType.fromPricingKey(
        productId: productId,
        variantId: variantId,
      );

  factory OrderLineItem.fromDeliveryType({
    required DeliveryProductType type,
    required int quantity,
  }) {
    return OrderLineItem(
      productId: type.productId,
      variantId: type.variantId,
      label: type.title,
      quantity: quantity,
    );
  }

  factory OrderLineItem.fromMap(Map<String, dynamic> data) {
    return OrderLineItem(
      productId: data['productId'] as String? ?? CustomerPricingKeys.canProductId,
      variantId: data['variantId'] as String? ?? CustomerPricingKeys.normalVariantId,
      label: data['label'] as String? ?? 'Item',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'variantId': variantId,
        'label': label,
        'quantity': quantity,
      };

  bool get isNormalCan =>
      productId == CustomerPricingKeys.canProductId &&
      variantId == CustomerPricingKeys.normalVariantId;

  bool get isCoolCan =>
      productId == CustomerPricingKeys.canProductId &&
      variantId == CustomerPricingKeys.coolVariantId;
}
