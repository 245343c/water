class MonthlyStats {
  const MonthlyStats({
    required this.normalCans,
    required this.coolCans,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
  });

  final int normalCans;
  final int coolCans;
  final double totalAmount;
  final double paidAmount;
  final double balance;

  bool get isPaid => balance <= 0 && totalAmount > 0;
  bool get isPending => totalAmount > 0 && balance > 0;
  String get statusLabel {
    if (totalAmount == 0) return 'No activity';
    return isPaid ? 'Paid' : 'Pending';
  }
}
