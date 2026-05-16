class Delivery {
  Delivery({
    required this.id,
    required this.customerId,
    required this.date,
    required this.normalQty,
    required this.coolQty,
    required this.normalUnitPrice,
    required this.coolUnitPrice,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String customerId;
  DateTime date;
  int normalQty;
  int coolQty;
  final double normalUnitPrice;
  final double coolUnitPrice;
  final DateTime createdAt;

  double get totalAmount =>
      (normalQty * normalUnitPrice) + (coolQty * coolUnitPrice);

  String get cansSummary {
    final parts = <String>[];
    if (normalQty > 0) parts.add('$normalQty Normal');
    if (coolQty > 0) parts.add('$coolQty Cool');
    return parts.isEmpty ? 'No cans' : parts.join(', ');
  }

  Delivery copyWith({
    DateTime? date,
    int? normalQty,
    int? coolQty,
  }) {
    return Delivery(
      id: id,
      customerId: customerId,
      date: date ?? this.date,
      normalQty: normalQty ?? this.normalQty,
      coolQty: coolQty ?? this.coolQty,
      normalUnitPrice: normalUnitPrice,
      coolUnitPrice: coolUnitPrice,
      createdAt: createdAt,
    );
  }
}
