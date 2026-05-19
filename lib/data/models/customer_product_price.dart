/// Per-customer price for a catalog variant (cans or bottles).
class CustomerProductPrice {
  const CustomerProductPrice({
    required this.productId,
    required this.variantId,
    required this.unitPrice,
    this.enabled = true,
  });

  final String productId;
  final String variantId;
  final double unitPrice;
  final bool enabled;

  String get key => '$productId|$variantId';

  CustomerProductPrice copyWith({
    String? productId,
    String? variantId,
    double? unitPrice,
    bool? enabled,
  }) {
    return CustomerProductPrice(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      unitPrice: unitPrice ?? this.unitPrice,
      enabled: enabled ?? this.enabled,
    );
  }
}
