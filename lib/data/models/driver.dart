class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.active = true,
    this.loginUid,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final bool active;
  /// Set when admin created a login for this driver (`User.uid`).
  final String? loginUid;
  final DateTime? createdAt;

  Driver copyWith({
    String? name,
    String? phone,
    String? email,
    bool? active,
    String? loginUid,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      active: active ?? this.active,
      loginUid: loginUid ?? this.loginUid,
      createdAt: createdAt,
    );
  }

  bool get hasLoginAccount => loginUid != null && loginUid!.isNotEmpty;
}
