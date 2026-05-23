enum OrderStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.accepted => 'Accepted',
    OrderStatus.rejected => 'Declined',
    OrderStatus.cancelled => 'Cancelled',
  };
}
