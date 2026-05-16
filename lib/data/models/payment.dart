import 'package:sri_sai_ro_water/data/models/payment_method.dart';

class Payment {
  Payment({
    required this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    required this.method,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String customerId;
  DateTime date;
  double amount;
  PaymentMethod method;
  String? notes;
  final DateTime createdAt;
}
