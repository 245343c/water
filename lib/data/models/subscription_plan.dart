/// Platform plans for shop owners (admin pays; customers/drivers free).
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.monthlyPriceInr,
    required this.annualPriceInr,
    required this.customerLimit,
    required this.driverLimit,
    required this.features,
    this.recommended = false,
  });

  final String id;
  final String name;
  final String tagline;
  final int monthlyPriceInr;
  final int annualPriceInr;
  final int customerLimit;
  final int driverLimit;
  final List<String> features;
  final bool recommended;
}

abstract final class SubscriptionPlans {
  static const trialDays = 30;
  static const graceDays = 7;

  static const starter = SubscriptionPlan(
    id: 'starter',
    name: 'Starter',
    tagline: 'Small routes · one driver',
    monthlyPriceInr: 499,
    annualPriceInr: 4999,
    customerLimit: 150,
    driverLimit: 1,
    features: [
      'Up to 150 customers',
      '1 driver login',
      'Quick orders & monthly billing',
      'Push alerts for drivers',
    ],
  );

  static const standard = SubscriptionPlan(
    id: 'standard',
    name: 'Standard',
    tagline: 'Growing shops · most popular',
    monthlyPriceInr: 999,
    annualPriceInr: 9999,
    customerLimit: 500,
    driverLimit: 5,
    recommended: true,
    features: [
      'Up to 500 customers',
      'Up to 5 drivers',
      'Reports & route planning',
      'Priority email support',
    ],
  );

  static const premium = SubscriptionPlan(
    id: 'premium',
    name: 'Premium',
    tagline: 'High volume · multi-route',
    monthlyPriceInr: 1999,
    annualPriceInr: 19999,
    customerLimit: 1500,
    driverLimit: 15,
    features: [
      'Up to 1,500 customers',
      'Up to 15 drivers',
      'Advanced reports',
      'Dedicated onboarding help',
    ],
  );

  static const List<SubscriptionPlan> catalog = [starter, standard, premium];

  static SubscriptionPlan? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final plan in catalog) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  static SubscriptionPlan get recommended => standard;
}
