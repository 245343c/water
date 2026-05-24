import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

// ─── Colour palette ──────────────────────────────────────────────────────────

abstract final class MonthlyBillColors {
  static const Color billBlue = Color(0xFF1E40AF);
  static const Color tableNavy = Color(0xFF1E3A8A);
  static const Color titleNavy = AppColors.textPrimary;
  static const Color tableHeaderBg = AppColors.surface;
  static const Color tableTotalBg = Color(0xFFEFF6FF);
  static const Color screenBg = AppColors.surface;
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color balanceRed = Color(0xFFDC2626);
  static const Color primaryBtn = AppColors.primary;
  static const Color whatsappBtn = Color(0xFF25D366);
  static const Color tableBorder = Color(0xFFD1D5DB);
  static const Color cardBorder = AppColors.cardBorder;
  static const Color rowAlt = Color(0xFFF8FAFF);
  static const Color amountGreen = Color(0xFF16A34A);
  static const Color paidStampBg = Color(0xFFDCFCE7);
  static const Color paidStampBorder = Color(0xFF86EFAC);
  static const Color paidStampText = Color(0xFF15803D);
  static const Color qtyBlue = Color(0xFF1D4ED8);
  static const Color dashColor = Color(0xFFD1D5DB);
}

// ─── Bill number ─────────────────────────────────────────────────────────────

String generateBillNumber(String customerId, DateTime month) {
  final idx = customerId.replaceAll(RegExp(r'[^0-9]'), '');
  final num = (idx.isEmpty
      ? customerId.hashCode.abs() % 999
      : int.tryParse(idx) ?? customerId.hashCode.abs() % 999);
  return 'INV/${month.year}/${month.month.toString().padLeft(2, '0')}/'
      '${num.toString().padLeft(3, '0')}';
}

// ─── Product label helpers (shared with PDF service) ─────────────────────────

/// Collect distinct product labels from deliveries, sorted:
/// Normal Can → Cool Can → Bottles by ascending size.
List<String> productLabelsFrom(List<Delivery> deliveries) {
  final seen = <String>{};
  final labels = <String>[];
  for (final d in deliveries) {
    for (final line in d.lines) {
      if (seen.add(line.label)) labels.add(line.label);
    }
  }
  labels.sort((a, b) {
    final pa = _labelPriority(a), pb = _labelPriority(b);
    if (pa != pb) return pa.compareTo(pb);
    if (pa == 2) return _bottleSize(a).compareTo(_bottleSize(b));
    return a.compareTo(b);
  });
  return labels;
}

int _labelPriority(String label) {
  final l = label.toLowerCase();
  if (l.contains('normal')) return 0;
  if (l.contains('cool')) return 1;
  return 2;
}

double _bottleSize(String label) {
  final clean = label.replaceAll(RegExp(r'[^0-9/.]'), '');
  if (clean.contains('/')) {
    final parts = clean.split('/');
    final n = double.tryParse(parts[0]) ?? 0;
    final d = double.tryParse(parts[1]) ?? 1;
    return d > 0 ? n / d : 0;
  }
  return double.tryParse(clean) ?? 999;
}

int _qtyForDelivery(Delivery delivery, String label) {
  return delivery.lines
      .where((l) => l.label == label)
      .fold(0, (s, l) => s + l.quantity);
}

// ─── Scaffold & Header ───────────────────────────────────────────────────────

class MonthlyBillScaffold extends StatelessWidget {
  const MonthlyBillScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PremiumResponsiveBody(maxWidth: 1180, child: child),
    );
  }
}

class MonthlyBillHeader extends StatelessWidget {
  const MonthlyBillHeader({super.key, required this.onBack, this.onShare});
  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Monthly Bill',
      subtitle: 'PDF preview and sharing',
      onBack: onBack,
      trailing: IconButton(
        icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 22),
        onPressed: onShare,
      ),
    );
  }
}

// ─── Main Document Widget ────────────────────────────────────────────────────

class MonthlyBillDocument extends StatelessWidget {
  const MonthlyBillDocument({
    super.key,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    this.businessEmail = '',
    required this.month,
    required this.customer,
    required this.deliveries,
    required this.stats,
  });

  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final DateTime month;
  final Customer customer;
  final List<Delivery> deliveries;
  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    final billNo = generateBillNumber(customer.id, month);
    final productLabels = productLabelsFrom(deliveries);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MonthlyBillColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Letterhead ──────────────────────────────────────────────────
          Text(
            businessName.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MonthlyBillColors.billBlue,
              letterSpacing: 0.8,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            businessAddress,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.45,
              color: MonthlyBillColors.labelGrey,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Ph: $businessPhone',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: MonthlyBillColors.labelGrey,
            ),
          ),
          if (businessEmail.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              businessEmail,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: MonthlyBillColors.labelGrey,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: MonthlyBillColors.cardBorder),
          const SizedBox(height: 10),

          // ── Bill meta ───────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTHLY BILL',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: MonthlyBillColors.billBlue,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      month.monthYear,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: MonthlyBillColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    billNo,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MonthlyBillColors.titleNavy,
                    ),
                  ),
                  Text(
                    'Bill Number',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: MonthlyBillColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: MonthlyBillColors.cardBorder),
          const SizedBox(height: 12),

          // ── Customer details ────────────────────────────────────────────
          _CustomerBlock(customer: customer),
          const SizedBox(height: 16),
          const Divider(color: MonthlyBillColors.cardBorder),
          const SizedBox(height: 14),

          // ── Premium delivery ledger table ────────────────────────────────
          _DeliveryLedger(deliveries: deliveries, productLabels: productLabels),
          const SizedBox(height: 20),

          const Divider(color: MonthlyBillColors.cardBorder),
          const SizedBox(height: 14),

          // ── Financial summary ───────────────────────────────────────────
          _AmountSummary(stats: stats),
          const SizedBox(height: 18),

          // ── PAID stamp ──────────────────────────────────────────────────
          if (stats.isPaid) const _PaidStamp(),

          // ── Footer ──────────────────────────────────────────────────────
          const SizedBox(height: 20),
          Text(
            'Thank you for your business!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MonthlyBillColors.titleNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '— $businessName',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: MonthlyBillColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Block ──────────────────────────────────────────────────────────

class _CustomerBlock extends StatelessWidget {
  const _CustomerBlock({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: MonthlyBillColors.billBlue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: MonthlyBillColors.billBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Customer Details',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: MonthlyBillColors.titleNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CustomerLine(label: 'Customer Name', value: customer.name),
          const SizedBox(height: 8),
          _CustomerLine(label: 'Mobile Number', value: customer.phone),
          if (customer.email.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CustomerLine(label: 'Email', value: customer.email),
          ],
          if (customer.place.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CustomerLine(label: 'Place', value: customer.place),
          ],
          const SizedBox(height: 8),
          _CustomerLine(label: 'Address', value: customer.address),
        ],
      ),
    );
  }
}

class _CustomerLine extends StatelessWidget {
  const _CustomerLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MonthlyBillColors.labelGrey,
              height: 1.4,
            ),
          ),
        ),
        Text(
          ': ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MonthlyBillColors.labelGrey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MonthlyBillColors.titleNavy,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Premium Delivery Ledger Table ───────────────────────────────────────────
//
// Three-section layout to keep # + Date anchored left and Amount anchored right:
//   [Fixed left: # | Date]  [Scrollable middle: product cols]  [Fixed right: Amount]
//
// Fixed row heights ensure the three sections align row-for-row.
//

class _DeliveryLedger extends StatelessWidget {
  const _DeliveryLedger({
    required this.deliveries,
    required this.productLabels,
  });

  final List<Delivery> deliveries;
  final List<String> productLabels;

  // Fixed column widths (px)
  static const _kSnoW = 32.0;
  static const _kDateW = 68.0;
  static const _kAmtW = 76.0;

  // Fixed row heights — applied uniformly across left / middle / right sections
  static const _kHeadH = 46.0;
  static const _kRowH = 46.0;
  static const _kTotalH = 46.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section title
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: MonthlyBillColors.billBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Deliveries This Month',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MonthlyBillColors.titleNavy,
              ),
            ),
            const Spacer(),
            Text(
              '${deliveries.length} '
              '${deliveries.length == 1 ? 'day' : 'days'}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: MonthlyBillColors.labelGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MonthlyBillColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: deliveries.isEmpty ? _ledgerEmpty() : _ledgerTable(),
        ),
      ],
    );
  }

  Widget _ledgerEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 38,
            color: MonthlyBillColors.labelGrey.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            'No deliveries this month',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: MonthlyBillColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledgerTable() {
    final grandTotal = deliveries.fold<double>(0, (s, d) => s + d.totalAmount);

    return Column(
      children: [
        _FlexLedgerRow(
          height: _kHeadH,
          background: MonthlyBillColors.tableNavy,
          isHeader: true,
          cells: [
            _FlexCell.fixed('#', _kSnoW, TextAlign.center, header: true),
            _FlexCell.fixed('Date', _kDateW, TextAlign.left, header: true),
            ...productLabels.map(
              (l) => _FlexCell.expanded(l, TextAlign.center, header: true),
            ),
            _FlexCell.fixed('Amount', _kAmtW, TextAlign.right, header: true),
          ],
        ),
        for (var i = 0; i < deliveries.length; i++)
          _FlexLedgerRow(
            height: _kRowH,
            background: i.isOdd ? MonthlyBillColors.rowAlt : Colors.white,
            cells: [
              _FlexCell.fixed(
                '${i + 1}',
                _kSnoW,
                TextAlign.center,
                muted: true,
              ),
              _FlexCell.fixed(
                deliveries[i].date.dayMonth,
                _kDateW,
                TextAlign.left,
              ),
              ...productLabels.map((label) {
                final qty = _qtyForDelivery(deliveries[i], label);
                return qty > 0
                    ? _FlexCell.expanded('$qty', TextAlign.center, isQty: true)
                    : _FlexCell.expanded('—', TextAlign.center, isDash: true);
              }),
              _FlexCell.fixed(
                CurrencyUtils.format(deliveries[i].totalAmount),
                _kAmtW,
                TextAlign.right,
                isAmount: true,
              ),
            ],
          ),
        _FlexLedgerRow(
          height: _kTotalH,
          background: MonthlyBillColors.tableTotalBg,
          isTotal: true,
          cells: [
            _FlexCell.fixed('', _kSnoW, TextAlign.center, isTotal: true),
            _FlexCell.fixed('Total', _kDateW, TextAlign.left, isTotal: true),
            ...productLabels.map((label) {
              final t = deliveries.fold<int>(
                0,
                (s, d) => s + _qtyForDelivery(d, label),
              );
              return _FlexCell.expanded(
                t > 0 ? '$t' : '—',
                TextAlign.center,
                isTotal: true,
                highlight: t > 0,
              );
            }),
            _FlexCell.fixed(
              CurrencyUtils.format(grandTotal),
              _kAmtW,
              TextAlign.right,
              isTotal: true,
              isAmount: true,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Full-width flex ledger row (auto-fills card width) ────────────────────────

class _FlexCell {
  const _FlexCell._({
    required this.text,
    required this.align,
    this.width,
    this.expanded = false,
    this.header = false,
    this.muted = false,
    this.isQty = false,
    this.isDash = false,
    this.isAmount = false,
    this.isTotal = false,
    this.highlight = false,
  });

  factory _FlexCell.fixed(
    String text,
    double width,
    TextAlign align, {
    bool header = false,
    bool muted = false,
    bool isQty = false,
    bool isDash = false,
    bool isAmount = false,
    bool isTotal = false,
    bool highlight = false,
  }) => _FlexCell._(
    text: text,
    align: align,
    width: width,
    header: header,
    muted: muted,
    isQty: isQty,
    isDash: isDash,
    isAmount: isAmount,
    isTotal: isTotal,
    highlight: highlight,
  );

  factory _FlexCell.expanded(
    String text,
    TextAlign align, {
    bool header = false,
    bool isQty = false,
    bool isDash = false,
    bool isTotal = false,
    bool highlight = false,
  }) => _FlexCell._(
    text: text,
    align: align,
    expanded: true,
    header: header,
    isQty: isQty,
    isDash: isDash,
    isTotal: isTotal,
    highlight: highlight,
  );

  final String text;
  final TextAlign align;
  final double? width;
  final bool expanded;
  final bool header;
  final bool muted;
  final bool isQty;
  final bool isDash;
  final bool isAmount;
  final bool isTotal;
  final bool highlight;
}

class _FlexLedgerRow extends StatelessWidget {
  const _FlexLedgerRow({
    required this.height,
    required this.cells,
    this.background,
    this.isHeader = false,
    this.isTotal = false,
  });

  final double height;
  final List<_FlexCell> cells;
  final Color? background;
  final bool isHeader;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: background,
        border: isTotal
            ? const Border(
                top: BorderSide(color: MonthlyBillColors.tableBorder),
              )
            : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                color: isHeader
                    ? Colors.white.withValues(alpha: 0.22)
                    : MonthlyBillColors.tableBorder,
              ),
            if (cells[i].expanded)
              Expanded(child: _FlexCellWidget(cell: cells[i]))
            else
              _FlexCellWidget(cell: cells[i]),
          ],
        ],
      ),
    );
  }
}

class _FlexCellWidget extends StatelessWidget {
  const _FlexCellWidget({required this.cell});
  final _FlexCell cell;

  @override
  Widget build(BuildContext context) {
    if (cell.isQty && !cell.header && !cell.isTotal) {
      final qty = int.tryParse(cell.text) ?? 0;
      final badge = Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: MonthlyBillColors.qtyBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: MonthlyBillColors.qtyBlue.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            '$qty',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MonthlyBillColors.qtyBlue,
            ),
          ),
        ),
      );
      if (cell.expanded) return badge;
      return SizedBox(width: cell.width, child: badge);
    }

    final style = GoogleFonts.poppins(
      fontSize: cell.header ? 10 : (cell.muted ? 11 : 12),
      fontWeight: cell.header || cell.isTotal
          ? FontWeight.w700
          : (cell.muted ? FontWeight.w400 : FontWeight.w500),
      color: cell.header
          ? Colors.white
          : cell.isDash
          ? MonthlyBillColors.dashColor
          : cell.isAmount
          ? MonthlyBillColors.amountGreen
          : cell.isQty || cell.highlight
          ? MonthlyBillColors.qtyBlue
          : cell.muted
          ? MonthlyBillColors.labelGrey
          : MonthlyBillColors.titleNavy,
    );

    Widget child = Text(
      cell.text,
      textAlign: cell.align,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    if (cell.isDash) {
      child = Text(
        '—',
        textAlign: cell.align,
        style: style.copyWith(color: MonthlyBillColors.dashColor),
      );
    }

    final aligned = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Align(
        alignment: switch (cell.align) {
          TextAlign.center => Alignment.center,
          TextAlign.right => Alignment.centerRight,
          _ => Alignment.centerLeft,
        },
        child: child,
      ),
    );

    if (cell.expanded) return aligned;
    return SizedBox(width: cell.width, child: aligned);
  }
}

// ─── Amount Summary ──────────────────────────────────────────────────────────

class _AmountSummary extends StatelessWidget {
  const _AmountSummary({required this.stats});
  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MonthlyBillColors.tableHeaderBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MonthlyBillColors.cardBorder),
      ),
      child: Column(
        children: [
          _SummaryLine(
            label: 'Total Amount',
            value: CurrencyUtils.format(stats.totalAmount),
          ),
          const SizedBox(height: 8),
          _SummaryLine(
            label: 'Paid Amount',
            value: CurrencyUtils.format(stats.paidAmount),
          ),
          const Divider(height: 16, color: MonthlyBillColors.cardBorder),
          _SummaryLine(
            label: 'Balance Due',
            value: CurrencyUtils.format(stats.balance),
            valueColor: stats.balance > 0
                ? MonthlyBillColors.balanceRed
                : MonthlyBillColors.amountGreen,
            valueLarge: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueLarge = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueLarge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: valueLarge ? 14 : 13,
              fontWeight: FontWeight.w600,
              color: MonthlyBillColors.labelGrey,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: valueLarge ? 18 : 13,
            fontWeight: FontWeight.w800,
            color: valueColor ?? MonthlyBillColors.titleNavy,
          ),
        ),
      ],
    );
  }
}

// ─── PAID Stamp ──────────────────────────────────────────────────────────────

class _PaidStamp extends StatelessWidget {
  const _PaidStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: MonthlyBillColors.paidStampBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MonthlyBillColors.paidStampBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: MonthlyBillColors.paidStampText,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'FULLY PAID',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: MonthlyBillColors.paidStampText,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Bar ──────────────────────────────────────────────────────────────

class MonthlyBillActionBar extends StatelessWidget {
  const MonthlyBillActionBar({
    super.key,
    required this.onDownload,
    required this.onWhatsApp,
  });
  final VoidCallback onDownload;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MonthlyBillColors.screenBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined, size: 20),
                    label: const Text('Download PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: MonthlyBillColors.primaryBtn,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text('Send via WhatsApp'),
                    style: FilledButton.styleFrom(
                      backgroundColor: MonthlyBillColors.whatsappBtn,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
