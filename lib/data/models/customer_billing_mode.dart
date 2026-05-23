/// How a CRM customer is billed.
///
/// Current product scope has only monthly customers. They can still use the
/// customer app to request/order water from linked admins/plants.
enum CustomerBillingMode {
  /// Monthly contract — ledger, PDF bill, WhatsApp, and app requests.
  monthlyContract,
}

extension CustomerBillingModeX on CustomerBillingMode {
  String get label => switch (this) {
    CustomerBillingMode.monthlyContract => 'Monthly contract',
  };

  bool get isMonthlyContract => this == CustomerBillingMode.monthlyContract;
}
