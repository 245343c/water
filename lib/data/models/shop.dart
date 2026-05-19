import 'package:sri_sai_ro_water/data/models/business_settings.dart';

enum ShopSubscriptionStatus {
  trial,
  active,
  grace,
  expired,
}

/// Water shop on the platform (multi-tenant ready; mock uses one shop).
class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.email = '',
    this.place = '',
    this.latitude,
    this.longitude,
    this.subscriptionStatus = ShopSubscriptionStatus.trial,
    this.trialEndsAt,
    this.isListed = true,
    this.homeDeliveryAvailable = false,
    this.normalPrice = 20,
    this.coolPrice = 30,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String place;
  final double? latitude;
  final double? longitude;
  final ShopSubscriptionStatus subscriptionStatus;
  final DateTime? trialEndsAt;
  final bool isListed;
  final bool homeDeliveryAvailable;
  final double normalPrice;
  final double coolPrice;

  bool get isVisibleToCustomers {
    if (!isListed || !homeDeliveryAvailable) return false;
    return switch (subscriptionStatus) {
      ShopSubscriptionStatus.trial => true,
      ShopSubscriptionStatus.active => true,
      ShopSubscriptionStatus.grace => true,
      ShopSubscriptionStatus.expired => false,
    };
  }

  bool get hasMapPin => latitude != null && longitude != null;

  static Shop fromBusinessSettings(BusinessSettings s, {required String id}) {
    return Shop(
      id: id,
      name: s.businessName,
      address: s.address,
      phone: s.phone,
      email: s.email,
      latitude: s.shopLatitude,
      longitude: s.shopLongitude,
      subscriptionStatus: ShopSubscriptionStatus.active,
      homeDeliveryAvailable: s.homeDeliveryAvailable,
      normalPrice: s.normalPrice,
      coolPrice: s.coolPrice,
    );
  }
}
