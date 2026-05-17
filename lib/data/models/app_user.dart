class AppUser {
  const AppUser({
    required this.id,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.businessName,
  });

  final String id;
  final String ownerName;
  final String email;
  final String phone;
  final String businessName;
}
