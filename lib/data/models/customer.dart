class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email = '',
    this.place = '',
    this.paymentFrequency = 'Monthly',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String phone;
  String address;
  String email;
  String place;
  String paymentFrequency;
  final DateTime createdAt;

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
    String? paymentFrequency,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      place: place ?? this.place,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      createdAt: createdAt,
    );
  }
}
