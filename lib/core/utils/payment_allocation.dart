import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';

/// One calendar month's bill and how much payment has been allocated to it (FIFO).
class MonthlyLedgerEntry {
  const MonthlyLedgerEntry({
    required this.month,
    required this.billAmount,
    this.allocatedPaid = 0,
  });

  /// First day of the calendar month.
  final DateTime month;
  final double billAmount;
  final double allocatedPaid;

  double get pending =>
      (billAmount - allocatedPaid).clamp(0, double.infinity).toDouble();

  bool get isPaid => billAmount > 0 && pending <= 0;
  bool get isPartial => allocatedPaid > 0 && pending > 0;
}

/// Full result after FIFO — includes advance credit left after all bills.
class PaymentAllocationResult {
  const PaymentAllocationResult({
    required this.ledger,
    required this.advanceCredit,
  });

  final List<MonthlyLedgerEntry> ledger;
  final double advanceCredit;
}

/// Applies customer payments to the oldest unpaid month first (FIFO).
PaymentAllocationResult allocatePaymentsFifo({
  required List<Delivery> deliveries,
  required List<Payment> payments,
}) {
  final bills = <DateTime, double>{};
  for (final d in deliveries) {
    final key = DateTime(d.date.year, d.date.month);
    bills[key] = (bills[key] ?? 0) + d.totalAmount;
  }

  if (bills.isEmpty) {
    final advanceOnly = payments.fold<double>(0, (s, p) => s + p.amount);
    return PaymentAllocationResult(ledger: const [], advanceCredit: advanceOnly);
  }

  final months = bills.keys.toList()..sort();
  final ledger = months
      .map(
        (m) => MonthlyLedgerEntry(
          month: m,
          billAmount: bills[m]!,
        ),
      )
      .toList();

  final sortedPayments = List<Payment>.from(payments)
    ..sort((a, b) => a.date.compareTo(b.date));

  var advanceCredit = 0.0;
  for (final payment in sortedPayments) {
    var remaining = payment.amount;
    for (var i = 0; i < ledger.length && remaining > 0; i++) {
      final due = ledger[i].pending;
      if (due <= 0) continue;
      final apply = remaining < due ? remaining : due;
      ledger[i] = MonthlyLedgerEntry(
        month: ledger[i].month,
        billAmount: ledger[i].billAmount,
        allocatedPaid: ledger[i].allocatedPaid + apply,
      );
      remaining -= apply;
    }
    advanceCredit += remaining;
  }

  return PaymentAllocationResult(ledger: ledger, advanceCredit: advanceCredit);
}

MonthlyLedgerEntry? ledgerEntryForMonth(
  List<MonthlyLedgerEntry> ledger,
  DateTime month,
) {
  final key = DateTime(month.year, month.month);
  for (final e in ledger) {
    if (e.month.year == key.year && e.month.month == key.month) {
      return e;
    }
  }
  return null;
}

double totalPendingFromLedger(List<MonthlyLedgerEntry> ledger) =>
    ledger.fold<double>(0, (s, e) => s + e.pending);

double pendingBeforeMonth(List<MonthlyLedgerEntry> ledger, DateTime month) {
  final cutoff = DateTime(month.year, month.month);
  return ledger
      .where((e) => e.month.isBefore(cutoff))
      .fold<double>(0, (s, e) => s + e.pending);
}
