class BusinessSettings {
  BusinessSettings({
    required this.businessName,
    required this.address,
    required this.phone,
    required this.normalPrice,
    required this.coolPrice,
    this.email = '',
  });

  String businessName;
  String address;
  String phone;
  String email;
  double normalPrice;
  double coolPrice;

  BusinessSettings copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? email,
    double? normalPrice,
    double? coolPrice,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      normalPrice: normalPrice ?? this.normalPrice,
      coolPrice: coolPrice ?? this.coolPrice,
    );
  }
}
