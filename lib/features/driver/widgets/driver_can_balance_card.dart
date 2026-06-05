import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/constants/empty_can_balance.dart';
import 'package:sri_sai_ro_water/data/models/customer_can_balance.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Empty can balance with customer — driver teal styling only.
class DriverCanBalanceCard extends StatelessWidget {
  const DriverCanBalanceCard({
    super.key,
    required this.balance,
    required this.showNormal,
    required this.showCool,
    required this.onRecordReturn,
  });

  final CustomerCanBalance balance;
  final bool showNormal;
  final bool showCool;
  final VoidCallback onRecordReturn;

  @override
  Widget build(BuildContext context) {
    if (!showNormal && !showCool) return const SizedBox.shrink();

    final total = (showNormal ? balance.normalWithCustomer : 0) +
        (showCool ? balance.coolWithCustomer : 0);
    final showJarWarning = emptyCanCountIsWarning(total);

    return Container(
        padding: const EdgeInsets.all(14),
        decoration: DriverColors.whiteCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DriverColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: DriverColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Empty cans with customer',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.titleNavy,
                        ),
                      ),
                      Text(
                        total > 0
                            ? (showJarWarning
                                ? '$total jars out — collect before delivering more'
                                : '$total still out · collect when you can')
                            : 'All empty cans returned',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: showJarWarning
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: showJarWarning
                              ? const Color(0xFFDC2626)
                              : DriverColors.labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showNormal || showCool) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (showNormal)
                    Expanded(
                      child: _BalanceTile(
                        label: 'Normal',
                        withCustomer: balance.normalWithCustomer,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  if (showNormal && showCool) const SizedBox(width: 8),
                  if (showCool)
                    Expanded(
                      child: _BalanceTile(
                        label: 'Cool',
                        withCustomer: balance.coolWithCustomer,
                        color: DriverColors.accent,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRecordReturn,
                icon: const Icon(Icons.recycling_rounded, size: 18),
                label: Text(
                  'Return empties only',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DriverColors.accent,
                  side: const BorderSide(color: DriverColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.label,
    required this.withCustomer,
    required this.color,
  });

  final String label;
  final int withCustomer;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final countColor = emptyCanCountColor(withCustomer, normalColor: color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: countColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emptyCanCountIsWarning(withCustomer)
              ? const Color(0xFFFECACA)
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: DriverColors.labelGrey,
            ),
          ),
          Text(
            '$withCustomer',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: countColor,
            ),
          ),
          Text(
            'with customer',
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: DriverColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}
