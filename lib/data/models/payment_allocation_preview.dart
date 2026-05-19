/// Preview of how a new payment will be applied (FIFO + any advance).
class PaymentAllocationPreview {
  const PaymentAllocationPreview({
    required this.pendingBefore,
    required this.appliedToDue,
    required this.advanceCredit,
    required this.pendingAfter,
  });

  final double pendingBefore;
  final double appliedToDue;
  final double advanceCredit;
  final double pendingAfter;

  bool get hasAdvance => advanceCredit > 0;
  bool get clearsAllDue => pendingBefore > 0 && pendingAfter <= 0 && !hasAdvance;
}
