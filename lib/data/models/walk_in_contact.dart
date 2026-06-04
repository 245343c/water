/// Caller details stored on a walk-in dispatch order (source of truth for driver).
class WalkInContact {
  const WalkInContact({
    required this.name,
    required this.phone,
    required this.address,
    this.place = '',
  });

  final String name;
  final String phone;
  final String address;
  final String place;

  factory WalkInContact.fromMap(Map<String, dynamic> data) {
    return WalkInContact(
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      place: data['place'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'address': address,
        'place': place,
      };
}
