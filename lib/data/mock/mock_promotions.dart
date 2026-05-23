import 'package:sri_sai_ro_water/data/models/promotion.dart';

List<Promotion> seedPromotions({
  required String shopId,
  required String shopName,
  required DateTime now,
}) => [
  Promotion(
    id: 'promo-1',
    shopId: shopId,
    shopName: shopName,
    headline: 'Summer Special — Free Cool Can!',
    body:
        'Order 10 normal cans this month and get 1 cool can absolutely free. Valid till end of June.',
    mediaType: PromotionMediaType.image,
    badge: 'FREE CAN',
    ctaLabel: 'Claim offer',
    createdAt: now.subtract(const Duration(hours: 2)),
  ),
  Promotion(
    id: 'promo-2',
    shopId: 'shop-2',
    shopName: 'Aqua Pure RO Center',
    headline: 'New Customer Offer',
    body:
        'First-time customers get 2 cans free on their first order. Use code AQUAFIRST at checkout.',
    mediaType: PromotionMediaType.image,
    badge: 'NEW',
    ctaLabel: 'Order now',
    createdAt: now.subtract(const Duration(hours: 5)),
  ),
  Promotion(
    id: 'promo-3',
    shopId: 'shop-4',
    shopName: 'Crystal Clear Water Co.',
    headline: 'ISO Certified — Best Quality',
    body:
        'TDS level tested daily. Our water meets the highest purity standards. Monthly plans starting \u20b9180.',
    mediaType: PromotionMediaType.video,
    badge: 'QUALITY',
    ctaLabel: 'View plans',
    createdAt: now.subtract(const Duration(days: 1)),
  ),
  Promotion(
    id: 'promo-4',
    shopId: 'shop-3',
    shopName: 'Blue Drop Water Plant',
    headline: 'Same-Day Delivery',
    body:
        'Order before 12 PM and get delivery by 6 PM. No extra charge. Available in all areas.',
    mediaType: PromotionMediaType.image,
    badge: 'FAST',
    ctaLabel: 'Order now',
    createdAt: now.subtract(const Duration(days: 1, hours: 3)),
  ),
  Promotion(
    id: 'promo-5',
    shopId: 'shop-5',
    shopName: 'Neer Amrit Water Plant',
    headline: 'Monthly Plan — Save 15%',
    body:
        'Subscribe to our monthly plan and save up to 15% compared to per-can pricing. Min 20 cans/month.',
    mediaType: PromotionMediaType.image,
    badge: 'SAVE 15%',
    ctaLabel: 'Subscribe',
    createdAt: now.subtract(const Duration(days: 2)),
  ),
];
