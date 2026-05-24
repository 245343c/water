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
    this.routeNote = '',
    this.paymentFrequency = 'Monthly',
    this.productPrices = const [],
    this.billingMode = CustomerBillingMode.monthlyContract,
    this.status = 'active',
    this.appUserId,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String phone;
  String address;
  String email;
  String place;
  String? routeId;
  String routeNote;
  String paymentFrequency;
  final List<CustomerProductPrice> productPrices;
  final CustomerBillingMode billingMode;
  String status;
  final String? appUserId;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  bool get isMonthlyContract =>
      billingMode == CustomerBillingMode.monthlyContract;

  bool get isBlocked => status == 'blocked';
  bool get isDeleted => status == 'deleted';

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
    String? routeNote,
    String? paymentFrequency,
    List<CustomerProductPrice>? productPrices,
    CustomerBillingMode? billingMode,
    String? status,
    String? appUserId,
    double? latitude,
    double? longitude,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      place: place ?? this.place,
      routeId: clearRoute ? null : routeId ?? this.routeId,
      routeNote: routeNote ?? this.routeNote,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      productPrices: productPrices ?? this.productPrices,
      billingMode: billingMode ?? this.billingMode,
      status: status ?? this.status,
      appUserId: appUserId ?? this.appUserId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
