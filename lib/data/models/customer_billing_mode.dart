/// How a CRM customer is billed (admin app vs customer app).
enum CustomerBillingMode {
  /// Monthly contract — ledger, PDF bill, WhatsApp (admin-managed).
  monthlyContract,

  /// Orders from customer app — per order / light balance, no monthly PDF.
  appOnDemand,
}

extension CustomerBillingModeX on CustomerBillingMode {
  String get label => switch (this) {
        CustomerBillingMode.monthlyContract => 'Monthly contract',
        CustomerBillingMode.appOnDemand => 'App customer',
      };

  bool get isMonthlyContract => this == CustomerBillingMode.monthlyContract;
  bool get isAppOnDemand => this == CustomerBillingMode.appOnDemand;
}
