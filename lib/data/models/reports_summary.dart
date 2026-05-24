/// Aggregated report metrics from `/api/reports/*` or client fallback.
class ReportsSummary {
  const ReportsSummary({
    required this.totalDeliveries,
    required this.totalCans,
    required this.normalCans,
    required this.coolCans,
    required this.totalSales,
    required this.collected,
    required this.activeCustomers,
    required this.pendingAmount,
    required this.fromApi,
    this.dailyBuckets = const {},
  });

  final int totalDeliveries;
  final int totalCans;
  final int normalCans;
  final int coolCans;
  final double totalSales;
  final double collected;
  final int activeCustomers;
  final double pendingAmount;
  final bool fromApi;
  final Map<DateTime, ({int normal, int cool})> dailyBuckets;

  double get avgCansPerDay {
    if (dailyBuckets.isEmpty) return totalCans.toDouble();
    return totalCans / dailyBuckets.length;
  }

  double get collectionRate =>
      totalSales > 0 ? (collected / totalSales).clamp(0.0, 1.0) : 0;
}
