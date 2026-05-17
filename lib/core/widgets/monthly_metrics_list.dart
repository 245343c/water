import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';

/// Vertical month metrics — only products delivered this month.
class MonthlyMetricsList extends StatelessWidget {
  const MonthlyMetricsList({
    super.key,
    required this.stats,
    this.labelColor = const Color(0xFF6B7280),
    this.valueColor = const Color(0xFF2563EB),
    this.titleNavy = const Color(0xFF1E3A8A),
    this.dividerColor = const Color(0xFFE5E7EB),
    this.showTotalAndStatus = true,
  });

  final MonthlyStats stats;
  final Color labelColor;
  final Color valueColor;
  final Color titleNavy;
  final Color dividerColor;
  final bool showTotalAndStatus;

  @override
  Widget build(BuildContext context) {
    final statusColor = stats.isPaid ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final rows = stats.summaryRows;
    final isEmpty = !stats.hasDeliveries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEmpty)
          _EmptyMonthHint(labelColor: labelColor)
        else
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: dividerColor),
            _MetricRow(
              row: rows[i],
              labelColor: labelColor,
              valueColor: valueColor,
              icon: _iconForLabel(rows[i].label),
            ),
          ],
        if (showTotalAndStatus) ...[
          Divider(height: 1, color: dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.poppins(fontSize: 11, color: labelColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.format(stats.totalAmount),
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: dividerColor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.poppins(fontSize: 11, color: labelColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('cool')) return Icons.ac_unit_rounded;
    if (lower.contains('normal') || lower.contains('can')) {
      return Icons.water_drop_outlined;
    }
    return Icons.local_drink_outlined;
  }
}

class _EmptyMonthHint extends StatelessWidget {
  const _EmptyMonthHint({required this.labelColor});

  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: labelColor.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No deliveries this month',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.row,
    required this.labelColor,
    required this.valueColor,
    required this.icon,
  });

  final MonthlyStatRow row;
  final Color labelColor;
  final Color valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: valueColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
          Text(
            row.value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
