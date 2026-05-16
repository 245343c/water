enum DashboardActionKind {
  overdue,
  pendingPayment,
  noDeliveryToday,
  inactive,
}

class DashboardActionItem {
  const DashboardActionItem({
    required this.customerId,
    required this.customerName,
    required this.kind,
    required this.subtitle,
    required this.priority,
  });

  final String customerId;
  final String customerName;
  final DashboardActionKind kind;
  final String subtitle;
  final int priority;
}
