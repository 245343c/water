import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_app_profile.dart';
import 'package:sri_sai_ro_water/data/models/customer_billing_mode.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';
import 'package:sri_sai_ro_water/data/models/customer_shop_billing.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_action_item.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_stats.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/driver.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/models/payment_allocation_preview.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/models/promotion.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/core/utils/payment_allocation.dart';

/// Abstract contract for all water plant business data.
/// Concrete implementations: [WaterPlantRepository] (mock), ApiWaterPlantRepository (backend).
abstract class IWaterPlantRepository extends ChangeNotifier {
  // Settings
  BusinessSettings get settings;
  String? get adminImagePath;
  void updateAdminImage(String? path);
  Future<void> uploadAdminPhoto(String localPath);
  Future<void> clearAdminPhoto();
  Future<void> updateSettings(BusinessSettings newSettings);

  // Customers
  List<Customer> get customers;
  Customer? customerById(String id);
  List<Customer> searchCustomers(String query);
  List<Customer> customersForShop(String shopId);
  List<Customer> customersForDriver(String? driverId);
  bool canDriverAccessCustomer(String? driverId, String customerId);
  List<Customer> searchCustomersForDriver(String? driverId, String query);
  Future<Customer> addCustomer({
    required String name,
    required String phone,
    required String address,
    String email = '',
    String place = '',
    CustomerBillingMode billingMode = CustomerBillingMode.monthlyContract,
    List<CustomerProductPrice>? productPrices,
  });
  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  List<CustomerProductPrice> defaultCustomerPricing();
  double customerUnitPrice(
    Customer customer, {
    required String productId,
    required String variantId,
  });

  // Customer app profiles
  CustomerAppProfile? customerProfileByUserId(String userId);
  Future<void> saveCustomerProfile(CustomerAppProfile profile);
  Customer? linkedCrmCustomerForAppUser(String userId);
  List<Customer> linkedCrmCustomersForAppUser(String userId, {String? phone});
  Future<void> linkContractCustomerOnLogin({
    required String userId,
    required String phone,
  });
  bool isMonthlyContractAppUser(String userId, {String? phone});
  List<CustomerShopBilling> shopBillingsForAppUser(String userId);
  double totalPendingForAppUser(String userId);

  // Shops
  List<Shop> get shops;
  Shop? shopById(String id);
  List<Shop> listedShops();
  List<Shop> searchListedShops(String query);
  String shopIdForCustomer(String customerId);
  String shopIdForDriver(String driverId);
  List<Shop> linkedShopsForAppUser(String userId, {String? phone});
  bool canAppUserAccessShop(String userId, String shopId, {String? phone});

  // Drivers
  List<Driver> get drivers;
  Driver? driverById(String? id);
  Future<Driver> addDriver({required String name, required String phone, required String email});
  Future<void> setDriverActive(String driverId, bool active);
  List<Customer> todaysRouteCustomersForDriver(String? driverId);
  String? routeNoteForCustomer(String customerId);

  // Deliveries
  List<Delivery> get deliveries;
  List<Delivery> deliveriesForCustomer(String customerId, {DateTime? month});
  List<Delivery> deliveriesOnDate(DateTime day);
  List<Delivery> deliveriesOnDateForDriver(DateTime day, String? driverId);
  List<Delivery> recentDeliveries({int limit = 8});
  bool hasDeliveryToday(String customerId);
  Future<Delivery> addDelivery({
    required String customerId,
    required DateTime date,
    int normalQty = 0,
    int coolQty = 0,
    List<BottleDeliveryInput> bottles = const [],
    String? driverId,
  });

  // Payments / Cash
  List<Payment> get payments;
  List<Payment> paymentsForCustomer(String customerId, {DateTime? month});
  Payment? lastPayment(String customerId);
  Future<Payment> addPayment({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? notes,
  });
  double customerBalance(String customerId);
  double customerAdvanceCredit(String customerId);
  PaymentAllocationPreview previewPayment(String customerId, double paymentAmount);
  List<MonthlyLedgerEntry> customerLedger(String customerId);

  // Orders
  List<CustomerOrder> get orders;
  CustomerOrder? orderById(String id);
  List<CustomerOrder> ordersNewestFirst();
  List<CustomerOrder> ordersForAppUser(String appUserId);
  int get pendingOrderCount;
  Future<CustomerOrder> placeAppOrder({
    required String shopId,
    required String appUserId,
    required int normalQty,
    required int coolQty,
    String? customerNote,
    String? productSummary,
  });
  Future<void> respondToOrder(String orderId, OrderStatus status, {String? adminResponse});
  List<CustomerOrder> driverAcceptedOrders({String? driverId});

  // Products
  List<Product> get products;
  Product? productById(String id);
  List<Product> get bottleCatalog;
  List<Product> searchProducts(String query);
  Future<Product> addProduct({
    required String name,
    String? description,
    required ProductCategory category,
    required String variantLabel,
    required double price,
    bool isCool = false,
    String? imageSourcePath,
  });
  Future<void> deleteProduct(String id);
  List<Product> bottleCatalogForCustomer(Customer customer);

  // Promotions
  List<Promotion> get promotions;

  // Stats / Dashboard
  DashboardStats dashboardStats(DateTime month);
  List<DashboardActionItem> dashboardActionItems({int limit = 5});
  MonthlyStats monthlyStatsForCustomer(String customerId, DateTime month);
  double previousBalanceForMonth(String customerId, DateTime month);
  Map<DateTime, ({int normal, int cool})> dailyCanTotals(DateTime start, DateTime end);
}
