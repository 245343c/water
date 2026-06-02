/// Synthetic product id for 20L can pricing (not in bottle catalog).
abstract final class CustomerPricingKeys {
  static const String canProductId = '__water_cans__';
  static const String normalVariantId = 'normal';
  static const String coolVariantId = 'cool';

  /// Auto / lorry channel pricing (fixed catalog, not bottle products).
  static const String channelProductId = '__delivery_channels__';
  static const String lorryLitersVariantId = 'lorryLiters';
  static const String fullLorryVariantId = 'fullLorry';
  static const String autoLitersVariantId = 'autoLiters';
  static const String autoCansVariantId = 'autoCans';
}
