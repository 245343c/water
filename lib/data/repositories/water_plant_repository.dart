import 'package:flutter/foundation.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_stats.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
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

  late BusinessSettings settings;

  List<Customer> get customers => List.unmodifiable(_customers);
  List<Delivery> get deliveries => List.unmodifiable(_deliveries);
  List<Payment> get payments => List.unmodifiable(_payments);

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
        Delivery(
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

  List<Payment> paymentsForCustomer(String customerId) {
    final list = _payments.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Payment? lastPayment(String customerId) {
    final list = paymentsForCustomer(customerId);
    return list.isEmpty ? null : list.first;
  }

  MonthlyStats monthlyStatsForCustomer(String customerId, DateTime month) {
    final monthDeliveries = deliveriesForCustomer(customerId, month: month);
    final normalCans =
        monthDeliveries.fold<int>(0, (s, d) => s + d.normalQty);
    final coolCans = monthDeliveries.fold<int>(0, (s, d) => s + d.coolQty);
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
      (s, d) => s + d.normalQty + d.coolQty,
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
    notifyListeners();
  }

  Delivery addDelivery({
    required String customerId,
    required DateTime date,
    required int normalQty,
    required int coolQty,
  }) {
    final delivery = Delivery(
      id: _uuid.v4(),
      customerId: customerId,
      date: date,
      normalQty: normalQty,
      coolQty: coolQty,
      normalUnitPrice: settings.normalPrice,
      coolUnitPrice: settings.coolPrice,
    );
    _deliveries.insert(0, delivery);
    notifyListeners();
    return delivery;
  }

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
    notifyListeners();
  }

  void resetMockData() {
    _customers.clear();
    _deliveries.clear();
    _payments.clear();
    _seedMockData();
    notifyListeners();
  }

  String customerActivityLabel(String customerId, DateTime month) {
    final stats = monthlyStatsForCustomer(customerId, month);
    final cans = stats.normalCans + stats.coolCans;
    if (cans == 0) return 'No deliveries this month';
    return '$cans cans delivered this month';
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