import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerContractActivityScreen extends StatelessWidget {
  const CustomerContractActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final userId = auth.currentUser?.id;
    final crm = userId != null ? repo.linkedCrmCustomerForAppUser(userId) : null;

    if (crm == null) {
      return Scaffold(
        backgroundColor: CustomerColors.screenBg,
        body: CustomerScaffold(
          child: Column(
            children: [
              const CustomerHeader(title: 'Activity', subtitle: 'This month'),
              const Expanded(
                child: CustomerEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No activity',
                  message: 'Link your account with your shop first.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final deliveries = repo.deliveriesForCustomer(crm.id, month: month);
    final payments = repo.paymentsForCustomer(crm.id, month: month);
    final deliveryTotal =
        deliveries.fold<double>(0, (s, d) => s + d.totalAmount);
    final paymentTotal = payments.fold<double>(0, (s, p) => s + p.amount);

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          children: [
            CustomerHeader(
              title: 'Activity',
              subtitle: month.monthYear,
            ),
            Expanded(
              child: ListView(
                children: [
                  CustomerHeroStats(
                    leftLabel: 'Deliveries',
                    leftValue: '${deliveries.length}',
                    centerLabel: 'Cans value',
                    centerValue: CurrencyUtils.format(deliveryTotal),
                    rightLabel: 'Paid',
                    rightValue: CurrencyUtils.format(paymentTotal),
                  ),
                  CustomerSectionTitle(
                    title: 'Deliveries (${deliveries.length})',
                  ),
                  if (deliveries.isEmpty)
                    _empty('No deliveries this month')
                  else
                    ...deliveries.take(12).map(_deliveryTile),
                  CustomerSectionTitle(title: 'Payments (${payments.length})'),
                  if (payments.isEmpty)
                    _empty('No payments this month')
                  else
                    ...payments.take(12).map(_paymentTile),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _empty(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: CustomerColors.cardDecoration,
        child: Text(
          msg,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: CustomerColors.labelGrey,
          ),
        ),
      ),
    );
  }

  static Widget _deliveryTile(Delivery d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: CustomerColors.cardDecoration,
        child: Row(
          children: [
            const Icon(Icons.local_shipping_rounded, color: CustomerColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d.normalQty + d.coolQty} cans',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    d.date.dayMonth,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: CustomerColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyUtils.format(d.totalAmount),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: CustomerColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _paymentTile(Payment p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: CustomerColors.cardDecoration,
        child: Row(
          children: [
            const Icon(Icons.payments_rounded, color: CustomerColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.method.label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    p.date.dayMonth,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: CustomerColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyUtils.format(p.amount),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: CustomerColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
