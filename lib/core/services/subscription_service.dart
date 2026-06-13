import 'package:sri_sai_ro_water/core/subscription/shop_subscription_logic.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/models/subscription_plan.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

/// Admin shop subscription — sync, activate (mock payment), limits.
class SubscriptionService {
  SubscriptionService({required WaterPlantRepository plant}) : _plant = plant;

  final WaterPlantRepository _plant;

  Shop? get currentShop => _plant.adminShop;

  ShopSubscriptionView? get view {
    final shop = currentShop;
    if (shop == null) return null;
    return shop.subscriptionView;
  }

  SubscriptionPlan get currentPlan =>
      SubscriptionPlans.byId(currentShop?.planId) ?? SubscriptionPlans.standard;

  Future<Shop> refreshSubscription() => _plant.syncShopSubscriptionFromCloud();

  Future<Shop> activatePlan({
    required String planId,
    SubscriptionBillingCycle billingCycle = SubscriptionBillingCycle.monthly,
  }) =>
      _plant.activateShopSubscriptionPlan(
        planId: planId,
        billingCycle: billingCycle,
      );

  bool canAddCustomer({int extra = 1}) =>
      _plant.canAddCustomerWithinPlan(extra: extra);

  bool canAddDriver({int extra = 1}) =>
      _plant.canAddDriverWithinPlan(extra: extra);

  String? customerLimitMessage() => _plant.customerPlanLimitMessage();

  String? driverLimitMessage() => _plant.driverPlanLimitMessage();
}
