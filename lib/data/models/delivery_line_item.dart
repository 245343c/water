enum DeliveryItemKind {
  normalCan,
  coolCan,
  bottle,
}

class DeliveryLineItem {
  const DeliveryLineItem({
    required this.kind,
    required this.label,
    required this.quantity,
    required this.unitPrice,
    this.productId,
  });

  final DeliveryItemKind kind;
  final String label;
  final int quantity;
  final double unitPrice;
  final String? productId;

  double get lineTotal => quantity * unitPrice;
}

/// Bottle line when recording a delivery from the product catalog.
class BottleDeliveryInput {
  const BottleDeliveryInput({
    required this.label,
    required this.quantity,
    required this.unitPrice,
    this.productId,
  });

  final String label;
  final int quantity;
  final double unitPrice;
  final String? productId;
}
