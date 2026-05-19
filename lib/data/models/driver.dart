class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final bool active;
  final DateTime? createdAt;

  Driver copyWith({
    String? name,
    String? phone,
    String? email,
    bool? active,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }
}
