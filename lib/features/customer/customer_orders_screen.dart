import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_card.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/customer_contract_activity_screen.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final userId = auth.currentUser?.id;

    if (userId != null &&
        repo.isMonthlyContractAppUser(userId, phone: auth.currentUser?.phone)) {
      return const CustomerContractActivityScreen();
    }

    final orders =
        userId != null ? repo.ordersForAppUser(userId) : <CustomerOrder>[];
    final pending = orders.where((o) => o.isPending).length;

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          children: [
            _OrdersHeader(
              total: orders.length,
              pending: pending,
            ),
            Expanded(
              child: orders.isEmpty
                  ? const CustomerEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      message:
                          'Go to Home, choose your linked water plant, and send your first request.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: orders.length,
                      itemBuilder: (context, i) => _OrderCard(
                        order: orders[i],
                        shopName: orders[i].shopId != null
                            ? repo.shopById(orders[i].shopId!)?.name
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.total, required this.pending});

  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            'My orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Track home delivery orders'
                : '$pending pending · $total total',
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.shopName});

  final CustomerOrder order;
  final String? shopName;

  Color get _statusColor => switch (order.status) {
        OrderStatus.pending => CustomerColors.warning,
        OrderStatus.accepted => CustomerColors.success,
        OrderStatus.rejected => const Color(0xFFDC2626),
      };

  IconData get _statusIcon => switch (order.status) {
        OrderStatus.pending => Icons.schedule_rounded,
        OrderStatus.accepted => Icons.check_circle_rounded,
        OrderStatus.rejected => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CustomerColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: _statusColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shopName ?? 'Water order',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: CustomerColors.titleNavy,
                                ),
                              ),
                            ),
                            PremiumStatusBadge(
                              label: order.status.label,
                              color: _statusColor,
                              icon: _statusIcon,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.water_drop_outlined,
                                size: 16, color: CustomerColors.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.cansSummary,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: CustomerColors.labelGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _OrderStatusMessage(order: order),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(order.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: CustomerColors.labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _OrderStatusMessage extends StatelessWidget {
  const _OrderStatusMessage({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      OrderStatus.pending => CustomerColors.warning,
      OrderStatus.accepted => CustomerColors.success,
      OrderStatus.rejected => const Color(0xFFDC2626),
    };
    final icon = switch (order.status) {
      OrderStatus.pending => Icons.hourglass_bottom_rounded,
      OrderStatus.accepted => Icons.local_shipping_rounded,
      OrderStatus.rejected => Icons.info_outline_rounded,
    };
    final text = switch (order.status) {
      OrderStatus.pending => 'Waiting for your water plant to confirm.',
      OrderStatus.accepted =>
        order.adminResponse ?? 'Confirmed. Driver will deliver soon.',
      OrderStatus.rejected =>
        order.adminResponse == null || order.adminResponse!.trim().isEmpty
            ? 'Declined by your water plant.'
            : 'Declined: ${order.adminResponse}',
    };

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.04),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: CustomerColors.titleNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
