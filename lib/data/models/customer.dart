import 'package:sri_sai_ro_water/data/models/customer_billing_mode.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';

class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email = '',
    this.place = '',
    this.routeId,
    this.paymentFrequency = 'Monthly',
    this.productPrices = const [],
    this.billingMode = CustomerBillingMode.monthlyContract,
    this.appUserId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String phone;
  String address;
  String email;
  String place;
  String? routeId;
  String paymentFrequency;
  final List<CustomerProductPrice> productPrices;
  final CustomerBillingMode billingMode;
  final String? appUserId;
  final DateTime createdAt;

  bool get isMonthlyContract =>
      billingMode == CustomerBillingMode.monthlyContract;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    String? email,
    String? place,
    String? routeId,
    bool clearRoute = false,
    String? paymentFrequency,
    List<CustomerProductPrice>? productPrices,
    CustomerBillingMode? billingMode,
    String? appUserId,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      place: place ?? this.place,
      routeId: clearRoute ? null : routeId ?? this.routeId,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      productPrices: productPrices ?? this.productPrices,
      billingMode: billingMode ?? this.billingMode,
      appUserId: appUserId ?? this.appUserId,
      createdAt: createdAt,
    );
  }

  CustomerProductPrice? priceEntry(String productId, String variantId) {
    final key = '$productId|$variantId';
    for (final p in productPrices) {
      if (p.key == key) return p;
    }
    return null;
  }
}
