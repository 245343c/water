import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/customer_display_localization.dart';
import 'package:sri_sai_ro_water/core/localization/delivery_localization.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Teal bar only at top — no full-page gradient (avoids colour bleed top-left).
class DriverCustomerDetailBar extends StatelessWidget {
  const DriverCustomerDetailBar({
    super.key,
    required this.customer,
    required this.onBack,
    required this.deliveredToday,
  });

  final Customer customer;
  final VoidCallback onBack;
  final bool deliveredToday;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DriverColors.headerStart,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.paddingOf(context).top + 6,
        12,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.driverDisplayName(strings),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(deliveredToday: deliveredToday),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.deliveredToday});

  final bool deliveredToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: deliveredToday
            ? DriverColors.success.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        deliveredToday ? context.l10n.done : context.l10n.pending,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Simple white section card on flat background.
class DriverContentCard extends StatelessWidget {
  const DriverContentCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: DriverColors.whiteCard,
      child: child,
    );
  }
}

class DriverContactRow extends StatelessWidget {
  const DriverContactRow({
    super.key,
    required this.onDirections,
    required this.onCall,
  });

  final VoidCallback onDirections;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactButton(
            icon: Icons.directions_rounded,
            label: context.l10n.directions,
            filled: false,
            onTap: onDirections,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ContactButton(
            icon: Icons.phone_rounded,
            label: context.l10n.call,
            filled: true,
            onTap: onCall,
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? DriverColors.accent : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: DriverColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : DriverColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : DriverColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverAddressBlock extends StatelessWidget {
  const DriverAddressBlock({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final addressNote = customer.driverAddressNote(strings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customer.place.isNotEmpty) ...[
          Text(
            customer.place,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DriverColors.titleNavy,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          addressNote.isNotEmpty ? addressNote : customer.address,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: DriverColors.labelGrey,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class DriverLastVisitLine extends StatelessWidget {
  const DriverLastVisitLine({
    super.key,
    this.lastDelivery,
    required this.deliveredToday,
  });

  final Delivery? lastDelivery;
  final bool deliveredToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          deliveredToday ? Icons.check_circle_outline : Icons.schedule,
          size: 18,
          color: deliveredToday ? DriverColors.success : DriverColors.labelGrey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lastDelivery == null
                ? context.l10n.noPreviousVisit
                : _summary(context, lastDelivery!),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DriverColors.labelGrey,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  String _summary(BuildContext context, Delivery d) {
    final strings = context.l10n;
    final when = d.date.fullDate;
    if (d.isEmptyReturnOnly) {
      return strings.lastVisit(
        when,
        strings.emptyReturnedCount(d.totalEmptyReturned),
      );
    }
    return strings.lastVisit(when, strings.deliveryItemsSummary(d));
  }
}

class DriverRouteNoteLine extends StatelessWidget {
  const DriverRouteNoteLine({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.flag_outlined, size: 18, color: DriverColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            note,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DriverColors.titleNavy,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class DriverSectionLabel extends StatelessWidget {
  const DriverSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DriverColors.labelGrey,
        ),
      ),
    );
  }
}
