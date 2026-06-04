/// Whether the driver should collect money at the door.
enum DispatchPaymentMode {
  /// Monthly bill or admin said pay later.
  billLater,

  /// Driver should collect cash or UPI when possible.
  collectAtDoor;

  String get label => switch (this) {
        DispatchPaymentMode.billLater => 'Pay later / monthly',
        DispatchPaymentMode.collectAtDoor => 'Collect at door',
      };
}
