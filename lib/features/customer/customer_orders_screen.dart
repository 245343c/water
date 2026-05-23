import 'package:flutter/material.dart';
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
            'Requests',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Track water requests from your linked plants'
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
