import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_request_card.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerContractActivityScreen extends StatelessWidget {
  const CustomerContractActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final userId = auth.currentUser?.id;
    final billings = userId != null ? repo.shopBillingsForAppUser(userId) : [];

    if (billings.isEmpty) {
      return CustomerScaffold(
        child: Column(
          children: [
            const _ActivityHeader(subtitle: 'Deliveries & payments'),
            const Expanded(
              child: CustomerEmptyState(
                icon: Icons.history_rounded,
                title: 'No activity',
                message: 'Link your account with your shop first.',
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    var deliveryCount = 0;
    var deliveryTotal = 0.0;
    var paymentTotal = 0.0;
    final allDeliveries = <({Delivery d, String shopName})>[];
    final allPayments = <({Payment p, String shopName})>[];
    final requests = userId != null
        ? repo.ordersForAppUser(userId)
        : <CustomerOrder>[];
    final pendingRequests = requests
        .where((o) => o.status == OrderStatus.pending)
        .length;

    for (final b in billings) {
      final shopName = b.shop.name;
      final dels = repo.deliveriesForCustomer(b.customer.id, month: month);
      final pays = repo.paymentsForCustomer(b.customer.id, month: month);
      deliveryCount += dels.length;
      deliveryTotal += dels.fold<double>(0, (s, d) => s + d.totalAmount);
      paymentTotal += pays.fold<double>(0, (s, p) => s + p.amount);
      for (final d in dels) {
        allDeliveries.add((d: d, shopName: shopName));
      }
      for (final p in pays) {
        allPayments.add((p: p, shopName: shopName));
      }
    }

    allDeliveries.sort((a, b) => b.d.date.compareTo(a.d.date));
    allPayments.sort((a, b) => b.p.date.compareTo(a.p.date));

    return CustomerScaffold(
      child: Column(
        children: [
          _ActivityHeader(
            subtitle: requests.isEmpty
                ? month.monthYear
                : '$month.monthYear · $pendingRequests pending requests',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _miniStat('$deliveryCount', 'Deliveries', Colors.white),
                        _vDiv(),
                        _miniStat(
                          '${requests.length}',
                          'Requests',
                          Colors.white,
                        ),
                        _vDiv(),
                        _miniStat(
                          CurrencyUtils.format(deliveryTotal),
                          'Can value',
                          Colors.white,
                        ),
                        _vDiv(),
                        _miniStat(
                          CurrencyUtils.format(paymentTotal),
                          'Paid',
                          Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                if (billings.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Text(
                      'Activity across ${billings.length} shops',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CustomerColors.labelGrey,
                      ),
                    ),
                  ),
                CustomerSectionTitle(
                  title: 'Water requests (${requests.length})',
                ),
                if (requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CustomerEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No water requests yet',
                      message:
                          'Open a linked plant from Home and send a request when you need cans.',
                    ),
                  )
                else
                  ...requests.map((order) {
                    final shopName = order.shopId != null
                        ? repo.shopById(order.shopId!)?.name ??
                              'Your water plant'
                        : 'Your water plant';
                    return CustomerRequestCard(
                      order: order,
                      shopName: shopName,
                      delivery: repo.deliveryForOrder(order),
                    );
                  }),
                CustomerSectionTitle(
                  title: 'Deliveries (${allDeliveries.length})',
                ),
                if (allDeliveries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CustomerEmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No deliveries this month',
                      message: 'Your shops will record cans when delivered.',
                    ),
                  )
                else
                  ...allDeliveries.map(
                    (e) => _DeliveryTile(delivery: e.d, shopName: e.shopName),
                  ),
                CustomerSectionTitle(title: 'Payments (${allPayments.length})'),
                if (allPayments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No payments recorded this month',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: CustomerColors.labelGrey,
                      ),
                    ),
                  )
                else
                  ...allPayments.map(
                    (e) => _PaymentTile(payment: e.p, shopName: e.shopName),
                  ),
                const SizedBox(height: 8),
                ...billings.map(
                  (b) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${AppRoutes.customerMonthDetail}?customerId=${b.customer.id}'
                        '&shopId=${b.shop.id}&year=${month.year}&month=${month.month}',
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: Text(
                        '${b.shop.name} — month details',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CustomerColors.accent,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _vDiv() => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white24,
  );

  static Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomerColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({required this.delivery, required this.shopName});

  final Delivery delivery;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: CustomerColors.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CustomerColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: CustomerColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CustomerColors.accent,
                    ),
                  ),
                  Text(
                    delivery.itemsSummary,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${delivery.date.day}/${delivery.date.month}/${delivery.date.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: CustomerColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyUtils.format(delivery.totalAmount),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: CustomerColors.titleNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.shopName});

  final Payment payment;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: CustomerColors.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: Color(0xFF16A34A),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CustomerColors.accent,
                    ),
                  ),
                  Text(
                    payment.method.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${payment.date.day}/${payment.date.month}/${payment.date.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: CustomerColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyUtils.format(payment.amount),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
