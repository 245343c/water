enum OrderStatus {
  pending,
  accepted,
  assigned,
  outForDelivery,
  delivered,
  rejected,
  cancelled;

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.accepted => 'Accepted',
    OrderStatus.assigned => 'Assigned',
    OrderStatus.outForDelivery => 'Out for delivery',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.rejected => 'Declined',
    OrderStatus.cancelled => 'Cancelled',
  };

  /// Admin accepted through driver en route — still an open delivery task.
  bool get isOpenDelivery =>
      this == accepted ||
      this == assigned ||
      this == outForDelivery;

  bool get isTerminal =>
      this == rejected || this == cancelled || this == delivered;

  static OrderStatus fromApi(String? raw) {
    return switch (raw) {
      'accepted' => OrderStatus.accepted,
      'assigned' => OrderStatus.assigned,
      'out_for_delivery' => OrderStatus.outForDelivery,
      'delivered' => OrderStatus.delivered,
      'rejected' => OrderStatus.rejected,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  String get apiValue => switch (this) {
    OrderStatus.pending => 'pending',
    OrderStatus.accepted => 'accepted',
    OrderStatus.assigned => 'assigned',
    OrderStatus.outForDelivery => 'out_for_delivery',
    OrderStatus.delivered => 'delivered',
    OrderStatus.rejected => 'rejected',
    OrderStatus.cancelled => 'cancelled',
  };
}
