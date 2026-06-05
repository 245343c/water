/// Payment outcome for instant / walk-in dispatch orders.
enum DispatchCollectionStatus {
  /// Driver or admin recorded cash or UPI at the door.
  collected,

  /// Delivered but customer did not pay; will follow up with admin.
  pending,

  /// Admin said pay later or no collection required.
  waived;

  String get label => switch (this) {
        DispatchCollectionStatus.collected => 'Payment received',
        DispatchCollectionStatus.pending => 'Payment pending',
        DispatchCollectionStatus.waived => 'Pay later',
      };

  String get shortLabel => switch (this) {
        DispatchCollectionStatus.collected => 'Collected',
        DispatchCollectionStatus.pending => 'Pending',
        DispatchCollectionStatus.waived => 'Pay later',
      };
}
