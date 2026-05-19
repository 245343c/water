import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/customer_contract_activity_screen.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pending => CustomerColors.warning,
        OrderStatus.accepted => CustomerColors.success,
        OrderStatus.rejected => const Color(0xFFDC2626),
      };

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
            CustomerHeader(
              title: 'My orders',
              subtitle: orders.isEmpty
                  ? 'Orders you place appear here'
                  : '$pending pending · ${orders.length} total',
            ),
            Expanded(
              child: orders.isEmpty
                  ? const CustomerEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      message:
                          'Go to Home, search a shop, and place your first order.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: orders.length,
                      itemBuilder: (context, i) {
                        final o = orders[i];
                        final shop =
                            o.shopId != null ? repo.shopById(o.shopId!) : null;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {},
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _statusColor(o.status)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shop?.name ?? 'Water order',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(o.status)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            o.status.label,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _statusColor(o.status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      o.cansSummary,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: CustomerColors.labelGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatDate(o.createdAt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: CustomerColors.labelGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
