class BusinessSettings {
  BusinessSettings({
    required this.businessName,
    required this.address,
    required this.phone,
    required this.normalPrice,
    required this.coolPrice,
    this.lorryLiterPrice = 0,
    this.fullLorryPrice = 0,
    this.autoLiterPrice = 0,
    this.autoCanPrice = 0,
    this.email = '',
    this.shopLatitude,
    this.shopLongitude,
    this.homeDeliveryAvailable = false,
  });

  String businessName;
  String address;
  String phone;
  String email;
  double normalPrice;
  double coolPrice;
  double lorryLiterPrice;
  double fullLorryPrice;
  double autoLiterPrice;
  double autoCanPrice;
  /// Pin on map (optional — uses address search if null).
  double? shopLatitude;
  double? shopLongitude;

  /// When true, shop appears in customer app for home delivery orders.
  bool homeDeliveryAvailable;

  bool get hasMapPin => shopLatitude != null && shopLongitude != null;

  BusinessSettings copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? email,
    double? normalPrice,
    double? coolPrice,
    double? lorryLiterPrice,
    double? fullLorryPrice,
    double? autoLiterPrice,
    double? autoCanPrice,
    double? shopLatitude,
    double? shopLongitude,
    bool? homeDeliveryAvailable,
    bool clearMapPin = false,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      normalPrice: normalPrice ?? this.normalPrice,
      coolPrice: coolPrice ?? this.coolPrice,
      lorryLiterPrice: lorryLiterPrice ?? this.lorryLiterPrice,
      fullLorryPrice: fullLorryPrice ?? this.fullLorryPrice,
      autoLiterPrice: autoLiterPrice ?? this.autoLiterPrice,
      autoCanPrice: autoCanPrice ?? this.autoCanPrice,
      shopLatitude: clearMapPin ? null : (shopLatitude ?? this.shopLatitude),
      shopLongitude: clearMapPin ? null : (shopLongitude ?? this.shopLongitude),
      homeDeliveryAvailable:
          homeDeliveryAvailable ?? this.homeDeliveryAvailable,
    );
  }
}
