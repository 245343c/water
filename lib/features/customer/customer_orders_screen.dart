import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/customer_contract_activity_screen.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_request_card.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  Future<void> _confirmCancel(
    BuildContext context,
    WaterPlantRepository repo,
    AuthRepository auth,
    CustomerOrder order,
  ) async {
    final user = auth.currentUser;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel request?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You can cancel before the plant confirms it.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repo.cancelPendingAppOrderInFirebase(
      orderId: order.id,
      appUserId: user.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final userId = auth.currentUser?.id;

    if (userId != null &&
        repo.isMonthlyContractAppUser(userId, phone: auth.currentUser?.phone)) {
      return const CustomerContractActivityScreen();
    }

    final orders = userId != null
        ? repo.ordersForAppUser(userId)
        : <CustomerOrder>[];
    final pending = orders.where((o) => o.isPending).length;

    return CustomerScaffold(
      child: Column(
        children: [
          _OrdersHeader(total: orders.length, pending: pending),
          Expanded(
            child: orders.isEmpty
                ? const CustomerEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No requests yet',
                    message:
                        'Go to Home, choose your linked water plant, and send your first request.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      final shopName = order.shopId != null
                          ? repo.shopById(order.shopId!)?.name ??
                                'Your water plant'
                          : 'Your water plant';
                      return CustomerRequestCard(
                        order: order,
                        shopName: shopName,
                        delivery: repo.deliveryForOrder(order),
                        onEdit: order.canCustomerEdit && order.shopId != null
                            ? () => context.push(
                                '/customer/shop/${order.shopId}?orderId=${order.id}',
                              )
                            : null,
                        onCancel: order.canCustomerCancel
                            ? () => _confirmCancel(context, repo, auth, order)
                            : null,
                      );
                    },
                  ),
          ),
        ],
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
                ? 'Track orders from your linked water plants'
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
