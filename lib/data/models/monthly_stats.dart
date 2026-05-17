class MonthlyStats {
  const MonthlyStats({
    required this.normalCans,
    required this.coolCans,
    required this.bottleUnits,
    required this.bottlesByLabel,
    required this.quantitiesByLabel,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
  });

  final int normalCans;
  final int coolCans;
  final int bottleUnits;
  final Map<String, int> bottlesByLabel;
  /// All delivered line items aggregated by product label (qty > 0 only).
  final Map<String, int> quantitiesByLabel;
  final double totalAmount;
  final double paidAmount;
  final double balance;

  bool get isPaid => balance <= 0 && totalAmount > 0;
  bool get isPending => totalAmount > 0 && balance > 0;

  bool get hasDeliveries =>
      quantitiesByLabel.values.any((q) => q > 0);

  int get totalUnits =>
      quantitiesByLabel.values.fold<int>(0, (s, q) => s + q);

  String get statusLabel {
    if (!hasDeliveries && totalAmount == 0) return 'No activity';
    return isPaid ? 'Paid' : 'Pending';
  }

  bool get hasBottles => bottleUnits > 0;

  /// Only products actually delivered this month (no zero rows).
  List<MonthlyStatRow> get summaryRows {
    if (!hasDeliveries) {
      return const [
        MonthlyStatRow(label: 'No deliveries this month', value: '—'),
      ];
    }

    final labels = quantitiesByLabel.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    labels.sort((a, b) {
      final orderA = _labelSortOrder(a);
      final orderB = _labelSortOrder(b);
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.compareTo(b);
    });

    return labels
        .map((label) => MonthlyStatRow(label: label, value: '${quantitiesByLabel[label]}'))
        .toList();
  }

  /// Short line for list tiles (e.g. bills, customers).
  String get deliveredItemsLabel {
    if (!hasDeliveries) return 'No deliveries this month';
    return summaryRows
        .where((r) => r.value.isNotEmpty && r.value != '—')
        .map((r) => '${r.value} ${r.label}')
        .join(' · ');
  }

  static int _labelSortOrder(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('normal')) return 0;
    if (lower.contains('cool')) return 1;
    return 2;
  }
}

class MonthlyStatRow {
  const MonthlyStatRow({
    required this.label,
    required this.value,
    this.indent = false,
  });

  final String label;
  final String value;
  final bool indent;
}
