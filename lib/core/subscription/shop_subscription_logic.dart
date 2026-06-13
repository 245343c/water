import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/models/subscription_plan.dart';

/// Resolves trial/grace/expired from stored shop fields + clock.
class ShopSubscriptionView {
  ShopSubscriptionView({required this.shop, DateTime? now})
    : clock = now ?? DateTime.now();

  final Shop shop;
  final DateTime clock;

  ShopSubscriptionStatus get effectiveStatus {
    switch (shop.subscriptionStatus) {
      case ShopSubscriptionStatus.active:
        final renews = shop.currentPeriodEndsAt;
        if (renews != null && !clock.isBefore(renews)) {
          final graceEnd =
              shop.graceEndsAt ??
              renews.add(const Duration(days: SubscriptionPlans.graceDays));
          if (clock.isBefore(graceEnd)) {
            return ShopSubscriptionStatus.grace;
          }
          return ShopSubscriptionStatus.expired;
        }
        return ShopSubscriptionStatus.active;
      case ShopSubscriptionStatus.trial:
        final trialEnd = shop.trialEndsAt;
        if (trialEnd == null || clock.isBefore(trialEnd)) {
          return ShopSubscriptionStatus.trial;
        }
        final graceEnd =
            shop.graceEndsAt ??
            trialEnd.add(const Duration(days: SubscriptionPlans.graceDays));
        if (clock.isBefore(graceEnd)) {
          return ShopSubscriptionStatus.grace;
        }
        return ShopSubscriptionStatus.expired;
      case ShopSubscriptionStatus.grace:
        final graceEnd =
            shop.graceEndsAt ??
            shop.trialEndsAt?.add(
              const Duration(days: SubscriptionPlans.graceDays),
            );
        if (graceEnd != null && !clock.isBefore(graceEnd)) {
          return ShopSubscriptionStatus.expired;
        }
        return ShopSubscriptionStatus.grace;
      case ShopSubscriptionStatus.expired:
        return ShopSubscriptionStatus.expired;
    }
  }

  bool get canAccessAdminFeatures =>
      effectiveStatus != ShopSubscriptionStatus.expired;

  bool get isTrialEndingSoon {
    if (effectiveStatus != ShopSubscriptionStatus.trial) return false;
    final days = trialDaysRemaining;
    return days != null && days <= 7;
  }

  int? get trialDaysRemaining {
    final end = shop.trialEndsAt;
    if (end == null) return SubscriptionPlans.trialDays;
    final diff = end.difference(clock).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  int? get graceDaysRemaining {
    if (effectiveStatus != ShopSubscriptionStatus.grace) return null;
    final end =
        shop.graceEndsAt ??
        shop.trialEndsAt?.add(
          const Duration(days: SubscriptionPlans.graceDays),
        ) ??
        shop.currentPeriodEndsAt?.add(
          const Duration(days: SubscriptionPlans.graceDays),
        );
    if (end == null) return null;
    final diff = end.difference(clock).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  DateTime? get renewalDate {
    if (effectiveStatus == ShopSubscriptionStatus.trial) {
      return shop.trialEndsAt;
    }
    return shop.currentPeriodEndsAt ?? shop.trialEndsAt;
  }

  double get trialProgress {
    final end = shop.trialEndsAt;
    if (end == null) return 0;
    final start = end.subtract(
      const Duration(days: SubscriptionPlans.trialDays),
    );
    final total = end.difference(start).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = clock.difference(start).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
