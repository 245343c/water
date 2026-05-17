import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_action_item.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_stats.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/models/product_variant.dart';
import 'package:sri_sai_ro_water/core/services/product_image_service.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
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

  late BusinessSettings settings;

  List<Customer> get customers => List.unmodifiable(_customers);
  List<Delivery> get deliveries => List.unmodifiable(_deliveries);
  List<Payment> get payments => List.unmodifiable(_payments);
  List<CustomerOrder> get orders => List.unmodifiable(_orders);
  List<Product> get products => List.unmodifiable(_products);

  void _seedMockData() {
    settings = BusinessSettings(
      businessName: 'Sri Sai RO Water Plant',
      address: 'Main Road, Rajahmundry, Andhra Pradesh - 533101',
      phone: '+91 98765 43210',
      email: 'info@srisairowater.com',
      normalPrice: 20,
      coolPrice: 30,
    );

    final ramesh = Customer(
      id: 'c1',
      name: 'Ramesh Kumar',
      phone: '98850 12345',
      email: 'ramesh.kumar@email.com',
      place: 'Gandhi Nagar, Rajahmundry',
      address: 'Door No: 12-5-8, Gandhi Nagar',
    );
    final lakshmi = Customer(
      id: 'c2',
      name: 'Lakshmi Devi',
      phone: '98765 43210',
      email: 'lakshmi.devi@email.com',
      place: 'RTC Colony, Rajahmundry',
      address: 'Plot 45, RTC Colony',
    );
    final suresh = Customer(
      id: 'c3',
      name: 'Suresh Babu',
      phone: '91234 56789',
      email: 'suresh.babu@email.com',
      place: 'Danavaipeta, Rajahmundry',
      address: 'Flat 302, Sai Residency',
    );
    final priya = Customer(
      id: 'c4',
      name: 'Priya Sharma',
      phone: '99887 76655',
      email: 'priya.sharma@email.com',
      place: 'Market Street, Rajahmundry',
      address: '12, Market Street',
    );
    final venkat = Customer(
      id: 'c5',
      name: 'Venkat Reddy',
      phone: '94401 22334',
      place: 'Katheru Road, Rajahmundry',
      address: 'H.No 8-2-14, Katheru Road',
    );

    _customers.addAll([ramesh, lakshmi, suresh, priya, venkat]);

    _seedProducts();

    final now = DateTime.now();
    final may = DateTime(now.year, now.month);

    void addDelivery(
      String customerId,
      int day,
      int normal,
      int cool, {
      int hour = 10,
    }) {
      _deliveries.add(
        Delivery.fromLegacyCans(
          id: _uuid.v4(),
          customerId: customerId,
          date: DateTime(may.year, may.month, day, hour),
          normalQty: normal,
          coolQty: cool,
          normalUnitPrice: settings.normalPrice,
          coolUnitPrice: settings.coolPrice,
        ),
      );
    }

    addDelivery('c1', 21, 1, 2, hour: 9);
    addDelivery('c1', 20, 2, 0, hour: 11);
    addDelivery('c1', 18, 1, 1, hour: 8);
    addDelivery('c2', 19, 0, 3, hour: 14);
    addDelivery('c2', 17, 2, 1, hour: 10);
    addDelivery('c3', 21, 3, 2, hour: 7);
    addDelivery('c3', 20, 2, 2, hour: 16);
    addDelivery('c3', 19, 4, 1, hour: 9);
    addDelivery('c3', 15, 2, 3, hour: 11);
    addDelivery('c4', 21, 1, 0, hour: 12);
    addDelivery('c4', 16, 2, 2, hour: 15);
    addDelivery('c5', 20, 0, 2, hour: 13);
    addDelivery('c5', 14, 3, 0, hour: 8);

    _deliveries.add(
      Delivery(
        id: _uuid.v4(),
        customerId: 'c1',
        date: DateTime(may.year, may.month, 22, 10),
        lines: [
          DeliveryLineItem(
            kind: DeliveryItemKind.bottle,
            label: '1 L',
            quantity: 6,
            unitPrice: 15,
          ),
          DeliveryLineItem(
            kind: DeliveryItemKind.bottle,
            label: '2 L',
            quantity: 4,
            unitPrice: 25,
          ),
          DeliveryLineItem(
            kind: DeliveryItemKind.normalCan,
            label: 'Normal Can',
            quantity: 1,
            unitPrice: settings.normalPrice,
          ),
        ],
      ),
    );

    _payments.addAll([
      Payment(
        id: _uuid.v4(),
        customerId: 'c1',
        date: DateTime(may.year, may.month, 15),
        amount: 500,
        method: PaymentMethod.upi,
        notes: 'Partial payment',
      ),
      Payment(
        id: _uuid.v4(),
        customerId: 'c2',
        date: DateTime(may.year, may.month, 20),
        amount: 2000,
        method: PaymentMethod.cash,
      ),
      Payment(
        id: _uuid.v4(),
        customerId: 'c4',
        date: DateTime(may.year, may.month, 10),
        amount: 800,
        method: PaymentMethod.upi,
      ),
    ]);

    _seedMockOrders();
  }

  void _seedMockOrders() {
    final now = DateTime.now();

    CustomerOrder make(
      String customerId,
      int normal,
      int cool,
      OrderStatus status, {
      Duration age = const Duration(hours: 2),
      String? adminResponse,
      String? customerNote,
    }) {
      final created = now.subtract(age);
      return CustomerOrder(
        id: _uuid.v4(),
        customerId: customerId,
        normalQty: normal,
        coolQty: cool,
        status: status,
        customerNote: customerNote,
        adminResponse: adminResponse,
        createdAt: created,
        respondedAt: status == OrderStatus.pending
            ? null
            : created.add(const Duration(minutes: 20)),
      );
    }

    _orders.addAll([
      make('c1', 2, 1, OrderStatus.pending, age: const Duration(minutes: 35), customerNote: 'Please deliver by evening'),
      make('c3', 3, 0, OrderStatus.pending, age: const Duration(hours: 1)),
      make('c5', 0, 2, OrderStatus.pending, age: const Duration(hours: 3)),
      make('c2', 1, 2, OrderStatus.accepted, age: const Duration(hours: 5), adminResponse: 'Order confirmed'),
      make('c4', 2, 0, OrderStatus.accepted, age: const Duration(days: 1), adminResponse: 'Order confirmed'),
      make(
        'c1',
        4,
        0,
        OrderStatus.rejected,
        age: const Duration(days: 2),
        adminResponse: 'Out of stock — Normal cans',
      ),
    ]);
  }

  Customer? customerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  double customerBalance(String customerId) {
    final deliveryTotal = _deliveries
        .where((d) => d.customerId == customerId)
        .fold<double>(0, (sum, d) => sum + d.totalAmount);
    final paymentTotal = _payments
        .where((p) => p.customerId == customerId)
        .fold<double>(0, (sum, p) => sum + p.amount);
    return deliveryTotal - paymentTotal;
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

    final paidInMonth = _payments
        .where(
          (p) =>
              p.customerId == customerId && p.date.isSameMonth(month),
        )
        .fold<double>(0, (s, p) => s + p.amount);

    final priorBalance = _balanceBeforeMonth(customerId, month);
    final balance = priorBalance + totalAmount - paidInMonth;

    return MonthlyStats(
      normalCans: normalCans,
      coolCans: coolCans,
      bottleUnits: bottleUnits,
      bottlesByLabel: bottlesByLabel,
      quantitiesByLabel: quantitiesByLabel,
      totalAmount: totalAmount,
      paidAmount: paidInMonth,
      balance: balance.clamp(0, double.infinity).toDouble(),
    );
  }

  double _balanceBeforeMonth(String customerId, DateTime month) {
    final monthStart = DateTime(month.year, month.month);
    final deliveryBefore = _deliveries
        .where((d) => d.customerId == customerId && d.date.isBefore(monthStart))
        .fold<double>(0, (s, d) => s + d.totalAmount);
    final paymentBefore = _payments
        .where((p) => p.customerId == customerId && p.date.isBefore(monthStart))
        .fold<double>(0, (s, p) => s + p.amount);
    return (deliveryBefore - paymentBefore).clamp(0, double.infinity);
  }

  double previousBalanceForMonth(String customerId, DateTime month) =>
      _balanceBeforeMonth(customerId, month);

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
      activeCustomers: activeIds.length,
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

  Customer addCustomer({
    required String name,
    required String phone,
    required String address,
    String email = '',
    String place = '',
  }) {
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      address: address,
      email: email,
      place: place,
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

  Delivery addDelivery({
    required String customerId,
    required DateTime date,
    int normalQty = 0,
    int coolQty = 0,
    List<BottleDeliveryInput> bottles = const [],
  }) {
    final lines = <DeliveryLineItem>[];
    if (normalQty > 0) {
      lines.add(
        DeliveryLineItem(
          kind: DeliveryItemKind.normalCan,
          label: 'Normal Can',
          quantity: normalQty,
          unitPrice: settings.normalPrice,
        ),
      );
    }
    if (coolQty > 0) {
      lines.add(
        DeliveryLineItem(
          kind: DeliveryItemKind.coolCan,
          label: 'Cool Can',
          quantity: coolQty,
          unitPrice: settings.coolPrice,
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

  void updateSettings(BusinessSettings newSettings) {
    settings = newSettings;
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
    _products
      ..clear()
      ..addAll([
        Product(
          id: 'p1',
          name: 'RO Water Bottles',
          description: 'Sealed packaged drinking water in multiple sizes for home and retail.',
          category: ProductCategory.bottle,
          variants: const [
            ProductVariant(id: 'p1-v1', label: '1/2 L', price: 10),
            ProductVariant(id: 'p1-v2', label: '1 L', price: 15),
            ProductVariant(id: 'p1-v3', label: '2 L', price: 25),
            ProductVariant(id: 'p1-v4', label: '5 L', price: 45),
            ProductVariant(id: 'p1-v5', label: '20 L', price: 80),
            ProductVariant(id: 'p1-v6', label: '25 L', price: 95),
          ],
        ),
        Product(
          id: 'p2',
          name: '20L Water Cans',
          description: 'Refillable RO water cans for dispensers — normal and chilled delivery.',
          category: ProductCategory.can,
          variants: [
            ProductVariant(id: 'p2-v1', label: 'Normal Can', price: settings.normalPrice),
            ProductVariant(id: 'p2-v2', label: 'Cool Can', price: settings.coolPrice, isCool: true),
          ],
        ),
      ]);
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