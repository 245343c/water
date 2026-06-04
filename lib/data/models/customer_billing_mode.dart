/// How a CRM customer is billed.
enum CustomerBillingMode {
  /// Monthly contract — ledger, PDF bill, WhatsApp, and app requests.
  monthlyContract,

  /// One-off walk-in / phone caller — not in customer list; pay at door.
  instantDispatch,
}

extension CustomerBillingModeX on CustomerBillingMode {
  String get label => switch (this) {
    CustomerBillingMode.monthlyContract => 'Monthly contract',
    CustomerBillingMode.instantDispatch => 'Walk-in today',
  };

  bool get isMonthlyContract => this == CustomerBillingMode.monthlyContract;

  bool get isInstantDispatch => this == CustomerBillingMode.instantDispatch;
}
