class DashboardStats {
  const DashboardStats({
    required this.totalDeliveries,
    required this.totalCans,
    required this.totalSales,
    required this.activeCustomers,
    required this.paidThisMonth,
    required this.pendingAmount,
  });

  final int totalDeliveries;
  final int totalCans;
  final double totalSales;
  final int activeCustomers;
  final double paidThisMonth;
  final double pendingAmount;
}
