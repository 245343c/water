class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.label,
    required this.price,
    this.isCool = false,
  });

  final String id;
  final String label;
  final double price;
  final bool isCool;
}
