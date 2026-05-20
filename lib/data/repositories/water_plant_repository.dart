import 'package:flutter/foundation.dart';
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
import 'package:uuid/uuid.dart';

class WaterPlantRepository extends ChangeNotifier {
  WaterPlantRepository() {
    _seedMockData();
  }

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
              s.phone.replaceAll(RegExp(r'\D'), '').contains(q.replaceAll(RegExp(r'\D'), '')),
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
      return _customers.firstWhere(
        (c) => normalizePhone(c.phone) == digits,
      );
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

  String shopIdForCustomer(String customerId) =>
      _customerShopIds[customerId] ?? defaultShopId;

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

  /// Links app login to admin CRM row when phone matches a contract customer.
  void linkContractCustomerOnLogin({
    required String userId,
    required String phone,
  }) {
    final crm = crmCustomerByPhone(phone);
    if (crm == null || !crm.isMonthlyContract) return;

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
    _seedMarketplaceShops();
    _seedProducts();
    _seedPromotions();

    _drivers.addAll([
      const Driver(
        id: 'driver-1',
        name: 'Rajesh Kumar',
        phone: '+91 91234 56780',
        email: 'driver@srisai.com',
      ),
    ]);

    final abi = Customer(
      id: 'c1',
      name: 'Abi',
      phone: '9632580741',
      billingMode: CustomerBillingMode.monthlyContract,
      email: 'abi@email.com',
      place: 'Hyderabad, Telangana',
      address: 'Hyderabad, Telangana',
      productPrices: [
        const CustomerProductPrice(
          productId: CustomerPricingKeys.canProductId,
          variantId: CustomerPricingKeys.normalVariantId,
          unitPrice: 18,
        ),
        const CustomerProductPrice(
          productId: CustomerPricingKeys.canProductId,
          variantId: CustomerPricingKeys.coolVariantId,
          unitPrice: 28,
        ),
      ],
    );
    final ramesh = Customer(
      id: 'c2',
      name: 'Ramesh Kumar',
      phone: '98850 12345',
      billingMode: CustomerBillingMode.appOnDemand,
      email: 'ramesh.kumar@email.com',
      place: 'Gandhi Nagar, Rajahmundry',
      address: 'Door No: 12-5-8, Gandhi Nagar',
    );
    final lakshmi = Customer(
      id: 'c3',
      name: 'Lakshmi Devi',
      phone: '98765 43210',
      billingMode: CustomerBillingMode.appOnDemand,
      place: 'RTC Colony, Rajahmundry',
      address: 'Plot 45, RTC Colony',
    );
    final suresh = Customer(
      id: 'c4',
      name: 'Suresh Babu',
      phone: '91234 56789',
      billingMode: CustomerBillingMode.appOnDemand,
      place: 'Danavaipeta, Rajahmundry',
      address: 'Flat 302, Sai Residency',
    );

    _customers.addAll([abi, ramesh, lakshmi, suresh]);
    _customerShopIds[abi.id] = defaultShopId;
    _seedAbiMultiShopAccounts(abi);

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    void addCans(String customerId, int day, int normal, int cool, {int hour = 10}) {
      _deliveries.add(
        Delivery.fromLegacyCans(
          id: _uuid.v4(),
          customerId: customerId,
          date: DateTime(thisMonth.year, thisMonth.month, day, hour),
          normalQty: normal,
          coolQty: cool,
          normalUnitPrice: settings.normalPrice,
          coolUnitPrice: settings.coolPrice,
        ),
      );
    }

    void addCansInMonth(
      String customerId,
      DateTime month,
      int day,
      int normal,
      int cool,
    ) {
      _deliveries.add(
        Delivery.fromLegacyCans(
          id: _uuid.v4(),
          customerId: customerId,
          date: DateTime(month.year, month.month, day, 10),
          normalQty: normal,
          coolQty: cool,
          normalUnitPrice: settings.normalPrice,
          coolUnitPrice: settings.coolPrice,
        ),
      );
    }

    // Current month
    addCans('c1', 5, 2, 3);
    addCans('c1', 12, 1, 2);
    addCans('c2', 8, 3, 1);
    addCans('c2', 18, 2, 0);
    addCans('c3', 10, 0, 4);
    addCans('c4', 15, 4, 2);
    addCans('c4', 22, 2, 1);

    // Previous months (mixed paid / pending)
    final prev1 = DateTime(thisMonth.year, thisMonth.month - 1);
    final prev2 = DateTime(thisMonth.year, thisMonth.month - 2);
    addCansInMonth('c1', prev1, 10, 2, 2);
    addCansInMonth('c2', prev1, 14, 3, 1);
    addCansInMonth('c4', prev1, 20, 2, 3);
    addCansInMonth('c1', prev2, 8, 1, 1);
    addCansInMonth('c3', prev2, 16, 2, 2);

    _payments.addAll([
      Payment(
        id: _uuid.v4(),
        customerId: 'c2',
        date: DateTime(thisMonth.year, thisMonth.month, 6),
        amount: 2000,
        method: PaymentMethod.upi,
      ),
      Payment(
        id: _uuid.v4(),
        customerId: 'c4',
        date: DateTime(thisMonth.year, thisMonth.month, 12),
        amount: 500,
        method: PaymentMethod.cash,
        notes: 'Partial payment',
      ),
      Payment(
        id: _uuid.v4(),
        customerId: 'c1',
        date: DateTime(prev1.year, prev1.month, 25),
        amount: 1500,
        method: PaymentMethod.upi,
      ),
    ]);

    _seedDriverDemoData(now, thisMonth);
  }

  /// Bulk demo user (Abi) buys from 4 shops — separate CRM + deliveries per shop.
  void _seedAbiMultiShopAccounts(Customer abiTemplate) {
    final pairs = [
      ('c1-shop2', 'shop-2', 22.0, 32.0),
      ('c1-shop3', 'shop-3', 19.0, 29.0),
      ('c1-shop4', 'shop-4', 20.0, 30.0),
    ];

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final prev1 = DateTime(thisMonth.year, thisMonth.month - 1);

    void addCansShop(
      String customerId,
      String shopId,
      DateTime month,
      int day,
      int normal,
      int cool,
    ) {
      final shop = shopById(shopId);
      if (shop == null) return;
      _deliveries.add(
        Delivery.fromLegacyCans(
          id: _uuid.v4(),
          customerId: customerId,
          date: DateTime(month.year, month.month, day, 10),
          normalQty: normal,
          coolQty: cool,
          normalUnitPrice: shop.normalPrice,
          coolUnitPrice: shop.coolPrice,
        ),
      );
    }

    for (final (id, shopId, _, _) in pairs) {
      if (_customers.any((c) => c.id == id)) continue;
      _customerShopIds[id] = shopId;
      _customers.add(
        Customer(
          id: id,
          name: abiTemplate.name,
          phone: abiTemplate.phone,
          billingMode: CustomerBillingMode.monthlyContract,
          email: abiTemplate.email,
          place: abiTemplate.place,
          address: abiTemplate.address,
          productPrices: abiTemplate.productPrices,
        ),
      );
      // Current month — different cadence per shop
      addCansShop(id, shopId, thisMonth, 3 + id.hashCode % 5, 2, 1);
      addCansShop(id, shopId, thisMonth, 10 + id.hashCode % 4, 3, 2);
      addCansShop(id, shopId, thisMonth, 18 + id.hashCode % 3, 1, 0);
      // Previous month
      addCansShop(id, shopId, prev1, 8, 4, 2);
      addCansShop(id, shopId, prev1, 20, 2, 1);
    }

    // Partial payment at one shop; prev month paid at main shop already seeded
    _payments.add(
      Payment(
        id: _uuid.v4(),
        customerId: 'c1-shop2',
        date: DateTime(thisMonth.year, thisMonth.month, 8),
        amount: 400,
        method: PaymentMethod.upi,
        notes: 'Partial — Aqua Pure',
      ),
    );
    _payments.add(
      Payment(
        id: _uuid.v4(),
        customerId: 'c1-shop4',
        date: DateTime(prev1.year, prev1.month, 28),
        amount: 900,
        method: PaymentMethod.cash,
        notes: 'Crystal Clear — full month',
      ),
    );
  }

  void _seedDriverDemoData(DateTime now, DateTime thisMonth) {
    _customers.addAll([
      Customer(
        id: 'c5',
        name: 'Priya Sharma',
        phone: '99887 76655',
        email: 'priya@email.com',
        place: 'Korukonda Road',
        address: 'H.No 8-2-120, Korukonda Road',
      ),
      Customer(
        id: 'c6',
        name: 'Venkatesh Reddy',
        phone: '98480 11223',
        place: 'Morampudi',
        address: 'Near Temple, Morampudi',
      ),
      Customer(
        id: 'c7',
        name: 'Anitha Stores',
        phone: '95501 33445',
        email: 'anitha.stores@email.com',
        place: 'Main Road',
        address: 'Shop 12, Main Road Complex',
      ),
    ]);

    _routeNotes.addAll({
      'c2': 'Weekly route — usually 3 normal + 1 cool',
      'c3': 'Apartment — ask security for entry',
      'c5': 'New customer — confirm cans every visit',
      'c6': 'Call 5 min before arrival',
      'c7': 'Shop — back entrance for cans',
    });

    _todaysRouteIds = ['c2', 'c3', 'c5', 'c6', 'c7'];

    final today = DateTime(now.year, now.month, now.day, 9, 30);
    _deliveries.add(
      Delivery.fromLegacyCans(
        id: _uuid.v4(),
        customerId: 'c2',
        date: today,
        normalQty: 2,
        coolQty: 0,
        normalUnitPrice: settings.normalPrice,
        coolUnitPrice: settings.coolPrice,
        driverId: 'driver-1',
      ),
    );

    _orders.addAll([
      CustomerOrder(
        id: 'ord-1',
        customerId: 'c3',
        normalQty: 2,
        coolQty: 2,
        status: OrderStatus.accepted,
        customerNote: 'Deliver before 12 noon',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      CustomerOrder(
        id: 'ord-2',
        customerId: 'c5',
        normalQty: 1,
        coolQty: 1,
        status: OrderStatus.pending,
        customerNote: 'First order this week',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      CustomerOrder(
        id: 'ord-3',
        customerId: 'c6',
        normalQty: 4,
        coolQty: 0,
        status: OrderStatus.accepted,
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      CustomerOrder(
        id: 'ord-4',
        customerId: 'c7',
        normalQty: 6,
        coolQty: 2,
        status: OrderStatus.accepted,
        customerNote: 'Shop opens 8 AM',
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
    ]);
  }

  List<Customer> get todaysRouteCustomers {
    return _todaysRouteIds
        .map(customerById)
        .whereType<Customer>()
        .toList();
  }

  String? routeNoteForCustomer(String customerId) => _routeNotes[customerId];

  bool hasDeliveryToday(String customerId) {
    final today = DateTime.now();
    return deliveriesOnDate(today).any((d) => d.customerId == customerId);
  }

  Customer? customerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  PaymentAllocationResult _allocationFor(String customerId) {
    final deliveries =
        _deliveries.where((d) => d.customerId == customerId).toList();
    final payments = _payments.where((p) => p.customerId == customerId).toList();
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
    return (_deliveryTotal(customerId) - _paymentTotal(customerId))
        .clamp(0, double.infinity);
  }

  /// Extra paid after all monthly bills are cleared — auto-used on next delivery.
  double customerAdvanceCredit(String customerId) {
    final fromFifo = _allocationFor(customerId).advanceCredit;
    if (fromFifo > 0) return fromFifo;
    return (_paymentTotal(customerId) - _deliveryTotal(customerId))
        .clamp(0, double.infinity);
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
    final appliedToDue =
        paymentAmount < pendingBefore ? paymentAmount : pendingBefore;
    final advance = paymentAmount - appliedToDue;
    final pendingAfter =
        (pendingBefore - appliedToDue).clamp(0.0, double.infinity).toDouble();
    return PaymentAllocationPreview(
      pendingBefore: pendingBefore,
      appliedToDue: appliedToDue,
      advanceCredit: advance,
      pendingAfter: pendingAfter,
    );
  }

  List<Delivery> deliveriesForCustomer(
    String customerId, {
    DateTime? month,
  }) {
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
    return paymentsForCustomer(customerId, month: month)
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  Map<String, int> _bottlesByLabelFromDeliveries(List<Delivery> deliveries) {
    final map = <String, int>{};
    for (final d in deliveries) {
      for (final line in d.lines.where((l) => l.kind == DeliveryItemKind.bottle)) {
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
    final normalCans =
        monthDeliveries.fold<int>(0, (s, d) => s + d.normalQty);
    final coolCans = monthDeliveries.fold<int>(0, (s, d) => s + d.coolQty);
    final bottleUnits =
        monthDeliveries.fold<int>(0, (s, d) => s + d.bottleQty);
    final bottlesByLabel = _bottlesByLabelFromDeliveries(monthDeliveries);
    final quantitiesByLabel = _quantitiesByLabelFromDeliveries(monthDeliveries);
    final totalAmount =
        monthDeliveries.fold<double>(0, (s, d) => s + d.totalAmount);

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
    final monthDeliveries =
        _deliveries.where((d) => d.date.isSameMonth(month)).toList();
    final totalCans = monthDeliveries.fold<int>(
      0,
      (s, d) => s + d.normalQty + d.coolQty + d.bottleQty,
    );
    final totalSales =
        monthDeliveries.fold<double>(0, (s, d) => s + d.totalAmount);
    final activeIds = monthDeliveries.map((d) => d.customerId).toSet();
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
              .difference(DateTime(lastPay.date.year, lastPay.date.month, lastPay.date.day))
              .inDays;

      if (prior > 0 && monthStats.balance > 0) {
        consider(
          DashboardActionItem(
            customerId: c.id,
            customerName: c.name,
            kind: DashboardActionKind.overdue,
            subtitle: '${CurrencyUtils.format(totalBal)} overdue · prior month due',
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
            subtitle: '${CurrencyUtils.format(monthStats.balance)} pending$payHint',
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

    final list = best.values.toList()..sort((a, b) => a.priority.compareTo(b.priority));
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
    return deliveriesInRange(start, end).map((d) => d.customerId).toSet().length;
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
    List<CustomerProductPrice>? productPrices,
  }) {
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      address: address,
      email: email,
      place: place,
      productPrices: productPrices ?? defaultCustomerPricing(),
    );
    _customers.insert(0, customer);
    notifyListeners();
    return customer;
  }

  void updateCustomer(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
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

    final crmId = _ensureAppCrmCustomer(appUserId, profile);
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
    return order;
  }

  String _ensureAppCrmCustomer(String appUserId, CustomerAppProfile profile) {
    if (profile.linkedCrmCustomerId != null) {
      final existing = customerById(profile.linkedCrmCustomerId!);
      if (existing != null) {
        _customers[_customers.indexWhere((c) => c.id == existing.id)] =
            existing.copyWith(
          name: profile.name,
          phone: profile.phone,
          address: profile.address,
          email: profile.email,
          place: profile.place,
        );
        return existing.id;
      }
    }

    final appIdx = _customers.indexWhere((c) => c.appUserId == appUserId);
    if (appIdx >= 0) {
      _customerProfiles[appUserId] = profile.copyWith(
        linkedCrmCustomerId: _customers[appIdx].id,
      );
      return _customers[appIdx].id;
    }

    final customer = Customer(
      id: _uuid.v4(),
      name: profile.name,
      phone: profile.phone,
      address: profile.address,
      email: profile.email,
      place: profile.place,
      paymentFrequency: 'Per order',
      billingMode: CustomerBillingMode.appOnDemand,
      appUserId: appUserId,
    );
    _customers.add(customer);
    _customerProfiles[appUserId] = profile.copyWith(
      linkedCrmCustomerId: customer.id,
    );
    return customer.id;
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
    notifyListeners();
    return driver;
  }

  void setDriverActive(String driverId, bool active) {
    final i = _drivers.indexWhere((d) => d.id == driverId);
    if (i < 0) return;
    _drivers[i] = _drivers[i].copyWith(active: active);
    notifyListeners();
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
    return deliveriesOnDate(day).fold<int>(0, (s, d) => s + d.normalQty + d.coolQty);
  }

  /// Accepted by admin, not yet delivered today — shown to driver only.
  List<CustomerOrder> driverAcceptedOrders() {
    return _orders
        .where(
          (o) =>
              o.status == OrderStatus.accepted &&
              !hasDeliveryToday(o.customerId),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CustomerOrder? acceptedOrderForCustomer(String customerId) {
    try {
      return driverAcceptedOrders().firstWhere((o) => o.customerId == customerId);
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

  void _seedMarketplaceShops() {
    if (_shops.length > 1) return;
    _shops.addAll([
      const Shop(
        id: 'shop-2',
        name: 'Aqua Pure RO Center',
        address: 'MG Road, Rajahmundry, Andhra Pradesh',
        place: 'MG Road',
        phone: '+91 91234 00001',
        latitude: 16.9850,
        longitude: 81.7820,
        subscriptionStatus: ShopSubscriptionStatus.active,
        homeDeliveryAvailable: true,
        normalPrice: 22,
        coolPrice: 32,
        tagline: 'Mineral-filtered · TDS tested daily',
        rating: 4.7,
        reviewCount: 128,
      ),
      const Shop(
        id: 'shop-3',
        name: 'Blue Drop Water Plant',
        address: 'Kakinada Highway, Rajahmundry',
        place: 'Kakinada Highway',
        phone: '+91 91234 00002',
        latitude: 16.9950,
        longitude: 81.7700,
        subscriptionStatus: ShopSubscriptionStatus.active,
        homeDeliveryAvailable: true,
        normalPrice: 19,
        coolPrice: 29,
        tagline: 'Budget-friendly · Same-day delivery',
        rating: 4.4,
        reviewCount: 89,
      ),
      const Shop(
        id: 'shop-4',
        name: 'Crystal Clear Water Co.',
        address: 'Godavari Nagar, Rajahmundry',
        place: 'Godavari Nagar',
        phone: '+91 91234 00003',
        latitude: 16.9780,
        longitude: 81.7850,
        subscriptionStatus: ShopSubscriptionStatus.active,
        homeDeliveryAvailable: true,
        normalPrice: 20,
        coolPrice: 30,
        tagline: 'ISO certified · Free monthly can service',
        rating: 4.9,
        reviewCount: 214,
      ),
      const Shop(
        id: 'shop-5',
        name: 'Neer Amrit Water Plant',
        address: 'Danavaipeta, Rajahmundry',
        place: 'Danavaipeta',
        phone: '+91 91234 00004',
        latitude: 16.9830,
        longitude: 81.7760,
        subscriptionStatus: ShopSubscriptionStatus.active,
        homeDeliveryAvailable: true,
        normalPrice: 18,
        coolPrice: 28,
        tagline: 'Pure water · Affordable monthly plans',
        rating: 4.6,
        reviewCount: 73,
      ),
    ]);
  }

  List<Promotion> get promotions => List.unmodifiable(_promotions);

  void _seedPromotions() {
    if (_promotions.isNotEmpty) return;
    final now = DateTime.now();
    _promotions.addAll([
      Promotion(
        id: 'promo-1',
        shopId: defaultShopId,
        shopName: settings.businessName,
        headline: '🎉 Summer Special — Free Cool Can!',
        body: 'Order 10 normal cans this month and get 1 cool can absolutely free. Valid till end of June.',
        mediaType: PromotionMediaType.image,
        badge: 'FREE CAN',
        ctaLabel: 'Claim offer',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Promotion(
        id: 'promo-2',
        shopId: 'shop-2',
        shopName: 'Aqua Pure RO Center',
        headline: '💧 New Customer Offer',
        body: 'First-time customers get 2 cans free on their first order. Use code AQUAFIRST at checkout.',
        mediaType: PromotionMediaType.image,
        badge: 'NEW',
        ctaLabel: 'Order now',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Promotion(
        id: 'promo-3',
        shopId: 'shop-4',
        shopName: 'Crystal Clear Water Co.',
        headline: '🏆 ISO Certified — Best Quality',
        body: 'TDS level tested daily. Our water meets the highest purity standards. Monthly plans starting ₹180.',
        mediaType: PromotionMediaType.video,
        badge: 'QUALITY',
        ctaLabel: 'View plans',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Promotion(
        id: 'promo-4',
        shopId: 'shop-3',
        shopName: 'Blue Drop Water Plant',
        headline: '⚡ Same-Day Delivery',
        body: 'Order before 12 PM and get delivery by 6 PM. No extra charge. Available in all areas.',
        mediaType: PromotionMediaType.image,
        badge: 'FAST',
        ctaLabel: 'Order now',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      Promotion(
        id: 'promo-5',
        shopId: 'shop-5',
        shopName: 'Neer Amrit Water Plant',
        headline: '📅 Monthly Plan — Save 15%',
        body: 'Subscribe to our monthly plan and save up to 15% compared to per-can pricing. Min 20 cans/month.',
        mediaType: PromotionMediaType.image,
        badge: 'SAVE 15%',
        ctaLabel: 'Subscribe',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  void updateSettings(BusinessSettings newSettings) {
    settings = newSettings;
    _syncShopFromSettings();
    final canProduct = productById('p2');
    if (canProduct != null) {
      final i = _products.indexWhere((p) => p.id == 'p2');
      _products[i] = canProduct.copyWith(
        variants: [
          ProductVariant(id: 'p2-v1', label: 'Normal Can', price: newSettings.normalPrice),
          ProductVariant(id: 'p2-v2', label: 'Cool Can', price: newSettings.coolPrice, isCool: true),
        ],
      );
    }
    notifyListeners();
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
      savedImagePath = await ProductImageService.persistFromFile(imageSourcePath);
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
    return product;
  }

  String _defaultProductDescription(
    ProductCategory category,
    String label, {
    bool isCool = false,
  }) {
    return switch (category) {
      ProductCategory.bottle => 'RO water bottle — $label',
      ProductCategory.can => isCool ? 'Chilled 20L RO water can' : '20L RO water can — $label',
    };
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
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

  void resetMockData() {
    _customers.clear();
    _deliveries.clear();
    _payments.clear();
    _orders.clear();
    _products.clear();
    _drivers.clear();
    _routeNotes.clear();
    _todaysRouteIds = [];
    _seedMockData();
    notifyListeners();
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