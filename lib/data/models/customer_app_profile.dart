/// End-user profile for customer app (separate from admin CRM [Customer]).
class CustomerAppProfile {
  const CustomerAppProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.email = '',
    this.place = '',
    this.linkedCrmCustomerId,
    this.onboardingComplete = false,
  });

  final String userId;
  final String name;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String email;
  final String place;

  /// Links to [Customer.id] in shop CRM when order is placed.
  final String? linkedCrmCustomerId;
  final bool onboardingComplete;

  CustomerAppProfile copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? email,
    String? place,
    String? linkedCrmCustomerId,
    bool? onboardingComplete,
  }) {
    return CustomerAppProfile(
      userId: userId,
      name: name ?? this.name,
      phone: phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      email: email ?? this.email,
      place: place ?? this.place,
      linkedCrmCustomerId: linkedCrmCustomerId ?? this.linkedCrmCustomerId,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
