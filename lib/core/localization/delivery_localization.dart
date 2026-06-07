import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/order_line_item.dart';

extension DeliveryStrings on AppStrings {
  String deliveryProductTitle(DeliveryProductType type) {
    return switch (type) {
      DeliveryProductType.normalCan => normalCan,
      DeliveryProductType.coolCan => coolCan,
      DeliveryProductType.lorryLiters => lorryInLiters,
      DeliveryProductType.fullLorry => fullLorry,
      DeliveryProductType.autoLiters => autoInLiters,
      DeliveryProductType.autoCans => autoCans,
    };
  }

  String deliveryProductSubtitle(DeliveryProductType type) {
    return switch (type) {
      DeliveryProductType.normalCan => twentyLitre,
      DeliveryProductType.coolCan => twentyLitre,
      DeliveryProductType.lorryLiters => litreRange1000To5000,
      DeliveryProductType.fullLorry => fullLoad,
      DeliveryProductType.autoLiters => litreRange20To200,
      DeliveryProductType.autoCans => cansRange2To10,
    };
  }

  String orderLineLabel(OrderLineItem item) {
    final type = item.deliveryType;
    if (type == null) return item.label;
    return deliveryProductTitle(type);
  }

  String deliveryLineLabel(DeliveryLineItem item) {
    final type = item.productId == null || item.variantId == null
        ? null
        : DeliveryProductType.fromPricingKey(
            productId: item.productId!,
            variantId: item.variantId!,
          );
    if (type != null) return deliveryProductTitle(type);
    return switch (item.kind) {
      DeliveryItemKind.normalCan => normalCan,
      DeliveryItemKind.coolCan => coolCan,
      DeliveryItemKind.bottle => item.label,
    };
  }

  String orderItemsSummary(CustomerOrder order) {
    if (order.lineItems.isNotEmpty) {
      final parts = order.lineItems
          .where((line) => line.quantity > 0)
          .map((line) => '${line.quantity} ${orderLineLabel(line)}')
          .toList();
      return parts.isEmpty ? noCans : parts.join(' - ');
    }

    final parts = <String>[];
    if (order.normalQty > 0) parts.add('${order.normalQty} $normal');
    if (order.coolQty > 0) parts.add('${order.coolQty} $cool');
    return parts.isEmpty ? noCans : parts.join(' - ');
  }

  String deliveryItemsSummary(Delivery delivery) {
    if (delivery.isEmptyReturnOnly) {
      final parts = <String>[];
      if (delivery.emptyNormalReturned > 0) {
        parts.add('${delivery.emptyNormalReturned} $emptyNormal');
      }
      if (delivery.emptyCoolReturned > 0) {
        parts.add('${delivery.emptyCoolReturned} $emptyCool');
      }
      return emptyReturnWithDetails(parts.join(', '));
    }
    if (delivery.lines.isEmpty) return noItems;
    return delivery.lines
        .map((line) => '${line.quantity} ${deliveryLineLabel(line)}')
        .join(', ');
  }
}
