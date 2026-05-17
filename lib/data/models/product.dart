import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/models/product_variant.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.variants,
    this.isActive = true,
    this.localImagePath,
  });

  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final List<ProductVariant> variants;
  final bool isActive;
  final String? localImagePath;

  bool get hasPhoto => localImagePath != null && localImagePath!.isNotEmpty;

  Product copyWith({
    String? name,
    String? description,
    ProductCategory? category,
    List<ProductVariant>? variants,
    bool? isActive,
    String? localImagePath,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      variants: variants ?? this.variants,
      isActive: isActive ?? this.isActive,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }

  double get startingPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  String get variantSummary {
    if (category == ProductCategory.can) {
      return 'Normal & Cool';
    }
    if (variants.length <= 3) {
      return variants.map((v) => v.label).join(' · ');
    }
    return '${variants.first.label} – ${variants.last.label}';
  }
}
