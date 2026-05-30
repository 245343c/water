import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_request_card.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerContractActivityScreen extends StatelessWidget {
  const CustomerContractActivityScreen({super.key});

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
    final billings = userId != null ? repo.shopBillingsForAppUser(userId) : [];

    if (billings.isEmpty) {
      return CustomerScaffold(
        child: Column(
          children: [
            const _ActivityHeader(),
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

    final requests = userId != null
        ? repo.ordersForAppUser(userId)
        : <CustomerOrder>[];

    return CustomerScaffold(
      child: Column(
        children: [
          const _ActivityHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (billings.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                      onEdit: order.canCustomerEdit && order.shopId != null
                          ? () => context.push(
                              '/customer/shop/${order.shopId}?orderId=${order.id}',
                            )
                          : null,
                      onCancel: order.canCustomerCancel
                          ? () => _confirmCancel(context, repo, auth, order)
                          : null,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: CustomerColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        18,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
