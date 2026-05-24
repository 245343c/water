import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_summary_widgets.dart';

void showMonthlyDeliveriesSheet(
  BuildContext context, {
  required Customer customer,
  required DateTime month,
  required List<Delivery> deliveries,
}) {
  final total = deliveries.fold<double>(0, (s, d) => s + d.totalAmount);
  _showMonthlyDetailSheet(
    context,
    title: 'Deliveries',
    subtitle: '${customer.name} · ${month.monthYear}',
    accent: const Color(0xFF2563EB),
    accentLight: const Color(0xFFEFF6FF),
    icon: Icons.local_shipping_rounded,
    statLeftLabel: 'Trips',
    statLeftValue: '${deliveries.length}',
    statRightLabel: 'Total value',
    statRightValue: CurrencyUtils.format(total),
    emptyTitle: 'No deliveries',
    emptySubtitle: 'No deliveries recorded for ${month.monthYear}.',
    itemCount: deliveries.length,
    itemBuilder: (i) => _DeliverySheetTile(delivery: deliveries[i], customer: customer),
  );
}

void showMonthlyPaymentsSheet(
  BuildContext context, {
  required Customer customer,
  required DateTime month,
  required List<Payment> payments,
}) {
  final total = payments.fold<double>(0, (s, p) => s + p.amount);
  _showMonthlyDetailSheet(
    context,
    title: 'Payments',
    subtitle: '${customer.name} · ${month.monthYear}',
    accent: const Color(0xFF059669),
    accentLight: const Color(0xFFECFDF5),
    icon: Icons.account_balance_wallet_rounded,
    statLeftLabel: 'Payments',
    statLeftValue: '${payments.length}',
    statRightLabel: 'Collected',
    statRightValue: CurrencyUtils.format(total),
    emptyTitle: 'No payments',
    emptySubtitle: 'No payments recorded for ${month.monthYear}.',
    itemCount: payments.length,
    itemBuilder: (i) => _PaymentSheetTile(payment: payments[i], customer: customer),
  );
}

void _showMonthlyDetailSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Color accent,
  required Color accentLight,
  required IconData icon,
  required String statLeftLabel,
  required String statLeftValue,
  required String statRightLabel,
  required String statRightValue,
  required String emptyTitle,
  required String emptySubtitle,
  required int itemCount,
  required Widget Function(int index) itemBuilder,
}) {
  final isEmpty = itemCount == 0;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: isEmpty ? 0.44 : 0.62,
      minChildSize: 0.38,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, accent.withValues(alpha: 0.85)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: MonthlySummaryColors.titleNavy,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: MonthlySummaryColors.labelGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: statLeftLabel,
                        value: statLeftValue,
                        color: accent,
                        bg: accentLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: statRightLabel,
                        value: statRightValue,
                        color: accent,
                        bg: accentLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isEmpty
                    ? _EmptySheetState(title: emptyTitle, subtitle: emptySubtitle)
                    : ListView.separated(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
                        itemCount: itemCount,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => itemBuilder(i),
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: MonthlySummaryColors.labelGrey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySheetState extends StatelessWidget {
  const _EmptySheetState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 52,
              color: MonthlySummaryColors.labelGrey.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MonthlySummaryColors.titleNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: MonthlySummaryColors.labelGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliverySheetTile extends StatelessWidget {
  const _DeliverySheetTile({required this.delivery, required this.customer});

  final Delivery delivery;
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<WaterPlantRepository>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.date.fullDate,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MonthlySummaryColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  delivery.itemsSummary,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: MonthlySummaryColors.labelGrey,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyUtils.format(delivery.totalAmount),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2563EB),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Delete delivery?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    content: Text('${customer.name} · ${delivery.date.fullDate}', style: GoogleFonts.poppins()),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await repo.deleteDelivery(delivery.id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentSheetTile extends StatelessWidget {
  const _PaymentSheetTile({required this.payment, required this.customer});

  final Payment payment;
  final Customer customer;

  IconData _methodIcon(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => Icons.payments_outlined,
      PaymentMethod.upi => Icons.qr_code_2_rounded,
      PaymentMethod.other => Icons.receipt_long_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<WaterPlantRepository>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF059669).withValues(alpha: 0.15),
                  const Color(0xFF10B981).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _methodIcon(payment.method),
              color: const Color(0xFF059669),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyUtils.format(payment.amount),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.date.fullDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: MonthlySummaryColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              payment.method.label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF059669),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Delete payment?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    content: Text('${customer.name} · ${CurrencyUtils.format(payment.amount)}', style: GoogleFonts.poppins()),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await repo.deletePayment(payment.id);
                }
              } else if (v == 'edit') {
                final amountCtrl = TextEditingController(text: payment.amount.toStringAsFixed(0));
                final notesCtrl = TextEditingController(text: payment.notes ?? '');
                final saved = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Edit payment', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Amount'),
                        ),
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'Notes (optional)'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                    ],
                  ),
                );
                if (saved == true) {
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? payment.amount;
                  await repo.updatePayment(
                    paymentId: payment.id,
                    customerId: payment.customerId,
                    amount: amount,
                    date: payment.date,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
