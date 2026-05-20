enum PromotionMediaType { image, video }

class Promotion {
  const Promotion({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.headline,
    required this.body,
    required this.mediaType,
    this.mediaUrl,
    this.thumbUrl,
    this.badge,
    this.ctaLabel = 'Order now',
    required this.createdAt,
  });

  final String id;
  final String shopId;
  final String shopName;
  final String headline;
  final String body;
  final PromotionMediaType mediaType;
  final String? mediaUrl;
  final String? thumbUrl;
  final String? badge;
  final String ctaLabel;
  final DateTime createdAt;
}
