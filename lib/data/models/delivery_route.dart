class DeliveryRoute {
  const DeliveryRoute({
    required this.id,
    required this.name,
    this.active = true,
  });

  final String id;
  final String name;
  final bool active;

  DeliveryRoute copyWith({
    String? name,
    bool? active,
  }) {
    return DeliveryRoute(
      id: id,
      name: name ?? this.name,
      active: active ?? this.active,
    );
  }
}
