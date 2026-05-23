import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

List<Payment> seedPayments({required DateTime thisMonth}) {
  final prev1 = DateTime(thisMonth.year, thisMonth.month - 1);
  return [
    Payment(
      id: _uuid.v4(),
      customerId: 'c2',
      date: DateTime(thisMonth.year, thisMonth.month, 6),
      amount: 2000,
      method: PaymentMethod.upi,
    ),
    Payment(
      id: _uuid.v4(),
      customerId: 'c4',
      date: DateTime(thisMonth.year, thisMonth.month, 12),
      amount: 500,
      method: PaymentMethod.cash,
      notes: 'Partial payment',
    ),
    Payment(
      id: _uuid.v4(),
      customerId: 'c1',
      date: DateTime(prev1.year, prev1.month, 25),
      amount: 1500,
      method: PaymentMethod.upi,
    ),
    // Abi multi-shop payments
    Payment(
      id: _uuid.v4(),
      customerId: 'c1-shop2',
      date: DateTime(thisMonth.year, thisMonth.month, 8),
      amount: 400,
      method: PaymentMethod.upi,
      notes: 'Partial — Aqua Pure',
    ),
    Payment(
      id: _uuid.v4(),
      customerId: 'c1-shop4',
      date: DateTime(prev1.year, prev1.month, 28),
      amount: 900,
      method: PaymentMethod.cash,
      notes: 'Crystal Clear — full month',
    ),
  ];
}
