import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
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
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';
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
    _seedReferenceData();
  }

  static const _uuid = Uuid();
  final List<Customer> _customers = [];
  final List<Delivery> _deliveries = [];
  final List<Payment> _payments = [];
  final List<CustomerOrder> _orders = [];
  final List<Product> _products = [];
  final List<Driver> _drivers = [];
  final List<DeliveryRoute> _deliveryRoutes = [];
  final List<Shop> _shops = [];
  final List<Promotion> _promotions = [];

  /// CRM customer id → marketplace shop id (multi-shop bulk billing).
  final Map<String, String> _customerShopIds = {};

  /// Driver id -> shop id for tenant-scoped access.
  final Map<String, String> _driverShopIds = {};
  final Map<String, CustomerAppProfile> _customerProfiles = {};
  final Map<String, String> _routeNotes = {};
  List<String> _todaysRouteIds = [];

  static const defaultShopId = 'shop-1';

  late BusinessSettings settings;

  /// Local path to the admin's profile photo (null = not set).
  String? adminImagePath;
  String? _loadedFirebaseCustomerShopId;
  String? _loadedFirebaseDriverShopId;
  String? _loadedFirebaseLedgerShopId;
  bool _loadingFirebaseData = false;
  String? _loadedFirebaseUserId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ledgerDeliveriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ledgerPaymentsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ledgerOrdersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customerLedgerSub;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _customerLedgerItemSubs = [];
  Timer? _customerLedgerReloadTimer;
  Timer? _customerPortalRefreshTimer;
  String? _watchedLedgerShopId;
  String? _watchedCustomerLedgerUserId;

  bool get isFirebaseLoading => _loadingFirebaseData;

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
  List<DeliveryRoute> get deliveryRoutes => List.unmodifiable(_deliveryRoutes);
  List<Shop> get shops => List.unmodifiable(_shops);

  List<DeliveryRoute> get activeDeliveryRoutes =>
      _deliveryRoutes.where((route) => route.active).toList();

  DeliveryRoute? deliveryRouteById(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    try {
      return _deliveryRoutes.firstWhere((route) => route.id == id);
    } catch (_) {
      return null;
    }
  }

  String deliveryRouteName(String? id) =>
      deliveryRouteById(id)?.name ?? 'Unassigned';

  DeliveryRoute addDeliveryRoute(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Route name is required');
    }
    final existing = _deliveryRoutes.any(
      (route) => route.name.toLowerCase() == cleaned.toLowerCase(),
    );
    if (existing) {
      throw ArgumentError('Route already exists');
    }
    final route = DeliveryRoute(id: _uuid.v4(), name: cleaned);
    _deliveryRoutes.add(route);
    notifyListeners();
    return route;
  }

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

  Future<void> linkContractCustomerOnLoginFromFirestore({
    required String userId,
    required String phone,
  }) async {
    final digits = normalizePhone(phone);
    if (digits.length < 10) return;

    Customer? firstCustomer;
    Shop? firstShop;
    final result = await FirebaseFunctions.instance
        .httpsCallable('linkCustomerByPhone')
        .call({'phone': digits});
    final data = result.data is Map ? Map<String, dynamic>.from(result.data) : {};
    final matches = data['matches'] is List ? data['matches'] as List : const [];

    for (final item in matches.whereType<Map>()) {
      final shopData = item['shop'];
      final customerData = item['customer'];
      if (shopData is! Map || customerData is! Map) continue;
      final shopMap = Map<String, dynamic>.from(shopData);
      final customerMap = Map<String, dynamic>.from(customerData);
      final shopId = shopMap['id'] as String? ?? '';
      final customerId = customerMap['id'] as String? ?? '';
      if (shopId.isEmpty || customerId.isEmpty) continue;

      final shop = _shopFromFirestore(shopId, shopMap);
      final customer = _customerFromFirestoreMap(customerId, customerMap);
      _upsertShop(shop);
      _upsertCustomer(customer, shop.id);

      firstCustomer ??= customer;
      firstShop ??= shop;
    }

    if (firstCustomer == null) return;
    final lat = firstShop?.latitude ?? settings.shopLatitude ?? 16.9902;
    final lng = firstShop?.longitude ?? settings.shopLongitude ?? 81.7780;

    saveCustomerProfile(
      CustomerAppProfile(
        userId: userId,
        name: firstCustomer.name,
        phone: digits,
        address: firstCustomer.address,
        latitude: lat,
        longitude: lng,
        email: firstCustomer.email,
        place: firstCustomer.place,
        linkedCrmCustomerId: firstCustomer.id,
        onboardingComplete: true,
      ),
    );
  }

  void _seedReferenceData() {
    settings = BusinessSettings(
      businessName: 'Water plant',
      address: '',
      phone: '',
      normalPrice: 0,
      coolPrice: 0,
    );

    _seedProducts();
  }

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

  CustomerOrder? latestOpenOrderForAppUserShop({
    required String appUserId,
    required String shopId,
  }) {
    for (final order in ordersForAppUser(appUserId)) {
      if (order.shopId == shopId &&
          order.status == OrderStatus.pending &&
          order.placedByAppUserId == appUserId) {
        return order;
      }
    }
    return null;
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
    String? routeId,
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
      routeId: routeId,
      billingMode: billingMode,
      productPrices: productPrices ?? defaultCustomerPricing(),
    );
    _customers.insert(0, customer);
    _linkCustomerToShop(customer.id, defaultShopId);
    notifyListeners();
    return customer;
  }

  Future<void> loadCustomersForCurrentAdminFromFirestore({
    bool force = false,
  }) async {
    final shopId = await _currentAdminShopId();
    if (shopId == null) return;
    if (!force && _loadedFirebaseCustomerShopId == shopId) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .where('active', isEqualTo: true)
        .get();

    _customers
      ..clear()
      ..addAll(snapshot.docs.map(_customerFromFirestore));
    _customerShopIds
      ..clear()
      ..addEntries(_customers.map((c) => MapEntry(c.id, shopId)));
    _loadedFirebaseCustomerShopId = shopId;
    notifyListeners();
  }

  Future<void> loadFirebaseDataForUser(AppUser? user) async {
    if (user == null) {
      _loadedFirebaseUserId = null;
      await stopFirebaseWatches();
      clearOperationalData();
      return;
    }
    if (user.role == AppRole.customer) {
      _loadedFirebaseUserId = user.id;
      await stopFirebaseWatches();
      await refreshCustomerPortal(user.phone);
      _customerPortalRefreshTimer = Timer.periodic(
        const Duration(seconds: 12),
        (_) => _refreshCustomerPortalQuietly(user.phone),
      );
      notifyListeners();
      return;
    }
    if (_loadedFirebaseUserId == user.id && !_loadingFirebaseData) return;

    _loadedFirebaseUserId = user.id;
    _loadingFirebaseData = true;
    await stopFirebaseWatches();
    clearOperationalData(notify: false);
    notifyListeners();

    try {
      await loadCurrentShopFromFirestore(force: true);
      await loadCustomersForCurrentAdminFromFirestore(force: true);
      await loadLedgerForCurrentShopFromFirestore(force: true);
      if (user.role == AppRole.admin) {
        await loadDriversForCurrentAdminFromFirestore(force: true);
      } else if (user.role == AppRole.driver && user.driverId != null) {
        await loadDriverForCurrentUserFromFirestore(user.driverId!);
      }
      await startLedgerWatchForCurrentShop();
    } finally {
      _loadingFirebaseData = false;
      notifyListeners();
    }
  }

  Future<String?> firebaseShopIdForCurrentUser() => _currentAdminShopId();

  Future<List<String>> linkedCustomerIdsForAppUser(String? userId) async {
    if (userId == null) return const [];
    final snapshot = await FirebaseFirestore.instance
        .collection('customerShopLinks')
        .where('uid', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['customerId'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<void> loadLedgerForLinkedCustomersFromFirestore(String userId) async {
    final phone = firebase_auth.FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phone == null) return;
    await refreshCustomerPortal(phone);
  }

  Future<void> refreshCustomerPortal(String phone) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('linkCustomerByPhone')
        .call({'action': 'refresh', 'phone': normalizePhone(phone)});
    _applyCustomerPortalData(result.data);
  }

  Future<void> _refreshCustomerPortalQuietly(String phone) async {
    try {
      await refreshCustomerPortal(phone);
    } catch (_) {
      // Keep the last good customer snapshot during a temporary network error.
    }
  }

  void _applyCustomerPortalData(Object? value) {
    final data = value is Map ? Map<String, dynamic>.from(value) : {};
    final links = data['links'] is List ? data['links'] as List : const [];
    _deliveries.clear();
    _payments.clear();
    _orders.clear();

    for (final item in links.whereType<Map>()) {
      final shopData = item['shop'];
      final customerData = item['customer'];
      if (shopData is! Map || customerData is! Map) continue;
      final shopMap = Map<String, dynamic>.from(shopData);
      final customerMap = Map<String, dynamic>.from(customerData);
      final shopId = shopMap['id'] as String? ?? '';
      final customerId = customerMap['id'] as String? ?? '';
      if (shopId.isEmpty || customerId.isEmpty) continue;

      _upsertShop(_shopFromFirestore(shopId, shopMap));
      _upsertCustomer(_customerFromFirestoreMap(customerId, customerMap), shopId);
      final deliveries =
          item['deliveries'] is List ? item['deliveries'] as List : const [];
      final payments = item['payments'] is List ? item['payments'] as List : const [];
      final orders = item['orders'] is List ? item['orders'] as List : const [];
      _deliveries.addAll(deliveries.map(_deliveryFromCallable));
      _payments.addAll(payments.map(_paymentFromCallable));
      _orders.addAll(orders.map(_orderFromCallable));
    }
    _deliveries.sort((a, b) => b.date.compareTo(a.date));
    _payments.sort((a, b) => b.date.compareTo(a.date));
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> startLedgerWatchForCurrentShop() async {
    final shopId = await _currentAdminShopId();
    if (shopId == null) return;
    if (_watchedLedgerShopId == shopId &&
        _ledgerDeliveriesSub != null &&
        _ledgerPaymentsSub != null &&
        _ledgerOrdersSub != null) {
      return;
    }

    await _ledgerDeliveriesSub?.cancel();
    await _ledgerPaymentsSub?.cancel();
    await _ledgerOrdersSub?.cancel();
    _watchedLedgerShopId = shopId;
    _ledgerDeliveriesSub = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('deliveries')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(_applyShopDeliverySnapshot);
    _ledgerPaymentsSub = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(_applyShopPaymentSnapshot);
    _ledgerOrdersSub = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_applyShopOrderSnapshot);
  }

  Future<void> startCustomerLedgerWatch(String userId) async {
    if (_watchedCustomerLedgerUserId == userId && _customerLedgerSub != null) {
      return;
    }

    await _customerLedgerSub?.cancel();
    await _cancelCustomerLedgerItemSubs();
    _watchedCustomerLedgerUserId = userId;
    _customerLedgerSub = FirebaseFirestore.instance
        .collection('customerShopLinks')
        .where('uid', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .snapshots()
        .listen((_) async {
      await loadLedgerForLinkedCustomersFromFirestore(userId);
      await _restartCustomerLedgerItemWatches(userId);
    });
    await _restartCustomerLedgerItemWatches(userId);
  }

  Future<void> _restartCustomerLedgerItemWatches(String userId) async {
    await _cancelCustomerLedgerItemSubs();
    final links = await FirebaseFirestore.instance
        .collection('customerShopLinks')
        .where('uid', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .get();

    for (final link in links.docs) {
      final data = link.data();
      final shopId = data['shopId'] as String?;
      final customerId = data['customerId'] as String?;
      if (shopId == null || customerId == null) continue;
      final shopRef = FirebaseFirestore.instance.collection('shops').doc(shopId);
      _customerLedgerItemSubs.add(
        shopRef
            .collection('deliveries')
            .where('customerId', isEqualTo: customerId)
            .snapshots()
            .listen((_) => _scheduleCustomerLedgerReload(userId)),
      );
      _customerLedgerItemSubs.add(
        shopRef
            .collection('payments')
            .where('customerId', isEqualTo: customerId)
            .snapshots()
            .listen((_) => _scheduleCustomerLedgerReload(userId)),
      );
    }
  }

  void _scheduleCustomerLedgerReload(String userId) {
    _customerLedgerReloadTimer?.cancel();
    _customerLedgerReloadTimer = Timer(const Duration(milliseconds: 250), () {
      loadLedgerForLinkedCustomersFromFirestore(userId);
    });
  }

  Future<void> _cancelCustomerLedgerItemSubs() async {
    for (final sub in _customerLedgerItemSubs) {
      await sub.cancel();
    }
    _customerLedgerItemSubs.clear();
  }

  void _applyShopDeliverySnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final shopId = _watchedLedgerShopId;
    if (shopId == null) return;

    _deliveries.removeWhere((d) => shopIdForCustomer(d.customerId) == shopId);
    _deliveries.addAll(snapshot.docs.map(_deliveryFromFirestore));
    _deliveries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void _applyShopPaymentSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final shopId = _watchedLedgerShopId;
    if (shopId == null) return;

    _payments.removeWhere((p) => shopIdForCustomer(p.customerId) == shopId);
    _payments.addAll(snapshot.docs.map(_paymentFromFirestore));
    _payments.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void _applyShopOrderSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final shopId = _watchedLedgerShopId;
    if (shopId == null) return;

    _orders.removeWhere((o) => o.shopId == shopId);
    _orders.addAll(snapshot.docs.map(_orderFromFirestore));
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> stopFirebaseWatches() async {
    _customerLedgerReloadTimer?.cancel();
    _customerLedgerReloadTimer = null;
    await _ledgerDeliveriesSub?.cancel();
    _ledgerDeliveriesSub = null;
    await _ledgerPaymentsSub?.cancel();
    _ledgerPaymentsSub = null;
    await _ledgerOrdersSub?.cancel();
    _ledgerOrdersSub = null;
    _watchedLedgerShopId = null;
    await _customerLedgerSub?.cancel();
    _customerLedgerSub = null;
    await _cancelCustomerLedgerItemSubs();
    _watchedCustomerLedgerUserId = null;
    _customerPortalRefreshTimer?.cancel();
    _customerPortalRefreshTimer = null;
  }

  @override
  void dispose() {
    stopFirebaseWatches();
    super.dispose();
  }

  void clearOperationalData({bool notify = true}) {
    _customers.clear();
    _deliveries.clear();
    _payments.clear();
    _orders.clear();
    _drivers.clear();
    _customerShopIds.clear();
    _driverShopIds.clear();
    _routeNotes.clear();
    _todaysRouteIds = [];
    _loadedFirebaseCustomerShopId = null;
    _loadedFirebaseDriverShopId = null;
    _loadedFirebaseLedgerShopId = null;
    if (notify) notifyListeners();
  }

  Future<void> loadCurrentShopFromFirestore({bool force = false}) async {
    final shopId = await _currentAdminShopId();
    if (shopId == null) return;
    if (!force && _shops.any((shop) => shop.id == shopId)) return;

    final shopDoc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .get();
    final data = shopDoc.data();
    if (data == null) return;

    final shop = _shopFromFirestore(shopDoc.id, data);
    _upsertShop(shop);
    settings = BusinessSettings(
      businessName: shop.name,
      address: shop.address,
      phone: shop.phone,
      email: shop.email,
      normalPrice: shop.normalPrice,
      coolPrice: shop.coolPrice,
      shopLatitude: shop.latitude,
      shopLongitude: shop.longitude,
      homeDeliveryAvailable: shop.homeDeliveryAvailable,
    );
    notifyListeners();
  }

  Future<void> loadLedgerForCurrentShopFromFirestore({
    bool force = false,
  }) async {
    final shopId = await _currentAdminShopId();
    if (shopId == null) return;
    if (!force && _loadedFirebaseLedgerShopId == shopId) return;

    final shopRef = FirebaseFirestore.instance.collection('shops').doc(shopId);
    final results = await Future.wait([
      shopRef.collection('deliveries').orderBy('date', descending: true).get(),
      shopRef.collection('payments').orderBy('date', descending: true).get(),
      shopRef.collection('orders').orderBy('createdAt', descending: true).get(),
    ]);

    final deliverySnapshot =
        results[0] as QuerySnapshot<Map<String, dynamic>>;
    final paymentSnapshot =
        results[1] as QuerySnapshot<Map<String, dynamic>>;
    final orderSnapshot =
        results[2] as QuerySnapshot<Map<String, dynamic>>;

    _deliveries
      ..clear()
      ..addAll(deliverySnapshot.docs.map(_deliveryFromFirestore));
    _payments
      ..clear()
      ..addAll(paymentSnapshot.docs.map(_paymentFromFirestore));
    _orders
      ..clear()
      ..addAll(orderSnapshot.docs.map(_orderFromFirestore));
    _loadedFirebaseLedgerShopId = shopId;
    notifyListeners();
  }

  Future<Customer> addCustomerToCurrentAdminShop({
    required String name,
    required String phone,
    required String email,
    required String place,
    required String address,
    String? routeId,
    CustomerBillingMode billingMode = CustomerBillingMode.monthlyContract,
    List<CustomerProductPrice>? productPrices,
  }) async {
    final shopId = await _currentAdminShopId();
    if (shopId == null) {
      return addCustomer(
        name: name,
        phone: phone,
        email: email,
        place: place,
        routeId: routeId,
        address: address,
        billingMode: billingMode,
        productPrices: productPrices,
      );
    }

    final ref = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .doc();
    final customer = Customer(
      id: ref.id,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      place: place.trim(),
      routeId: routeId,
      address: address.trim(),
      billingMode: billingMode,
      productPrices: productPrices ?? defaultCustomerPricing(),
    );

    await ref.set(_customerToFirestore(customer, creating: true));
    _customers.insert(0, customer);
    _linkCustomerToShop(customer.id, shopId);
    notifyListeners();
    return customer;
  }

  Future<void> updateCustomerInCurrentAdminShop(Customer customer) async {
    final shopId = await _currentAdminShopId();
    if (shopId == null) {
      updateCustomer(customer);
      return;
    }

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .doc(customer.id)
        .set(_customerToFirestore(customer), SetOptions(merge: true));
    updateCustomer(customer);
    _linkCustomerToShop(customer.id, shopId);
  }

  Future<void> deleteCustomerFromCurrentAdminShop(String id) async {
    final shopId = await _currentAdminShopId();
    if (shopId != null) {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(id)
          .set({
            'active': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
    deleteCustomer(id);
  }

  Future<String?> _currentAdminShopId() async {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return userDoc.data()?['shopId'] as String?;
  }

  Future<String?> _shopIdForCustomerOrCurrent(String customerId) async {
    final cachedShopId = shopIdForCustomer(customerId);
    if (cachedShopId != defaultShopId) {
      return cachedShopId;
    }
    return _currentAdminShopId();
  }

  Customer _customerFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _customerFromFirestoreMap(doc.id, doc.data());
  }

  Customer _customerFromFirestoreMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return Customer(
      id: id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      place: data['place'] as String? ?? '',
      routeId: data['routeId'] as String?,
      address: data['address'] as String? ?? '',
      paymentFrequency: data['paymentFrequency'] as String? ?? 'Monthly',
      billingMode: CustomerBillingMode.monthlyContract,
      productPrices: _productPricesFromFirestore(data['productPrices']),
      appUserId: data['appUserId'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  Shop _shopFromFirestore(String id, Map<String, dynamic> data) {
    final trialEndsAt = data['trialEndsAt'];
    return Shop(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      place: data['place'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      subscriptionStatus: _shopSubscriptionStatusFromFirestore(
        data['subscriptionStatus'] as String?,
      ),
      trialEndsAt: trialEndsAt is Timestamp ? trialEndsAt.toDate() : null,
      isListed: data['isListed'] as bool? ?? true,
      homeDeliveryAvailable:
          data['homeDeliveryAvailable'] as bool? ?? false,
      normalPrice: (data['normalPrice'] as num?)?.toDouble() ?? 20,
      coolPrice: (data['coolPrice'] as num?)?.toDouble() ?? 30,
      coverImageUrl: data['coverImageUrl'] as String?,
      tagline: data['tagline'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  ShopSubscriptionStatus _shopSubscriptionStatusFromFirestore(String? value) {
    return switch (value) {
      'active' => ShopSubscriptionStatus.active,
      'grace' => ShopSubscriptionStatus.grace,
      'expired' => ShopSubscriptionStatus.expired,
      _ => ShopSubscriptionStatus.trial,
    };
  }

  void _upsertShop(Shop shop) {
    final index = _shops.indexWhere((s) => s.id == shop.id);
    if (index >= 0) {
      _shops[index] = shop;
    } else {
      _shops.add(shop);
    }
  }

  void _upsertCustomer(Customer customer, String shopId) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    _linkCustomerToShop(customer.id, shopId);
  }

  Map<String, dynamic> _customerToFirestore(
    Customer customer, {
    bool creating = false,
  }) {
    return {
      'name': customer.name,
      'phone': customer.phone,
      'normalizedPhone': customer.phone.replaceAll(RegExp(r'\D'), ''),
      'email': customer.email,
      'place': customer.place,
      'address': customer.address,
      'routeId': customer.routeId,
      'paymentFrequency': customer.paymentFrequency,
      'billingMode': customer.billingMode.name,
      'productPrices': customer.productPrices.map(_productPriceToMap).toList(),
      'appUserId': customer.appUserId,
      'active': true,
      if (creating) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _productPriceToMap(CustomerProductPrice price) {
    return {
      'productId': price.productId,
      'variantId': price.variantId,
      'unitPrice': price.unitPrice,
      'enabled': price.enabled,
    };
  }

  List<CustomerProductPrice> _productPricesFromFirestore(Object? value) {
    if (value is! List) return defaultCustomerPricing();
    return value.whereType<Map>().map((item) {
      return CustomerProductPrice(
        productId: item['productId'] as String? ?? '',
        variantId: item['variantId'] as String? ?? '',
        unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0,
        enabled: item['enabled'] as bool? ?? true,
      );
    }).toList();
  }

  Delivery _deliveryFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Delivery(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      date: _dateTimeFromFirestore(data['date']) ?? DateTime.now(),
      lines: _deliveryLinesFromFirestore(data['lines']),
      driverId: data['driverId'] as String?,
      createdAt: _dateTimeFromFirestore(data['createdAt']),
    );
  }

  Delivery _deliveryFromCallable(Object? value) {
    final data = value is Map ? Map<String, dynamic>.from(value) : {};
    return Delivery(
      id: data['id'] as String? ?? _uuid.v4(),
      customerId: data['customerId'] as String? ?? '',
      date: _dateTimeFromFirestore(data['date']) ?? DateTime.now(),
      lines: _deliveryLinesFromFirestore(data['lines']),
      driverId: data['driverId'] as String?,
      createdAt: _dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> _deliveryLineToMap(DeliveryLineItem line) {
    return {
      'kind': line.kind.name,
      'label': line.label,
      'quantity': line.quantity,
      'unitPrice': line.unitPrice,
      'lineTotal': line.lineTotal,
      'productId': line.productId,
    };
  }

  List<DeliveryLineItem> _deliveryLinesFromFirestore(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      return DeliveryLineItem(
        kind: _deliveryItemKindFromString(item['kind'] as String?),
        label: item['label'] as String? ?? 'Delivery item',
        quantity: (item['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0,
        productId: item['productId'] as String?,
      );
    }).where((line) => line.quantity > 0).toList();
  }

  DeliveryItemKind _deliveryItemKindFromString(String? value) {
    return DeliveryItemKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => DeliveryItemKind.normalCan,
    );
  }

  Payment _paymentFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Payment(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      date: _dateTimeFromFirestore(data['date']) ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      method: _paymentMethodFromString(data['method'] as String?),
      notes: data['notes'] as String?,
      createdAt: _dateTimeFromFirestore(data['createdAt']),
    );
  }

  Payment _paymentFromCallable(Object? value) {
    final data = value is Map ? Map<String, dynamic>.from(value) : {};
    return Payment(
      id: data['id'] as String? ?? _uuid.v4(),
      customerId: data['customerId'] as String? ?? '',
      date: _dateTimeFromFirestore(data['date']) ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      method: _paymentMethodFromString(data['method'] as String?),
      notes: data['notes'] as String?,
      createdAt: _dateTimeFromFirestore(data['createdAt']),
    );
  }

  CustomerOrder _orderFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _orderFromMap(doc.id, doc.data());
  }

  CustomerOrder _orderFromCallable(Object? value) {
    final data = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
    return _orderFromMap(data['id'] as String? ?? _uuid.v4(), data);
  }

  CustomerOrder _orderFromMap(String id, Map<String, dynamic> data) {
    return CustomerOrder(
      id: id,
      customerId: data['customerId'] as String? ?? '',
      shopId: data['shopId'] as String?,
      placedByAppUserId: data['placedByAppUserId'] as String?,
      normalQty: (data['normalQty'] as num?)?.toInt() ?? 0,
      coolQty: (data['coolQty'] as num?)?.toInt() ?? 0,
      status: _orderStatusFromString(data['status'] as String?),
      customerNote: data['customerNote'] as String?,
      adminResponse: data['adminResponse'] as String?,
      createdAt: _dateTimeFromFirestore(data['createdAt']),
      respondedAt: _dateTimeFromFirestore(data['respondedAt']),
      driverAcceptedAt: _dateTimeFromFirestore(data['driverAcceptedAt']),
      deliveryStartedAt: _dateTimeFromFirestore(data['deliveryStartedAt']),
    );
  }

  OrderStatus _orderStatusFromString(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  PaymentMethod _paymentMethodFromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  DateTime? _dateTimeFromFirestore(Object? value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
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
    _customerShopIds.remove(id);
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
    return order;
  }

  Future<CustomerOrder> placeAppOrderInFirebase({
    required String shopId,
    required String appUserId,
    required int normalQty,
    required int coolQty,
    String? customerNote,
    String? productSummary,
  }) async {
    final draft = placeAppOrder(
      shopId: shopId,
      appUserId: appUserId,
      normalQty: normalQty,
      coolQty: coolQty,
      customerNote: customerNote,
      productSummary: productSummary,
    );
    final result = await FirebaseFunctions.instance
        .httpsCallable('linkCustomerByPhone')
        .call({
          'action': 'createOrder',
          'shopId': shopId,
          'customerId': draft.customerId,
          'normalQty': normalQty,
          'coolQty': coolQty,
          'customerNote': draft.customerNote ?? '',
        });
    _orders.removeWhere((order) => order.id == draft.id);
    _applyCustomerPortalData(result.data);
    return ordersForAppUser(appUserId).first;
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
  }

  void updatePendingAppOrder({
    required String orderId,
    required String appUserId,
    required int normalQty,
    required int coolQty,
    String? customerNote,
    String? productSummary,
  }) {
    final order = orderById(orderId);
    if (order == null) return;
    if (order.status != OrderStatus.pending ||
        order.placedByAppUserId != appUserId) {
      throw StateError('Only pending requests can be edited');
    }
    final hasCans = normalQty + coolQty > 0;
    final hasProducts =
        productSummary != null && productSummary.trim().isNotEmpty;
    if (!hasCans && !hasProducts) {
      throw ArgumentError('Add at least one item to order');
    }
    order.normalQty = normalQty;
    order.coolQty = coolQty;
    order.customerNote = _mergeOrderNotes(customerNote, productSummary);
    notifyListeners();
  }

  Future<void> respondToOrderInFirestore(
    String orderId,
    OrderStatus status, {
    String? adminResponse,
  }) async {
    final order = orderById(orderId);
    if (order == null || order.shopId == null) return;
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(order.shopId)
        .collection('orders')
        .doc(orderId)
        .set({
          'status': status.name,
          'adminResponse': adminResponse ?? '',
          'respondedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    respondToOrder(orderId, status, adminResponse: adminResponse);
  }

  Future<void> updatePendingAppOrderInFirebase({
    required String orderId,
    required String appUserId,
    required int normalQty,
    required int coolQty,
    String? customerNote,
    String? productSummary,
  }) async {
    final order = orderById(orderId);
    if (order == null || order.shopId == null) return;
    final note = _mergeOrderNotes(customerNote, productSummary);
    final result = await FirebaseFunctions.instance
        .httpsCallable('linkCustomerByPhone')
        .call({
          'action': 'updateOrder',
          'shopId': order.shopId,
          'customerId': order.customerId,
          'orderId': order.id,
          'normalQty': normalQty,
          'coolQty': coolQty,
          'customerNote': note ?? '',
        });
    _applyCustomerPortalData(result.data);
  }

  void cancelPendingAppOrder({
    required String orderId,
    required String appUserId,
  }) {
    final order = orderById(orderId);
    if (order == null) return;
    if (order.status != OrderStatus.pending ||
        order.placedByAppUserId != appUserId) {
      throw StateError('Only pending requests can be cancelled');
    }
    order.status = OrderStatus.cancelled;
    order.adminResponse = 'Cancelled by customer';
    order.respondedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> cancelPendingAppOrderInFirebase({
    required String orderId,
    required String appUserId,
  }) async {
    final order = orderById(orderId);
    if (order == null || order.shopId == null) return;
    final result = await FirebaseFunctions.instance
        .httpsCallable('linkCustomerByPhone')
        .call({
          'action': 'cancelOrder',
          'shopId': order.shopId,
          'customerId': order.customerId,
          'orderId': order.id,
        });
    _applyCustomerPortalData(result.data);
  }

  Future<void> driverAcceptOrder({
    required String orderId,
    required String driverId,
  }) async {
    final order = orderById(orderId);
    if (order == null || order.status != OrderStatus.accepted) return;
    if (order.driverAcceptedAt != null) return;
    final shop = shopForDriver(driverId);
    if (shop == null ||
        (order.shopId != shop.id &&
            shopIdForCustomer(order.customerId) != shop.id)) {
      throw StateError('This request belongs to another water plant');
    }
    await FirebaseFunctions.instance
        .httpsCallable('recordCustomerDelivery')
        .call({
          'action': 'updateOrderProgress',
          'orderId': orderId,
          'progress': 'accepted',
        });
    order.driverAcceptedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> driverStartDelivery({
    required String orderId,
    required String driverId,
  }) async {
    final order = orderById(orderId);
    if (order == null || order.status != OrderStatus.accepted) return;
    final shop = shopForDriver(driverId);
    if (shop == null ||
        (order.shopId != shop.id &&
            shopIdForCustomer(order.customerId) != shop.id)) {
      throw StateError('This request belongs to another water plant');
    }
    await FirebaseFunctions.instance
        .httpsCallable('recordCustomerDelivery')
        .call({
          'action': 'updateOrderProgress',
          'orderId': orderId,
          'progress': 'started',
        });
    order.driverAcceptedAt ??= DateTime.now();
    order.deliveryStartedAt ??= DateTime.now();
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

  Future<Driver?> loadDriverForCurrentUserFromFirestore(String driverId) async {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return driverById(driverId);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final shopId = userDoc.data()?['shopId'] as String?;
    if (shopId == null || shopId.isEmpty) return null;

    final driverDoc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('drivers')
        .doc(driverId)
        .get();
    final data = driverDoc.data();
    if (data == null) return null;

    final driver = _driverFromFirestore(driverDoc);
    _upsertDriver(driver, shopId);
    notifyListeners();
    return driver;
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
    return driver;
  }

  Future<void> loadDriversForCurrentAdminFromFirestore({
    bool force = false,
  }) async {
    final shopId = await _currentAdminShopId();
    if (shopId == null) return;
    if (!force && _loadedFirebaseDriverShopId == shopId) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('drivers')
        .where('active', isEqualTo: true)
        .get();

    _drivers
      ..clear()
      ..addAll(snapshot.docs.map(_driverFromFirestore));
    _driverShopIds
      ..clear()
      ..addEntries(_drivers.map((d) => MapEntry(d.id, shopId)));
    _loadedFirebaseDriverShopId = shopId;
    notifyListeners();
  }

  Future<Driver> createDriverAccountInFirebase({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final shopId = await _currentAdminShopId();
    final pendingDriver = Driver(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
    _upsertDriver(pendingDriver, shopId ?? defaultShopId);
    notifyListeners();

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('createDriverAccount')
          .call({
            'name': name,
            'phone': phone,
            'email': email,
            'password': password,
          });
      final driver = _driverFromCallable(result.data);
      _drivers.removeWhere((d) => d.id == pendingDriver.id);
      _driverShopIds.remove(pendingDriver.id);
      _upsertDriver(driver, shopId ?? defaultShopId);
      notifyListeners();
      return driver;
    } catch (_) {
      _drivers.removeWhere((d) => d.id == pendingDriver.id);
      _driverShopIds.remove(pendingDriver.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDriverAccountInFirebase({
    required String driverId,
    required String name,
    required String phone,
    required String email,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('updateDriverAccount')
        .call({
          'driverId': driverId,
          'name': name,
          'phone': phone,
          'email': email,
        });
    final driver = _driverFromCallable(result.data);
    final shopId = await _currentAdminShopId();
    _upsertDriver(driver, shopId ?? shopIdForDriver(driver.id));
    notifyListeners();
  }

  Future<void> setDriverActiveInFirebase(String driverId, bool active) async {
    final previous = driverById(driverId);
    setDriverActive(driverId, active);
    try {
      await FirebaseFunctions.instance.httpsCallable('setDriverActive').call({
        'driverId': driverId,
        'active': active,
      });
    } catch (_) {
      if (previous != null) {
        setDriverActive(driverId, previous.active);
      }
      rethrow;
    }
  }

  Future<void> deleteDriverAccountInFirebase(String driverId) async {
    await FirebaseFunctions.instance.httpsCallable('deleteDriverAccount').call({
      'driverId': driverId,
    });
    deleteDriver(driverId);
  }

  Future<void> resetDriverPasswordInFirebase({
    required String driverId,
    required String password,
  }) async {
    await FirebaseFunctions.instance.httpsCallable('resetDriverPassword').call({
      'driverId': driverId,
      'password': password,
    });
  }

  Driver _driverFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];
    return Driver(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  Driver _driverFromCallable(Object? value) {
    final data = value is Map ? Map<String, dynamic>.from(value) : {};
    return Driver(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      createdAt: DateTime.now(),
    );
  }

  void _upsertDriver(Driver driver, String shopId) {
    final index = _drivers.indexWhere((d) => d.id == driver.id);
    if (index >= 0) {
      _drivers[index] = driver;
    } else {
      _drivers.insert(0, driver);
    }
    _linkDriverToShop(driver.id, shopId);
  }

  void setDriverActive(String driverId, bool active) {
    final i = _drivers.indexWhere((d) => d.id == driverId);
    if (i < 0) return;
    _drivers[i] = _drivers[i].copyWith(active: active);
    notifyListeners();
  }

  void updateDriver({
    required String driverId,
    required String name,
    required String phone,
    required String email,
  }) {
    final i = _drivers.indexWhere((d) => d.id == driverId);
    if (i < 0) return;
    _drivers[i] = _drivers[i].copyWith(
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim().toLowerCase(),
    );
    notifyListeners();
  }

  void deleteDriver(String driverId) {
    _drivers.removeWhere((d) => d.id == driverId);
    _driverShopIds.remove(driverId);
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
              deliveryForOrder(o) == null,
        )
        .toList();
    if (driverId != null) {
      final shop = shopForDriver(driverId);
      list = shop == null
          ? <CustomerOrder>[]
          : list
                .where(
                  (o) =>
                      o.shopId == shop.id ||
                      shopIdForCustomer(o.customerId) == shop.id,
                )
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
    final delivery = _buildDelivery(
      id: _uuid.v4(),
      customerId: customerId,
      date: date,
      normalQty: normalQty,
      coolQty: coolQty,
      bottles: bottles,
      driverId: driverId,
    );
    _upsertDelivery(delivery);
    notifyListeners();
    return delivery;
  }

  Future<Delivery> addDeliveryToCurrentShop({
    required String customerId,
    required DateTime date,
    int normalQty = 0,
    int coolQty = 0,
    List<BottleDeliveryInput> bottles = const [],
    String? driverId,
    String? driverName,
  }) async {
    final shopId = await _shopIdForCustomerOrCurrent(customerId);
    if (shopId == null) {
      return addDelivery(
        customerId: customerId,
        date: date,
        normalQty: normalQty,
        coolQty: coolQty,
        bottles: bottles,
        driverId: driverId,
      );
    }

    final deliveryDraft = _buildDelivery(
      id: _uuid.v4(),
      customerId: customerId,
      date: date,
      normalQty: normalQty,
      coolQty: coolQty,
      bottles: bottles,
      driverId: driverId,
    );

    final result = await FirebaseFunctions.instance
        .httpsCallable('recordCustomerDelivery')
        .call({
          'customerId': customerId,
          'date': date.toUtc().toIso8601String(),
          'lines': deliveryDraft.lines.map(_deliveryLineToMap).toList(),
          'driverId': driverId,
          if (driverName != null && driverName.isNotEmpty)
            'driverName': driverName,
        });
    final delivery = _deliveryFromCallable(result.data);
    _upsertDelivery(delivery);
    notifyListeners();
    return delivery;
  }

  Delivery _buildDelivery({
    required String id,
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

    return Delivery(
      id: id,
      customerId: customerId,
      date: date,
      lines: lines,
      driverId: driverId,
    );
  }

  void _upsertDelivery(Delivery delivery) {
    final index = _deliveries.indexWhere((d) => d.id == delivery.id);
    if (index >= 0) {
      _deliveries[index] = delivery;
    } else {
      _deliveries.insert(0, delivery);
    }
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
    _upsertPayment(payment);
    notifyListeners();
    return payment;
  }

  Future<Payment> addPaymentToCurrentShop({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? notes,
  }) async {
    final shopId = await _shopIdForCustomerOrCurrent(customerId);
    if (shopId == null) {
      return addPayment(
        customerId: customerId,
        amount: amount,
        method: method,
        date: date,
        notes: notes,
      );
    }

    final result = await FirebaseFunctions.instance
        .httpsCallable('recordCustomerPayment')
        .call({
          'customerId': customerId,
          'amount': amount,
          'method': method.name,
          'date': date.toUtc().toIso8601String(),
          'notes': notes ?? '',
        });
    final payment = _paymentFromCallable(result.data);
    _upsertPayment(payment);
    notifyListeners();
    return payment;
  }

  void _upsertPayment(Payment payment) {
    final index = _payments.indexWhere((p) => p.id == payment.id);
    if (index >= 0) {
      _payments[index] = payment;
    } else {
      _payments.insert(0, payment);
    }
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
              c.phone.replaceAll(' ', '').contains(q.replaceAll(' ', '')) ||
              c.place.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q) ||
              deliveryRouteName(c.routeId).toLowerCase().contains(q),
        )
        .toList();
  }
}
