import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/data/models/customer_app_profile.dart';
import 'package:sri_sai_ro_water/data/models/customer_billing_mode.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_action_item.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_stats.dart';
import 'package:sri_sai_ro_water/data/models/driver.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/data/models/payment_allocation_preview.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/models/product_variant.dart';
import 'package:sri_sai_ro_water/data/models/promotion.dart';
import 'package:sri_sai_ro_water/data/models/customer_shop_billing.dart';
import 'package:sri_sai_ro_water/core/services/product_image_service.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/utils/payment_allocation.dart';
import 'package:sri_sai_ro_water/data/mock/mock_customers.dart';
import 'package:sri_sai_ro_water/data/mock/mock_drivers.dart';
import 'package:sri_sai_ro_water/data/mock/mock_shops.dart';
import 'package:sri_sai_ro_water/data/mock/mock_orders.dart';
import 'package:sri_sai_ro_water/data/mock/mock_deliveries.dart';
import 'package:sri_sai_ro_water/data/mock/mock_payments.dart';
import 'package:sri_sai_ro_water/data/mock/mock_promotions.dart';
import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/core/services/api/api_config.dart';
import 'package:sri_sai_ro_water/core/services/api/api_data_service.dart';
import 'package:sri_sai_ro_water/core/services/api/api_client.dart';
import 'package:sri_sai_ro_water/data/repositories/i_water_plant_repository.dart';
import 'package:uuid/uuid.dart';

class WaterPlantRepository extends IWaterPlantRepository {
  WaterPlantRepository() {
    _apiService = ApiDataService(ApiClient.instance);
    if (!useBackend) {
      _seedMockData();
    } else {
      // Start with empty state; loadFromBackend() populates it
      settings = BusinessSettings(
        businessName: 'Sri Sai RO Water Plant',
        address: '',
        phone: '',
        email: '',
        normalPrice: 20,
        coolPrice: 30,
        homeDeliveryAvailable: false,
      );
    }
  }

  late final ApiDataService _apiService;

  static const _uuid = Uuid();
  final List<Customer> _customers = [];
  final List<Delivery> _deliveries = [];
  final List<Payment> _payments = [];
  final List<CustomerOrder> _orders = [];
  final List<Product> _products = [];
  final List<Driver> _drivers = [];
  final List<Shop> _shops = [];
  final List<Promotion> _promotions = [];

  /// CRM customer id → marketplace shop id (multi-shop bulk billing).
  final Map<String, String> _customerShopIds = {};

  /// Driver id -> shop id. Mock uses one shop today, but this is Firebase-ready.
  final Map<String, String> _driverShopIds = {};
  final Map<String, CustomerAppProfile> _customerProfiles = {};
  final Map<String, String> _routeNotes = {};
  List<String> _todaysRouteIds = [];

  static const defaultShopId = 'shop-1';

  late BusinessSettings settings;

  /// Local path to the admin's profile photo (null = not set).
  String? adminImagePath;

  void updateAdminImage(String? path) {
    adminImagePath = path;
    notifyListeners();
  }

  List<Customer> get customers => List.unmodifiable(_customers);
  List<Delivery> get deliveries => List.unmodifiable(_deliveries);
  List<Payment> get payments => List.unmodifiable(_payments);
  List<CustomerOrder> get orders => List.unmodifiable(_orders);
  List<Product> get products => List.unmodifiable(_products);
  List<Driver> get drivers => List.unmodifiable(_drivers);
  List<Shop> get shops => List.unmodifiable(_shops);

  List<Shop> listedShops() =>
      _shops.where((s) => s.isVisibleToCustomers).toList();

  List<Shop> searchListedShops(String query) {
    final q = query.trim().toLowerCase();
    final base = listedShops();
    if (q.isEmpty) return base;
    return base
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q) ||
              s.place.toLowerCase().contains(q) ||
              s.phone
                  .replaceAll(RegExp(r'\D'), '')
                  .contains(q.replaceAll(RegExp(r'\D'), '')),
        )
        .toList();
  }

  Shop? shopById(String id) {
    try {
      return _shops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  CustomerAppProfile? customerProfileByUserId(String userId) =>
      _customerProfiles[userId];

  void saveCustomerProfile(CustomerAppProfile profile) {
    _customerProfiles[profile.userId] = profile;
    notifyListeners();
  }

  static String normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '');

  /// CRM row matching mobile (admin-created customers).
  Customer? crmCustomerByPhone(String phone) {
    final digits = normalizePhone(phone);
    if (digits.length < 10) return null;
    try {
      return _customers.firstWhere((c) => normalizePhone(c.phone) == digits);
    } catch (_) {
      return null;
    }
  }

  String? crmCustomerIdForAppUser(String userId) {
    final profile = customerProfileByUserId(userId);
    if (profile?.linkedCrmCustomerId != null) {
      return profile!.linkedCrmCustomerId;
    }
    return null;
  }

  Customer? linkedCrmCustomerForAppUser(String userId) {
    final id = crmCustomerIdForAppUser(userId);
    if (id != null) return customerById(id);
    final profile = customerProfileByUserId(userId);
    if (profile != null) {
      return crmCustomerByPhone(profile.phone);
    }
    return null;
  }

  List<Customer> linkedCrmCustomersForAppUser(String userId, {String? phone}) {
    final profile = customerProfileByUserId(userId);
    final linkedId = crmCustomerIdForAppUser(userId);
    final digits = normalizePhone(profile?.phone ?? phone ?? '');
    if (digits.isEmpty && linkedId == null) return const [];

    final seen = <String>{};
    final matches = <Customer>[];
    for (final c in _customers) {
      final byId = linkedId != null && c.id == linkedId;
      final byPhone = digits.isNotEmpty && normalizePhone(c.phone) == digits;
      if ((byId || byPhone) && seen.add(c.id)) {
        matches.add(c);
      }
    }
    return matches;
  }

  String shopIdForCustomer(String customerId) =>
      _customerShopIds[customerId] ?? defaultShopId;

  String shopIdForDriver(String driverId) =>
      _driverShopIds[driverId] ?? defaultShopId;

  Shop? shopForDriver(String? driverId) {
    if (driverId == null || driverId.isEmpty) return null;
    return shopById(shopIdForDriver(driverId));
  }

  List<Customer> customersForShop(String shopId) =>
      _customers.where((c) => shopIdForCustomer(c.id) == shopId).toList();

  List<Customer> customersForDriver(String? driverId) {
    final shop = shopForDriver(driverId);
    if (shop == null) return const [];
    return customersForShop(shop.id);
  }

  bool canDriverAccessCustomer(String? driverId, String customerId) {
    final shop = shopForDriver(driverId);
    if (shop == null) return false;
    return shopIdForCustomer(customerId) == shop.id;
  }

  List<Customer> searchCustomersForDriver(String? driverId, String query) {
    final base = customersForDriver(driverId);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Customer>.from(base);
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    return base
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.place.toLowerCase().contains(q) ||
              (qDigits.isNotEmpty && normalizePhone(c.phone).contains(qDigits)),
        )
        .toList();
  }

  List<Shop> linkedShopsForAppUser(String userId, {String? phone}) {
    final seen = <String>{};
    final shops = <Shop>[];
    for (final customer in linkedCrmCustomersForAppUser(userId, phone: phone)) {
      final shop = shopById(shopIdForCustomer(customer.id));
      if (shop != null && seen.add(shop.id)) {
        shops.add(shop);
      }
    }
    shops.sort((a, b) {
      if (a.id == defaultShopId) return -1;
      if (b.id == defaultShopId) return 1;
      return a.name.compareTo(b.name);
    });
    return shops;
  }

  List<Shop> searchLinkedShopsForAppUser(
    String userId,
    String query, {
    String? phone,
  }) {
    final q = query.trim().toLowerCase();
    final base = linkedShopsForAppUser(userId, phone: phone);
    if (q.isEmpty) return base;
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    return base
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q) ||
              s.place.toLowerCase().contains(q) ||
              (qDigits.isNotEmpty &&
                  s.phone.replaceAll(RegExp(r'\D'), '').contains(qDigits)),
        )
        .toList();
  }

  bool canAppUserAccessShop(String userId, String shopId, {String? phone}) {
    return linkedShopsForAppUser(
      userId,
      phone: phone,
    ).any((s) => s.id == shopId);
  }

  void _linkCustomerToShop(String customerId, String shopId) {
    _customerShopIds[customerId] = shopId;
  }

  void _linkDriverToShop(String driverId, String shopId) {
    _driverShopIds[driverId] = shopId;
  }

  /// All monthly-contract CRM rows for this app user (one per shop).
  List<CustomerShopBilling> shopBillingsForAppUser(String userId) {
    final profile = customerProfileByUserId(userId);
    final linkedId = crmCustomerIdForAppUser(userId);
    final digits = normalizePhone(profile?.phone ?? '');
    if (digits.isEmpty && linkedId == null) return [];

    final matches = <Customer>[];
    for (final c in _customers) {
      if (!c.isMonthlyContract) continue;
      if (linkedId != null && c.id == linkedId) {
        matches.add(c);
        continue;
      }
      if (digits.isNotEmpty && normalizePhone(c.phone) == digits) {
        matches.add(c);
      }
    }

    final seen = <String>{};
    final billings = <CustomerShopBilling>[];
    for (final c in matches) {
      if (!seen.add(c.id)) continue;
      final shop = shopById(shopIdForCustomer(c.id));
      if (shop != null) {
        billings.add(CustomerShopBilling(shop: shop, customer: c));
      }
    }

    billings.sort((a, b) {
      if (a.shop.id == defaultShopId) return -1;
      if (b.shop.id == defaultShopId) return 1;
      return a.shop.name.compareTo(b.shop.name);
    });
    return billings;
  }

  double totalPendingForAppUser(String userId) {
    var total = 0.0;
    for (final b in shopBillingsForAppUser(userId)) {
      total += customerBalance(b.customer.id);
    }
    return total;
  }

  /// Bulk / monthly contract customer — only after CRM link on login (not phone guess).
  bool isMonthlyContractAppUser(String userId, {String? phone}) {
    final linked = linkedCrmCustomerForAppUser(userId);
    return linked?.isMonthlyContract ?? false;
  }

  /// Links app login to an admin-created CRM row when the phone matches.
  void linkContractCustomerOnLogin({
    required String userId,
    required String phone,
  }) {
    final crm = crmCustomerByPhone(phone);
    if (crm == null) return;

    final lat = settings.shopLatitude ?? 16.9902;
    final lng = settings.shopLongitude ?? 81.7780;

    saveCustomerProfile(
      CustomerAppProfile(
        userId: userId,
        name: crm.name,
        phone: normalizePhone(phone),
        address: crm.address,
        latitude: lat,
        longitude: lng,
        email: crm.email,
        place: crm.place,
        linkedCrmCustomerId: crm.id,
        onboardingComplete: true,
      ),
    );
  }

  void _seedMockData() {
    settings = BusinessSettings(
      businessName: 'Sri Sai RO Water Plant',
      address: 'Main Road, Rajahmundry, Andhra Pradesh - 533101',
      shopLatitude: 16.9902,
      shopLongitude: 81.7780,
      phone: '+91 98765 43210',
      email: 'info@srisairowater.com',
      normalPrice: 20,
      coolPrice: 30,
      homeDeliveryAvailable: true,
    );

    _syncShopFromSettings();
    _shops.addAll(seedMarketplaceShops());
    _seedProducts();

    _promotions.addAll(seedPromotions(
      shopId: defaultShopId,
      shopName: settings.businessName,
      now: DateTime.now(),
    ));

    _drivers.addAll(seedDrivers());
    _linkDriverToShop('driver-1', defaultShopId);

    final coreCustomers = seedCoreCustomers();
    _customers.addAll(coreCustomers);
    for (final c in coreCustomers) {
      _linkCustomerToShop(c.id, defaultShopId);
    }

    // Abi multi-shop linked accounts
    final abiTemplate = coreCustomers.first;
    final multiShopPairs = [
      ('c1-shop2', 'shop-2'),
      ('c1-shop3', 'shop-3'),
      ('c1-shop4', 'shop-4'),
    ];
    for (final (id, shopId) in multiShopPairs) {
      if (_customers.any((c) => c.id == id)) continue;
      _linkCustomerToShop(id, shopId);
      _customers.add(Customer(
        id: id,
        name: abiTemplate.name,
        phone: abiTemplate.phone,
        billingMode: CustomerBillingMode.monthlyContract,
        email: abiTemplate.email,
        place: abiTemplate.place,
        address: abiTemplate.address,
        productPrices: abiTemplate.productPrices,
      ));
    }

    // Driver demo customers
    final demoCustomers = seedDriverDemoCustomers();
    _customers.addAll(demoCustomers);
    for (final c in demoCustomers) {
      _linkCustomerToShop(c.id, defaultShopId);
    }

    // Route notes and today's route
    _routeNotes.addAll({
      'c2': 'Weekly route — usually 3 normal + 1 cool',
      'c3': 'Apartment — ask security for entry',
      'c5': 'New customer — confirm cans every visit',
      'c6': 'Call 5 min before arrival',
      'c7': 'Shop — back entrance for cans',
    });
    _todaysRouteIds = ['c2', 'c3', 'c5', 'c6', 'c7'];

    // Deliveries
    final now = DateTime.now();
    _deliveries.addAll(seedDeliveries(
      now: now,
      normalPrice: settings.normalPrice,
      coolPrice: settings.coolPrice,
      shops: _shops,
    ));

    // Payments
    final thisMonth = DateTime(now.year, now.month);
    _payments.addAll(seedPayments(thisMonth: thisMonth));

    // Orders
    _orders.addAll(seedOrders(now: now));
  }

  List<Customer> get todaysRouteCustomers {
    return _todaysRouteIds.map(customerById).whereType<Customer>().toList();
  }

  List<Customer> todaysRouteCustomersForDriver(String? driverId) {
    final shop = shopForDriver(driverId);
    if (shop == null) return const [];
    return todaysRouteCustomers
        .where((c) => shopIdForCustomer(c.id) == shop.id)
        .toList();
  }

  String? routeNoteForCustomer(String customerId) => _routeNotes[customerId];

  bool hasDeliveryToday(String customerId) {
    final today = DateTime.now();
    return deliveriesOnDate(today).any((d) => d.customerId == customerId);
  }

  Delivery? deliveryForOrder(CustomerOrder order) {
    if (order.status != OrderStatus.accepted) return null;
    final start = order.respondedAt ?? order.createdAt;
    final matches =
        _deliveries
            .where(
              (d) =>
                  d.customerId == order.customerId &&
                  !d.date.isBefore(start) &&
                  d.normalQty >= order.normalQty &&
                  d.coolQty >= order.coolQty,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return matches.isEmpty ? null : matches.first;
  }

  Customer? customerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  PaymentAllocationResult _allocationFor(String customerId) {
    final deliveries = _deliveries
        .where((d) => d.customerId == customerId)
        .toList();
    final payments = _payments
        .where((p) => p.customerId == customerId)
        .toList();
    return allocatePaymentsFifo(deliveries: deliveries, payments: payments);
  }

  /// FIFO ledger — payments clear oldest monthly bills first.
  List<MonthlyLedgerEntry> customerLedger(String customerId) =>
      _allocationFor(customerId).ledger;

  double _deliveryTotal(String customerId) => _deliveries
      .where((d) => d.customerId == customerId)
      .fold<double>(0, (sum, d) => sum + d.totalAmount);

  double _paymentTotal(String customerId) => _payments
      .where((p) => p.customerId == customerId)
      .fold<double>(0, (sum, p) => sum + p.amount);

  double customerBalance(String customerId) {
    final pending = totalPendingFromLedger(customerLedger(customerId));
    if (pending > 0) return pending;
    return (_deliveryTotal(customerId) - _paymentTotal(customerId)).clamp(
      0,
      double.infinity,
    );
  }

  /// Extra paid after all monthly bills are cleared — auto-used on next delivery.
  double customerAdvanceCredit(String customerId) {
    final fromFifo = _allocationFor(customerId).advanceCredit;
    if (fromFifo > 0) return fromFifo;
    return (_paymentTotal(customerId) - _deliveryTotal(customerId)).clamp(
      0,
      double.infinity,
    );
  }

  /// Simulates a new payment before saving (FIFO + advance).
  PaymentAllocationPreview previewPayment(
    String customerId,
    double paymentAmount,
  ) {
    if (paymentAmount <= 0) {
      final pending = customerBalance(customerId);
      return PaymentAllocationPreview(
        pendingBefore: pending,
        appliedToDue: 0,
        advanceCredit: 0,
        pendingAfter: pending,
      );
    }
    final pendingBefore = customerBalance(customerId);
    final appliedToDue = paymentAmount < pendingBefore
        ? paymentAmount
        : pendingBefore;
    final advance = paymentAmount - appliedToDue;
    final pendingAfter = (pendingBefore - appliedToDue)
        .clamp(0.0, double.infinity)
        .toDouble();
    return PaymentAllocationPreview(
      pendingBefore: pendingBefore,
      appliedToDue: appliedToDue,
      advanceCredit: advance,
      pendingAfter: pendingAfter,
    );
  }

  List<Delivery> deliveriesForCustomer(String customerId, {DateTime? month}) {
    var list = _deliveries.where((d) => d.customerId == customerId).toList();
    if (month != null) {
      list = list.where((d) => d.date.isSameMonth(month)).toList();
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Payment> paymentsForCustomer(String customerId, {DateTime? month}) {
    var list = _payments.where((p) => p.customerId == customerId).toList();
    if (month != null) {
      list = list.where((p) => p.date.isSameMonth(month)).toList();
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Payment? lastPayment(String customerId) {
    final list = paymentsForCustomer(customerId);
    return list.isEmpty ? null : list.first;
  }

  double paymentsTotalForMonth(String customerId, DateTime month) {
    return paymentsForCustomer(
      customerId,
      month: month,
    ).fold<double>(0, (sum, p) => sum + p.amount);
  }

  Map<String, int> _bottlesByLabelFromDeliveries(List<Delivery> deliveries) {
    final map = <String, int>{};
    for (final d in deliveries) {
      for (final line in d.lines.where(
        (l) => l.kind == DeliveryItemKind.bottle,
      )) {
        map[line.label] = (map[line.label] ?? 0) + line.quantity;
      }
    }
    return map;
  }

  Map<String, int> _quantitiesByLabelFromDeliveries(List<Delivery> deliveries) {
    final map = <String, int>{};
    for (final d in deliveries) {
      for (final line in d.lines) {
        map[line.label] = (map[line.label] ?? 0) + line.quantity;
      }
    }
    return map;
  }

  MonthlyStats monthlyStatsForCustomer(String customerId, DateTime month) {
    final monthDeliveries = deliveriesForCustomer(customerId, month: month);
    final normalCans = monthDeliveries.fold<int>(0, (s, d) => s + d.normalQty);
    final coolCans = monthDeliveries.fold<int>(0, (s, d) => s + d.coolQty);
    final bottleUnits = monthDeliveries.fold<int>(0, (s, d) => s + d.bottleQty);
    final bottlesByLabel = _bottlesByLabelFromDeliveries(monthDeliveries);
    final quantitiesByLabel = _quantitiesByLabelFromDeliveries(monthDeliveries);
    final totalAmount = monthDeliveries.fold<double>(
      0,
      (s, d) => s + d.totalAmount,
    );

    final ledger = customerLedger(customerId);
    final entry = ledgerEntryForMonth(ledger, month);
    final paidAllocated = entry?.allocatedPaid ?? 0;
    final pending = entry?.pending ?? 0;

    return MonthlyStats(
      normalCans: normalCans,
      coolCans: coolCans,
      bottleUnits: bottleUnits,
      bottlesByLabel: bottlesByLabel,
      quantitiesByLabel: quantitiesByLabel,
      totalAmount: totalAmount,
      paidAmount: paidAllocated,
      balance: pending,
    );
  }

  double previousBalanceForMonth(String customerId, DateTime month) =>
      pendingBeforeMonth(customerLedger(customerId), month);

  DashboardStats dashboardStats(DateTime month) {
    final monthDeliveries = _deliveries
        .where((d) => d.date.isSameMonth(month))
        .toList();
    final totalCans = monthDeliveries.fold<int>(
      0,
      (s, d) => s + d.normalQty + d.coolQty + d.bottleQty,
    );
    final totalSales = monthDeliveries.fold<double>(
      0,
      (s, d) => s + d.totalAmount,
    );
    final paidThisMonth = _payments
        .where((p) => p.date.isSameMonth(month))
        .fold<double>(0, (s, p) => s + p.amount);

    var pending = 0.0;
    for (final c in _customers) {
      final stats = monthlyStatsForCustomer(c.id, month);
      pending += stats.balance;
    }

    return DashboardStats(
      totalDeliveries: monthDeliveries.length,
      totalCans: totalCans,
      totalSales: totalSales,
      activeCustomers: _customers.length,
      paidThisMonth: paidThisMonth,
      pendingAmount: pending,
    );
  }

  /// Admin home: prioritized attention items (one per customer, highest urgency wins).
  List<DashboardActionItem> dashboardActionItems({int limit = 5}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final month = DateTime(now.year, now.month);
    final best = <String, DashboardActionItem>{};

    void consider(DashboardActionItem item) {
      final existing = best[item.customerId];
      if (existing == null || item.priority < existing.priority) {
        best[item.customerId] = item;
      }
    }

    for (final c in _customers) {
      final monthStats = monthlyStatsForCustomer(c.id, month);
      final totalBal = customerBalance(c.id);
      final prior = previousBalanceForMonth(c.id, month);
      final lastPay = lastPayment(c.id);
      final daysSincePay = lastPay == null
          ? null
          : today
                .difference(
                  DateTime(
                    lastPay.date.year,
                    lastPay.date.month,
                    lastPay.date.day,
                  ),
                )
                .inDays;

      if (prior > 0 && monthStats.balance > 0) {
        consider(
          DashboardActionItem(
            customerId: c.id,
            customerName: c.name,
            kind: DashboardActionKind.overdue,
            subtitle:
                '${CurrencyUtils.format(totalBal)} overdue · prior month due',
            priority: 0,
          ),
        );
      }

      if (monthStats.balance > 0 && totalBal > 0) {
        final payHint = daysSincePay != null && daysSincePay > 0
            ? ' · last paid $daysSincePay days ago'
            : '';
        consider(
          DashboardActionItem(
            customerId: c.id,
            customerName: c.name,
            kind: DashboardActionKind.pendingPayment,
            subtitle:
                '${CurrencyUtils.format(monthStats.balance)} pending$payHint',
            priority: 1,
          ),
        );
      }

      final deliveredToday = _deliveries.any((d) {
        if (d.customerId != c.id) return false;
        final dDay = DateTime(d.date.year, d.date.month, d.date.day);
        return dDay == today;
      });

      final activeThisMonth = monthStats.normalCans + monthStats.coolCans > 0;
      if (activeThisMonth && !deliveredToday) {
        consider(
          DashboardActionItem(
            customerId: c.id,
            customerName: c.name,
            kind: DashboardActionKind.noDeliveryToday,
            subtitle: 'No delivery logged today',
            priority: 2,
          ),
        );
      }

      final customerDeliveries = deliveriesForCustomer(c.id);
      if (customerDeliveries.isNotEmpty) {
        final lastDay = DateTime(
          customerDeliveries.first.date.year,
          customerDeliveries.first.date.month,
          customerDeliveries.first.date.day,
        );
        final gap = today.difference(lastDay).inDays;
        if (gap >= 7) {
          consider(
            DashboardActionItem(
              customerId: c.id,
              customerName: c.name,
              kind: DashboardActionKind.inactive,
              subtitle: 'No delivery in $gap days',
              priority: 3,
            ),
          );
        }
      }
    }

    final list = best.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return list.take(limit).toList();
  }

  static int compareDeliveriesNewestFirst(Delivery a, Delivery b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.createdAt.compareTo(a.createdAt);
  }

  List<Delivery> deliveriesNewestFirst({int? limit}) {
    final list = List<Delivery>.from(_deliveries)
      ..sort(compareDeliveriesNewestFirst);
    if (limit != null) return list.take(limit).toList();
    return list;
  }

  List<Delivery> recentDeliveries({int limit = 8}) {
    return deliveriesNewestFirst(limit: limit);
  }

  List<Delivery> deliveriesInRange(DateTime start, DateTime end) {
    return _deliveries
        .where(
          (d) =>
              !d.date.isBefore(start) &&
              !d.date.isAfter(end.add(const Duration(days: 1))),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Payment> paymentsInRange(DateTime start, DateTime end) {
    return _payments
        .where(
          (p) =>
              !p.date.isBefore(start) &&
              !p.date.isAfter(end.add(const Duration(days: 1))),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double paymentsTotalInRange(DateTime start, DateTime end) {
    return paymentsInRange(start, end).fold<double>(0, (s, p) => s + p.amount);
  }

  int activeCustomersInRange(DateTime start, DateTime end) {
    return deliveriesInRange(
      start,
      end,
    ).map((d) => d.customerId).toSet().length;
  }

  Map<DateTime, ({int normal, int cool})> dailyCanTotals(
    DateTime start,
    DateTime end,
  ) {
    final map = <DateTime, ({int normal, int cool})>{};
    for (final d in deliveriesInRange(start, end)) {
      final key = DateTime(d.date.year, d.date.month, d.date.day);
      final existing = map[key] ?? (normal: 0, cool: 0);
      map[key] = (
        normal: existing.normal + d.normalQty,
        cool: existing.cool + d.coolQty,
      );
    }
    return map;
  }

  /// Default pricing for a new customer — shop rates for all active products.
  List<CustomerProductPrice> defaultCustomerPricing() {
    final list = <CustomerProductPrice>[
      CustomerProductPrice(
        productId: CustomerPricingKeys.canProductId,
        variantId: CustomerPricingKeys.normalVariantId,
        unitPrice: settings.normalPrice,
      ),
      CustomerProductPrice(
        productId: CustomerPricingKeys.canProductId,
        variantId: CustomerPricingKeys.coolVariantId,
        unitPrice: settings.coolPrice,
      ),
    ];
    for (final product in _products) {
      if (!product.isActive) continue;
      for (final variant in product.variants) {
        list.add(
          CustomerProductPrice(
            productId: product.id,
            variantId: variant.id,
            unitPrice: variant.price,
            enabled: product.category == ProductCategory.bottle,
          ),
        );
      }
    }
    return list;
  }

  double customerUnitPrice(
    Customer customer, {
    required String productId,
    required String variantId,
  }) {
    final entry = customer.priceEntry(productId, variantId);
    if (entry != null) return entry.unitPrice;

    if (productId == CustomerPricingKeys.canProductId) {
      if (variantId == CustomerPricingKeys.normalVariantId) {
        return settings.normalPrice;
      }
      if (variantId == CustomerPricingKeys.coolVariantId) {
        return settings.coolPrice;
      }
    }

    final product = productById(productId);
    if (product == null) return 0;
    for (final v in product.variants) {
      if (v.id == variantId) return v.price;
    }
    return 0;
  }

  bool customerVariantEnabled(
    Customer customer, {
    required String productId,
    required String variantId,
  }) {
    final entry = customer.priceEntry(productId, variantId);
    if (entry != null) return entry.enabled;
    return true;
  }

  /// Bottle catalog filtered to variants this customer is set up to buy.
  List<Product> bottleCatalogForCustomer(Customer customer) {
    return bottleCatalog
        .map((product) {
          final enabledVariants = product.variants
              .where(
                (v) => customerVariantEnabled(
                  customer,
                  productId: product.id,
                  variantId: v.id,
                ),
              )
              .toList();
          if (enabledVariants.isEmpty) return null;
          return product.copyWith(variants: enabledVariants);
        })
        .whereType<Product>()
        .toList();
  }

  bool customerUsesNormalCans(Customer customer) => customerVariantEnabled(
    customer,
    productId: CustomerPricingKeys.canProductId,
    variantId: CustomerPricingKeys.normalVariantId,
  );

  bool customerUsesCoolCans(Customer customer) => customerVariantEnabled(
    customer,
    productId: CustomerPricingKeys.canProductId,
    variantId: CustomerPricingKeys.coolVariantId,
  );

  Customer addCustomer({
    required String name,
    required String phone,
    required String address,
    String email = '',
    String place = '',
    CustomerBillingMode billingMode = CustomerBillingMode.monthlyContract,
    List<CustomerProductPrice>? productPrices,
  }) {
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      address: address,
      email: email,
      place: place,
      billingMode: billingMode,
      productPrices: productPrices ?? defaultCustomerPricing(),
    );
    _customers.insert(0, customer);
    _linkCustomerToShop(customer.id, defaultShopId);
    notifyListeners();

    if (useBackend) {
      _apiService.createCustomer({
        'name': name, 'phone': phone, 'address': address,
        'email': email, 'place': place,
        'billingMode': billingMode == CustomerBillingMode.monthlyContract ? 'monthly_contract' : 'on_demand',
      }).then((_) {}).catchError((Object e) { debugPrint('createCustomer API error: $e'); });
    }

    return customer;
  }

  void updateCustomer(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
      notifyListeners();

      if (useBackend) {
        _apiService.updateCustomer(customer.id, {
          'name': customer.name, 'phone': customer.phone,
          'address': customer.address, 'email': customer.email, 'place': customer.place,
        }).then((_) {}).catchError((Object e) { debugPrint('updateCustomer API error: $e'); });
      }
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    _customerShopIds.remove(id);

    if (useBackend) {
      _apiService.deleteCustomer(id)
          .then((_) {}).catchError((Object e) { debugPrint('deleteCustomer API error: $e'); });
    }
    _deliveries.removeWhere((d) => d.customerId == id);
    _payments.removeWhere((p) => p.customerId == id);
    _orders.removeWhere((o) => o.customerId == id);
    notifyListeners();
  }

  int get pendingOrderCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  List<CustomerOrder> ordersNewestFirst() {
    final list = List<CustomerOrder>.from(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  CustomerOrder? orderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CustomerOrder> ordersForAppUser(String appUserId) {
    final profile = customerProfileByUserId(appUserId);
    final crmId = profile?.linkedCrmCustomerId;
    if (crmId == null) return const [];
    return _orders
        .where((o) => o.customerId == crmId || o.placedByAppUserId == appUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static String? _mergeOrderNotes(String? note, String? productSummary) {
    final parts = <String>[];
    if (note != null && note.trim().isNotEmpty) parts.add(note.trim());
    if (productSummary != null && productSummary.trim().isNotEmpty) {
      parts.add(productSummary.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  /// Listed products for customer ordering (active catalog).
  List<Product> catalogProducts() =>
      _products.where((p) => p.isActive).toList();

  /// Ensures CRM row exists for app user, then creates a pending order.
  CustomerOrder placeAppOrder({
    required String shopId,
    required String appUserId,
    required int normalQty,
    required int coolQty,
    String? customerNote,
    String? productSummary,
  }) {
    final hasCans = normalQty + coolQty > 0;
    final hasProducts =
        productSummary != null && productSummary.trim().isNotEmpty;
    if (!hasCans && !hasProducts) {
      throw ArgumentError('Add at least one item to order');
    }
    final shop = shopById(shopId);
    if (shop == null || !shop.isVisibleToCustomers) {
      throw StateError('This shop does not offer home delivery right now');
    }
    final profile = customerProfileByUserId(appUserId);
    if (profile == null || !profile.onboardingComplete) {
      throw StateError('Complete your delivery address first');
    }
    if (!canAppUserAccessShop(appUserId, shopId, phone: profile.phone)) {
      throw StateError('This water plant is not linked to your account');
    }

    final crmId = _linkedCrmCustomerIdForOrder(
      appUserId: appUserId,
      profile: profile,
      shopId: shopId,
    );
    _customerShopIds.putIfAbsent(crmId, () => shopId);
    final order = CustomerOrder(
      id: _uuid.v4(),
      customerId: crmId,
      shopId: shopId,
      placedByAppUserId: appUserId,
      normalQty: normalQty,
      coolQty: coolQty,
      status: OrderStatus.pending,
      customerNote: _mergeOrderNotes(customerNote, productSummary),
    );
    _orders.add(order);
    notifyListeners();

    if (useBackend) {
      _apiService.placeOrder({
        'shopId': shopId,
        'customerId': crmId,
        'normalQty': normalQty,
        'coolQty': coolQty,
        if (order.customerNote != null) 'customerNote': order.customerNote,
      }).then((_) {}).catchError((Object e) { debugPrint('placeOrder API error: $e'); });
    }

    return order;
  }

  String _linkedCrmCustomerIdForOrder({
    required String appUserId,
    required CustomerAppProfile profile,
    required String shopId,
  }) {
    for (final customer in linkedCrmCustomersForAppUser(
      appUserId,
      phone: profile.phone,
    )) {
      if (shopIdForCustomer(customer.id) == shopId) {
        _customerProfiles[appUserId] = profile.copyWith(
          linkedCrmCustomerId: customer.id,
        );
        return customer.id;
      }
    }
    throw StateError('Ask your water plant admin to add your phone number');
  }

  void respondToOrder(
    String orderId,
    OrderStatus status, {
    String? adminResponse,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) return;
    final order = _orders[index];
    if (order.status != OrderStatus.pending) return;
    order.status = status;
    order.adminResponse = adminResponse;
    order.respondedAt = DateTime.now();
    notifyListeners();

    if (useBackend) {
      if (status == OrderStatus.accepted) {
        _apiService.acceptOrder(orderId, adminNote: adminResponse)
            .then((_) {}).catchError((Object e) { debugPrint('acceptOrder API error: $e'); });
      } else if (status == OrderStatus.rejected) {
        _apiService.rejectOrder(orderId, adminNote: adminResponse)
            .then((_) {}).catchError((Object e) { debugPrint('rejectOrder API error: $e'); });
      }
    }
  }

  Driver? driverById(String? id) {
    if (id == null) return null;
    try {
      return _drivers.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Driver addDriver({
    required String name,
    required String phone,
    required String email,
  }) {
    final driver = Driver(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
    _drivers.add(driver);
    _linkDriverToShop(driver.id, defaultShopId);
    notifyListeners();

    if (useBackend) {
      _apiService.createDriver({
        'name': driver.name,
        'phone': driver.phone,
        'email': driver.email,
      }).then((_) {}).catchError((Object e) { debugPrint('createDriver API error: $e'); });
    }

    return driver;
  }

  void setDriverActive(String driverId, bool active) {
    final i = _drivers.indexWhere((d) => d.id == driverId);
    if (i < 0) return;
    _drivers[i] = _drivers[i].copyWith(active: active);
    notifyListeners();

    if (useBackend) {
      _apiService.setDriverActive(driverId, active)
          .then((_) {}).catchError((Object e) { debugPrint('setDriverActive API error: $e'); });
    }
  }

  List<Delivery> deliveriesOnDate(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _deliveries
        .where((d) => !d.date.isBefore(start) && d.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int cansDeliveredOnDate(DateTime day) {
    return deliveriesOnDate(
      day,
    ).fold<int>(0, (s, d) => s + d.normalQty + d.coolQty);
  }

  List<Delivery> deliveriesOnDateForDriver(DateTime day, String? driverId) {
    final shop = shopForDriver(driverId);
    if (shop == null) return const [];
    return deliveriesOnDate(
      day,
    ).where((d) => shopIdForCustomer(d.customerId) == shop.id).toList();
  }

  int cansDeliveredOnDateForDriver(DateTime day, String? driverId) {
    return deliveriesOnDateForDriver(
      day,
      driverId,
    ).fold<int>(0, (s, d) => s + d.normalQty + d.coolQty);
  }

  /// Accepted by admin, not yet delivered today — shown to driver only.
  List<CustomerOrder> driverAcceptedOrders({String? driverId}) {
    var list = _orders
        .where(
          (o) =>
              o.status == OrderStatus.accepted &&
              !hasDeliveryToday(o.customerId),
        )
        .toList();
    if (driverId != null) {
      final shop = shopForDriver(driverId);
      list = shop == null
          ? <CustomerOrder>[]
          : list
                .where((o) => shopIdForCustomer(o.customerId) == shop.id)
                .toList();
    }
    return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CustomerOrder? acceptedOrderForCustomer(
    String customerId, {
    String? driverId,
  }) {
    try {
      return driverAcceptedOrders(
        driverId: driverId,
      ).firstWhere((o) => o.customerId == customerId);
    } catch (_) {
      return null;
    }
  }

  int get driverAcceptedOrderCount => driverAcceptedOrders().length;

  Delivery addDelivery({
    required String customerId,
    required DateTime date,
    int normalQty = 0,
    int coolQty = 0,
    List<BottleDeliveryInput> bottles = const [],
    String? driverId,
  }) {
    final customer = customerById(customerId);
    final lines = <DeliveryLineItem>[];
    if (normalQty > 0) {
      final unitPrice = customer != null
          ? customerUnitPrice(
              customer,
              productId: CustomerPricingKeys.canProductId,
              variantId: CustomerPricingKeys.normalVariantId,
            )
          : settings.normalPrice;
      lines.add(
        DeliveryLineItem(
          kind: DeliveryItemKind.normalCan,
          label: 'Normal Can',
          quantity: normalQty,
          unitPrice: unitPrice,
        ),
      );
    }
    if (coolQty > 0) {
      final unitPrice = customer != null
          ? customerUnitPrice(
              customer,
              productId: CustomerPricingKeys.canProductId,
              variantId: CustomerPricingKeys.coolVariantId,
            )
          : settings.coolPrice;
      lines.add(
        DeliveryLineItem(
          kind: DeliveryItemKind.coolCan,
          label: 'Cool Can',
          quantity: coolQty,
          unitPrice: unitPrice,
        ),
      );
    }
    for (final b in bottles) {
      if (b.quantity <= 0) continue;
      lines.add(
        DeliveryLineItem(
          kind: DeliveryItemKind.bottle,
          label: b.label,
          quantity: b.quantity,
          unitPrice: b.unitPrice,
          productId: b.productId,
        ),
      );
    }
    if (lines.isEmpty) {
      throw ArgumentError('At least one item is required for a delivery');
    }

    final delivery = Delivery(
      id: _uuid.v4(),
      customerId: customerId,
      date: date,
      lines: lines,
      driverId: driverId,
    );
    _deliveries.insert(0, delivery);
    notifyListeners();

    if (useBackend) {
      _apiService.createDelivery({
        'customerId': customerId,
        'deliveryDate': date.toIso8601String(),
        'normalQty': normalQty,
        'coolQty': coolQty,
        if (driverId != null) 'driverId': driverId,
        'lines': lines.map((l) => {
          'kind': l.kind.name,
          'label': l.label,
          'quantity': l.quantity,
          'unitPrice': l.unitPrice,
          if (l.productId != null) 'productId': l.productId,
        }).toList(),
        'totalAmount': delivery.totalAmount,
        'deliveryType': 'manual_delivery',
      }).then((_) {}).catchError((Object e) { debugPrint('createDelivery API error: $e'); });
    }

    return delivery;
  }

  List<Product> get bottleCatalog =>
      _products.where((p) => p.category == ProductCategory.bottle).toList();

  Payment addPayment({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? notes,
  }) {
    final payment = Payment(
      id: _uuid.v4(),
      customerId: customerId,
      date: date,
      amount: amount,
      method: method,
      notes: notes,
    );
    _payments.insert(0, payment);
    notifyListeners();

    if (useBackend) {
      _apiService.recordCashCollection({
        'customerId': customerId,
        'amount': amount,
        'collectionType': 'delivery_cash',
        'collectionDate': date.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }).then((_) {}).catchError((Object e) { debugPrint('recordCashCollection API error: $e'); });
    }

    return payment;
  }

  void _syncShopFromSettings() {
    final shop = Shop.fromBusinessSettings(settings, id: defaultShopId);
    final idx = _shops.indexWhere((s) => s.id == defaultShopId);
    if (idx >= 0) {
      _shops[idx] = shop;
    } else {
      _shops.add(shop);
    }
  }

  List<Promotion> get promotions => List.unmodifiable(_promotions);

  void updateSettings(BusinessSettings newSettings) {
    settings = newSettings;
    _syncShopFromSettings();
    final canProduct = productById('p2');
    if (canProduct != null) {
      final i = _products.indexWhere((p) => p.id == 'p2');
      _products[i] = canProduct.copyWith(
        variants: [
          ProductVariant(
            id: 'p2-v1',
            label: 'Normal Can',
            price: newSettings.normalPrice,
          ),
          ProductVariant(
            id: 'p2-v2',
            label: 'Cool Can',
            price: newSettings.coolPrice,
            isCool: true,
          ),
        ],
      );
    }
    notifyListeners();

    if (useBackend) {
      _apiService.updateShop({
        'shopName': newSettings.businessName,
        'address': newSettings.address,
        'phone': newSettings.phone,
        'email': newSettings.email,
        'normalCanPrice': newSettings.normalPrice,
        'coolCanPrice': newSettings.coolPrice,
        'homeDeliveryAvailable': newSettings.homeDeliveryAvailable,
        if (newSettings.shopLatitude != null) 'latitude': newSettings.shopLatitude,
        if (newSettings.shopLongitude != null) 'longitude': newSettings.shopLongitude,
      }).then((_) {}).catchError((Object e) { debugPrint('updateShop API error: $e'); });
    }
  }

  void _seedProducts() {
    // Products start empty — admin adds their own catalog.
    _products.clear();
  }

  Product? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<Product> addProduct({
    required String name,
    String? description,
    required ProductCategory category,
    required String variantLabel,
    required double price,
    bool isCool = false,
    String? imageSourcePath,
  }) async {
    String? savedImagePath;
    if (imageSourcePath != null && imageSourcePath.isNotEmpty) {
      savedImagePath = await ProductImageService.persistFromFile(
        imageSourcePath,
      );
    }

    final product = Product(
      id: _uuid.v4(),
      name: name.trim(),
      description: (description?.trim().isEmpty ?? true)
          ? _defaultProductDescription(category, variantLabel, isCool: isCool)
          : description!.trim(),
      category: category,
      variants: [
        ProductVariant(
          id: _uuid.v4(),
          label: variantLabel.trim(),
          price: price,
          isCool: isCool,
        ),
      ],
      localImagePath: savedImagePath,
    );
    _products.insert(0, product);
    notifyListeners();

    if (useBackend) {
      final firstVariant = product.variants.isNotEmpty ? product.variants.first : null;
      _apiService.createProduct({
        'name': product.name,
        'description': product.description,
        'category': product.category.name,
        'variantLabel': firstVariant?.label ?? product.name,
        'price': firstVariant?.price ?? 0,
        'isCool': firstVariant?.isCool ?? false,
      }).then((_) {}).catchError((Object e) { debugPrint('createProduct API error: $e'); });
    }

    return product;
  }

  String _defaultProductDescription(
    ProductCategory category,
    String label, {
    bool isCool = false,
  }) {
    return switch (category) {
      ProductCategory.bottle => 'RO water bottle — $label',
      ProductCategory.can =>
        isCool ? 'Chilled 20L RO water can' : '20L RO water can — $label',
    };
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();

    if (useBackend) {
      _apiService.deleteProduct(id)
          .then((_) {}).catchError((Object e) { debugPrint('deleteProduct API error: $e'); });
    }
  }

  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return List<Product>.from(_products);
    final q = query.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.category.label.toLowerCase().contains(q) ||
              p.variants.any((v) => v.label.toLowerCase().contains(q)),
        )
        .toList();
  }

  /// Re-fetch all data from the backend (used for pull-to-refresh).
  Future<void> refreshFromBackend() => loadFromBackend();

  void resetMockData() {
    _customers.clear();
    _deliveries.clear();
    _payments.clear();
    _orders.clear();
    _products.clear();
    _drivers.clear();
    _shops.clear();
    _promotions.clear();
    _customerShopIds.clear();
    _driverShopIds.clear();
    _customerProfiles.clear();
    _routeNotes.clear();
    _todaysRouteIds = [];
    _seedMockData();
    notifyListeners();
  }

  /// Load all data from the backend API (called when useBackend = true).
  Future<void> loadFromBackend() async {
    if (!useBackend) return;
    try {
      // Load shop settings
      final shopData = await _apiService.getShop();
      final shopJson = shopData['shop'] as Map<String, dynamic>;
      settings = settings.copyWith(
        businessName: shopJson['shopName'] as String? ?? settings.businessName,
        address: shopJson['address'] as String? ?? settings.address,
        phone: shopJson['phone'] as String? ?? settings.phone,
        email: shopJson['email'] as String? ?? settings.email,
        normalPrice: (shopJson['normalCanPrice'] as num?)?.toDouble() ?? settings.normalPrice,
        coolPrice: (shopJson['coolCanPrice'] as num?)?.toDouble() ?? settings.coolPrice,
        homeDeliveryAvailable: shopJson['homeDeliveryAvailable'] as bool? ?? settings.homeDeliveryAvailable,
        shopLatitude: (shopJson['latitude'] as num?)?.toDouble(),
        shopLongitude: (shopJson['longitude'] as num?)?.toDouble(),
      );

      // Load customers
      final customersData = await _apiService.listCustomers();
      _customers.clear();
      for (final c in (customersData['customers'] as List<dynamic>? ?? [])) {
        final map = c as Map<String, dynamic>;
        final customer = _customerFromJson(map);
        _customers.add(customer);
        _customerShopIds[customer.id] = map['shopId'] as String? ?? defaultShopId;
      }

      // Load drivers
      final driversData = await _apiService.listDrivers();
      _drivers.clear();
      for (final d in (driversData['drivers'] as List<dynamic>? ?? [])) {
        final map = d as Map<String, dynamic>;
        final driver = _driverFromJson(map);
        _drivers.add(driver);
        _driverShopIds[driver.id] = map['shopId'] as String? ?? defaultShopId;
      }

      // Load products
      final productsData = await _apiService.listProducts();
      _products.clear();
      for (final p in (productsData['products'] as List<dynamic>? ?? [])) {
        final map = p as Map<String, dynamic>;
        _products.add(_productFromJson(map));
      }

      // Load recent deliveries (last 30 days)
      final endDate = DateTime.now().toIso8601String().split('T')[0];
      final startDate = DateTime.now().subtract(const Duration(days: 60)).toIso8601String().split('T')[0];
      final deliveriesData = await _apiService.listDeliveries(startDate: startDate, endDate: endDate, limit: 200);
      _deliveries.clear();
      for (final d in (deliveriesData['deliveries'] as List<dynamic>? ?? [])) {
        _deliveries.add(_deliveryFromJson(d as Map<String, dynamic>));
      }

      // Load recent orders
      final ordersData = await _apiService.listOrders(limit: 100);
      _orders.clear();
      for (final o in (ordersData['orders'] as List<dynamic>? ?? [])) {
        _orders.add(_orderFromJson(o as Map<String, dynamic>));
      }

      // Load promotions
      final promosData = await _apiService.listPromotions();
      _promotions.clear();
      for (final p in (promosData['promotions'] as List<dynamic>? ?? [])) {
        _promotions.add(_promotionFromJson(p as Map<String, dynamic>));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('loadFromBackend error: $e');
    }
  }

  // ─── JSON → Model converters ───────────────────────────────────────────────

  Customer _customerFromJson(Map<String, dynamic> map) {
    return Customer(
      id: map['customerId'] as String? ?? map['_id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      place: map['place'] as String? ?? '',
      billingMode: map['billingMode'] == 'on_demand'
          ? CustomerBillingMode.monthlyContract
          : CustomerBillingMode.monthlyContract,
      productPrices: ((map['productPrices'] as List<dynamic>?) ?? [])
          .map((e) => CustomerProductPrice(
                productId: (e as Map<String, dynamic>)['productId'] as String,
                variantId: e['variantId'] as String,
                unitPrice: (e['unitPrice'] as num).toDouble(),
                enabled: e['enabled'] as bool? ?? true,
              ))
          .toList(),
    );
  }

  Driver _driverFromJson(Map<String, dynamic> map) {
    return Driver(
      id: map['driverId'] as String? ?? map['_id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      active: map['active'] as bool? ?? true,
    );
  }

  Product _productFromJson(Map<String, dynamic> map) {
    final catStr = map['category'] as String? ?? 'can';
    final category = catStr == 'bottle' ? ProductCategory.bottle : ProductCategory.can;
    final variants = ((map['variants'] as List<dynamic>?) ?? [])
        .map((e) {
          final v = e as Map<String, dynamic>;
          return ProductVariant(
            id: v['variantId'] as String,
            label: v['label'] as String? ?? '',
            price: (v['price'] as num).toDouble(),
            isCool: v['isCool'] as bool? ?? false,
          );
        })
        .toList();
    return Product(
      id: map['productId'] as String? ?? map['_id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: category,
      variants: variants,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Delivery _deliveryFromJson(Map<String, dynamic> map) {
    final lines = ((map['lines'] as List<dynamic>?) ?? []).map((e) {
      final l = e as Map<String, dynamic>;
      final kindStr = l['kind'] as String? ?? 'normalCan';
      final kind = switch (kindStr) {
        'coolCan' => DeliveryItemKind.coolCan,
        'bottle' => DeliveryItemKind.bottle,
        _ => DeliveryItemKind.normalCan,
      };
      return DeliveryLineItem(
        kind: kind,
        label: l['label'] as String? ?? '',
        quantity: (l['quantity'] as num).toInt(),
        unitPrice: (l['unitPrice'] as num).toDouble(),
        productId: l['productId'] as String?,
      );
    }).toList();

    return Delivery(
      id: map['deliveryId'] as String? ?? map['_id'] as String,
      customerId: map['customerId'] as String,
      date: DateTime.parse(map['deliveryDate'] as String),
      lines: lines,
      driverId: map['driverId'] as String?,
    );
  }

  CustomerOrder _orderFromJson(Map<String, dynamic> map) {
    final statusStr = map['orderStatus'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'accepted' => OrderStatus.accepted,
      'rejected' => OrderStatus.rejected,
      _ => OrderStatus.pending,
    };
    return CustomerOrder(
      id: map['orderId'] as String? ?? map['_id'] as String,
      customerId: map['customerId'] as String,
      shopId: map['shopId'] as String?,
      placedByAppUserId: map['appUserId'] as String?,
      normalQty: (map['normalQty'] as num?)?.toInt() ?? 0,
      coolQty: (map['coolQty'] as num?)?.toInt() ?? 0,
      status: status,
      customerNote: map['customerNote'] as String?,
      adminResponse: map['adminNote'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }

  Promotion _promotionFromJson(Map<String, dynamic> map) {
    final mediaTypeStr = map['mediaType'] as String? ?? 'image';
    final mediaType = mediaTypeStr == 'video' ? PromotionMediaType.video : PromotionMediaType.image;
    return Promotion(
      id: map['promotionId'] as String? ?? map['_id'] as String,
      shopId: map['shopId'] as String? ?? '',
      shopName: '',
      headline: map['headline'] as String? ?? '',
      body: map['body'] as String? ?? '',
      mediaType: mediaType,
      badge: map['badge'] as String?,
      ctaLabel: map['ctaLabel'] as String? ?? 'Order now',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }

  String customerActivityLabel(String customerId, DateTime month) {
    final stats = monthlyStatsForCustomer(customerId, month);
    final parts = <String>[];
    if (stats.normalCans > 0) parts.add('${stats.normalCans} normal');
    if (stats.coolCans > 0) parts.add('${stats.coolCans} cool');
    if (stats.bottleUnits > 0) parts.add('${stats.bottleUnits} bottles');
    if (parts.isEmpty) return 'No deliveries this month';
    return '${parts.join(', ')} delivered this month';
  }

  bool customerHasPendingBalance(String customerId) =>
      customerBalance(customerId) > 0;

  List<Customer> searchCustomers(String query) {
    if (query.trim().isEmpty) return List<Customer>.from(_customers);
    final q = query.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.replaceAll(' ', '').contains(q.replaceAll(' ', '')),
        )
        .toList();
  }
}
