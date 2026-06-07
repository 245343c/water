class DashboardStats {
  const DashboardStats({
    required this.totalDeliveries,
    required this.totalCans,
    required this.totalLiters,
    required this.totalLoads,
    required this.totalSales,
    required this.activeCustomers,
    required this.paidThisMonth,
    required this.pendingAmount,
  });

  final int totalDeliveries;
  final int totalCans;
  final int totalLiters;
  final int totalLoads;
  final double totalSales;
  final int activeCustomers;
  final double paidThisMonth;
  final double pendingAmount;
}
