import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

class DeliveriesDayHeader extends StatelessWidget {
  const DeliveriesDayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: CustomersColors.addButton,
        ),
      ),
    );
  }
}

class DeliveryListCard extends StatelessWidget {
  const DeliveryListCard({
    super.key,
    required this.customerName,
    required this.initials,
    required this.colorIndex,
    required this.delivery,
    required this.onTap,
  });

  final String customerName;
  final String initials;
  final int colorIndex;
  final Delivery delivery;
  final VoidCallback onTap;

  String _time(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final accent = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CustomersColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.withValues(alpha: 0.14),
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CustomersColors.titleNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.water_drop_outlined,
                        text: delivery.cansSummary,
                      ),
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.access_time,
                        text: _time(delivery.date),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.format(delivery.totalAmount),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CustomersColors.balanceGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Delivered',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CustomersColors.addButton,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CustomersColors.labelGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 11, color: CustomersColors.labelGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String deliveriesDayLabel(DateTime date, DateTime today) {
  final yesterday = today.subtract(const Duration(days: 1));
  if (_sameDay(date, today)) return 'Today';
  if (_sameDay(date, yesterday)) return 'Yesterday';
  return date.fullDate;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Groups deliveries: [Today] first, then newer days first; latest delivery on top per day.
List<({String label, List<Delivery> items})> groupDeliveriesByDay(
  List<Delivery> deliveries,
  DateTime referenceNow,
) {
  if (deliveries.isEmpty) return [];

  final todayStart = DateTime(referenceNow.year, referenceNow.month, referenceNow.day);

  final sorted = List<Delivery>.from(deliveries)
    ..sort((a, b) {
      final cmp = b.date.compareTo(a.date);
      return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
    });

  final byDay = <DateTime, List<Delivery>>{};
  for (final d in sorted) {
    final key = DateTime(d.date.year, d.date.month, d.date.day);
    byDay.putIfAbsent(key, () => []).add(d);
  }

  int daySortKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (_sameDay(d, todayStart)) return 0;
    if (d.isAfter(todayStart)) return d.difference(todayStart).inDays;
    return 1000 + todayStart.difference(d).inDays;
  }

  final days = byDay.keys.toList()..sort((a, b) => daySortKey(a).compareTo(daySortKey(b)));

  return [
    for (final day in days)
      (
        label: deliveriesDayLabel(day, referenceNow),
        items: byDay[day]!,
      ),
  ];
}
