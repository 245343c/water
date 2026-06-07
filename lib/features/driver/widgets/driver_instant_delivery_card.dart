import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/customer_display_localization.dart';
import 'package:sri_sai_ro_water/core/localization/delivery_localization.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Instant / phone-call job card on driver route.
class DriverInstantDeliveryCard extends StatelessWidget {
  const DriverInstantDeliveryCard({
    super.key,
    required this.order,
    required this.repo,
    required this.driverId,
    required this.estimatedTotal,
  });

  final CustomerOrder order;
  final WaterPlantRepository repo;
  final String? driverId;
  final double estimatedTotal;

  @override
  Widget build(BuildContext context) {
    final walkIn = order.walkInContact;
    final customer = repo.customerById(order.customerId);
    final strings = context.l10n;
    final name =
        walkIn?.name ?? customer?.driverDisplayName(strings) ?? strings.instant;
    final phone = walkIn?.phone ?? customer?.phone ?? '';
    final address = walkIn?.address ?? customer?.address ?? '';
    final localAddress = customer?.driverAddressNote(strings) ?? '';
    final place = walkIn?.place ??
        (localAddress.isNotEmpty ? localAddress : customer?.place) ??
        '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () => context.push(
            '/driver/customers/${order.customerId}?orderId=${order.id}',
          ),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.06),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF7C3AED),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DriverColors.titleNavy,
                            ),
                          ),
                          Text(
                            order.createdAt.timeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: DriverColors.labelGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        strings.collectCash,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (phone.isNotEmpty)
                  _RowIcon(
                    icon: Icons.phone_outlined,
                    text: phone,
                  ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _RowIcon(
                    icon: Icons.location_on_outlined,
                    text: place.isNotEmpty ? '$place · $address' : address,
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: DriverColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.orderItemsSummary(order),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DriverColors.titleNavy,
                          ),
                        ),
                      ),
                      if (estimatedTotal > 0)
                        Text(
                          CurrencyUtils.format(estimatedTotal),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                if (order.customerNote != null &&
                    order.customerNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    order.customerNote!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: DriverColors.labelGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/driver/customers/${order.customerId}?orderId=${order.id}',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: DriverColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.local_shipping_outlined, size: 20),
                  label: Text(
                    strings.openDeliver,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DriverColors.labelGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DriverColors.titleNavy,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
