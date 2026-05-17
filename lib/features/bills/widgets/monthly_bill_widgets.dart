import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

// ─── Colour palette ──────────────────────────────────────────────────────────

abstract final class MonthlyBillColors {
  static const Color billBlue        = Color(0xFF1E40AF);
  static const Color tableNavy       = Color(0xFF1E3A8A);
  static const Color titleNavy       = Color(0xFF111827);
  static const Color tableHeaderBg   = Color(0xFFF3F4F6);
  static const Color tableTotalBg    = Color(0xFFEFF6FF);
  static const Color screenBg        = Color(0xFFF3F4F6);
  static const Color labelGrey       = Color(0xFF6B7280);
  static const Color balanceRed      = Color(0xFFDC2626);
  static const Color primaryBtn      = Color(0xFF1A73E8);
  static const Color whatsappBtn     = Color(0xFF25D366);
  static const Color tableBorder     = Color(0xFFD1D5DB);
  static const Color cardBorder      = Color(0xFFE5E7EB);
  static const Color rowAlt          = Color(0xFFF8FAFF);
  static const Color amountGreen     = Color(0xFF16A34A);
  static const Color paidStampBg     = Color(0xFFDCFCE7);
  static const Color paidStampBorder = Color(0xFF86EFAC);
  static const Color paidStampText   = Color(0xFF15803D);
  static const Color qtyBlue         = Color(0xFF1D4ED8);
  static const Color dashColor       = Color(0xFFD1D5DB);
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
  final seen   = <String>{};
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
  if (l.contains('cool'))   return 1;
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
      child: child,
    );
  }
}

class MonthlyBillHeader extends StatelessWidget {
  const MonthlyBillHeader({super.key, required this.onBack, this.onShare});
  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.paddingOf(context).top + 4,
        4,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Monthly Bill (PDF)',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white, size: 22),
            onPressed: onShare,
          ),
        ],
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
    final billNo       = generateBillNumber(customer.id, month);
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
          _DeliveryLedger(
            deliveries: deliveries,
            productLabels: productLabels,
          ),
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
    return Column(
      children: [
        _CustomerLine(label: 'Customer Name', value: customer.name),
        const SizedBox(height: 6),
        _CustomerLine(label: 'Mobile Number', value: customer.phone),
        if (customer.email.isNotEmpty) ...[
          const SizedBox(height: 6),
          _CustomerLine(label: 'Email', value: customer.email),
        ],
        if (customer.place.isNotEmpty) ...[
          const SizedBox(height: 6),
          _CustomerLine(label: 'Place', value: customer.place),
        ],
        const SizedBox(height: 6),
        _CustomerLine(label: 'Address', value: customer.address),
      ],
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
  static const _kSnoW  = 34.0;
  static const _kDateW = 72.0;
  static const _kProdW = 68.0;
  static const _kAmtW  = 84.0;

  // Fixed row heights — applied uniformly across left / middle / right sections
  static const _kHeadH  = 46.0;
  static const _kRowH   = 46.0;
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
              '${deliveries.length == 1 ? 'delivery' : 'deliveries'}',
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
          child: deliveries.isEmpty
              ? _ledgerEmpty()
              : _ledgerTable(),
        ),

        // Scroll hint when product cols overflow
        if (productLabels.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.swipe_right_alt_outlined,
                size: 13,
                color: MonthlyBillColors.labelGrey.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 4),
              Text(
                'Swipe products section to view more',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: MonthlyBillColors.labelGrey.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
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
    final grandTotal =
        deliveries.fold<double>(0, (s, d) => s + d.totalAmount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fixed left: # and Date ───────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeftHeader(),
            ...List.generate(
              deliveries.length,
              (i) => _LeftRow(
                serial: i + 1,
                delivery: deliveries[i],
                isAlt: i.isOdd,
              ),
            ),
            _LeftTotal(),
          ],
        ),

        // Vertical divider between left and middle
        Container(
          width: 1,
          color: MonthlyBillColors.tableBorder,
        ),

        // ── Scrollable middle: one column per product ────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: productLabels.isEmpty
                // No product cols — show just a spacer strip
                ? SizedBox(
                    width: 0,
                    height: _kHeadH +
                        deliveries.length * _kRowH +
                        _kTotalH,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiddleHeader(productLabels: productLabels),
                      ...List.generate(
                        deliveries.length,
                        (i) => _MiddleRow(
                          delivery: deliveries[i],
                          productLabels: productLabels,
                          isAlt: i.isOdd,
                        ),
                      ),
                      _MiddleTotal(
                        deliveries: deliveries,
                        productLabels: productLabels,
                      ),
                    ],
                  ),
          ),
        ),

        // Vertical divider between middle and right
        Container(
          width: 1,
          color: MonthlyBillColors.tableBorder,
        ),

        // ── Fixed right: Amount ──────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RightHeader(),
            ...List.generate(
              deliveries.length,
              (i) => _RightRow(
                delivery: deliveries[i],
                isAlt: i.isOdd,
              ),
            ),
            _RightTotal(grandTotal: grandTotal),
          ],
        ),
      ],
    );
  }
}

// ── Left section: # and Date (fixed, never scrolls) ──────────────────────────

class _LeftHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kHeadH,
      color: MonthlyBillColors.tableNavy,
      child: Row(
        children: [
          _HCell('#', _DeliveryLedger._kSnoW, TextAlign.center),
          _VDiv(header: true),
          _HCell('Date', _DeliveryLedger._kDateW, TextAlign.left),
        ],
      ),
    );
  }
}

class _LeftRow extends StatelessWidget {
  const _LeftRow({
    required this.serial,
    required this.delivery,
    required this.isAlt,
  });
  final int serial;
  final Delivery delivery;
  final bool isAlt;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kRowH,
      color: isAlt ? MonthlyBillColors.rowAlt : Colors.white,
      child: Row(
        children: [
          _DCell(
            '$serial',
            _DeliveryLedger._kSnoW,
            TextAlign.center,
            muted: true,
          ),
          _VDiv(),
          _DCell(
            delivery.date.dayMonth,
            _DeliveryLedger._kDateW,
            TextAlign.left,
          ),
        ],
      ),
    );
  }
}

class _LeftTotal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kTotalH,
      decoration: const BoxDecoration(
        color: MonthlyBillColors.tableTotalBg,
        border: Border(
          top: BorderSide(color: MonthlyBillColors.tableBorder),
        ),
      ),
      child: Row(
        children: [
          _TCell('', _DeliveryLedger._kSnoW, TextAlign.center),
          _VDiv(),
          _TCell('Total', _DeliveryLedger._kDateW, TextAlign.left),
        ],
      ),
    );
  }
}

// ── Middle section: product quantity columns (scrollable) ─────────────────────

class _MiddleHeader extends StatelessWidget {
  const _MiddleHeader({required this.productLabels});
  final List<String> productLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kHeadH,
      color: MonthlyBillColors.tableNavy,
      child: Row(
        children: productLabels.expand((label) => [
              _VDiv(header: true),
              _HCell(label, _DeliveryLedger._kProdW, TextAlign.center),
            ]).toList(),
      ),
    );
  }
}

class _MiddleRow extends StatelessWidget {
  const _MiddleRow({
    required this.delivery,
    required this.productLabels,
    required this.isAlt,
  });
  final Delivery delivery;
  final List<String> productLabels;
  final bool isAlt;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kRowH,
      color: isAlt ? MonthlyBillColors.rowAlt : Colors.white,
      child: Row(
        children: productLabels.expand((label) {
          final qty = _qtyForDelivery(delivery, label);
          return [
            _VDiv(),
            qty > 0
                ? _QtyCell(qty, _DeliveryLedger._kProdW)
                : _DashCell(_DeliveryLedger._kProdW),
          ];
        }).toList(),
      ),
    );
  }
}

class _MiddleTotal extends StatelessWidget {
  const _MiddleTotal({
    required this.deliveries,
    required this.productLabels,
  });
  final List<Delivery> deliveries;
  final List<String> productLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kTotalH,
      decoration: const BoxDecoration(
        color: MonthlyBillColors.tableTotalBg,
        border: Border(top: BorderSide(color: MonthlyBillColors.tableBorder)),
      ),
      child: Row(
        children: productLabels.expand((label) {
          final t = deliveries.fold<int>(
            0,
            (s, d) => s + _qtyForDelivery(d, label),
          );
          return [
            _VDiv(),
            _TCell(
              t > 0 ? '$t' : '—',
              _DeliveryLedger._kProdW,
              TextAlign.center,
              highlight: t > 0,
            ),
          ];
        }).toList(),
      ),
    );
  }
}

// ── Right section: Amount column (fixed, never scrolls) ───────────────────────

class _RightHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kHeadH,
      color: MonthlyBillColors.tableNavy,
      child: _HCell('Amount', _DeliveryLedger._kAmtW, TextAlign.right),
    );
  }
}

class _RightRow extends StatelessWidget {
  const _RightRow({required this.delivery, required this.isAlt});
  final Delivery delivery;
  final bool isAlt;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kRowH,
      color: isAlt ? MonthlyBillColors.rowAlt : Colors.white,
      child: _AmtCell(
        CurrencyUtils.format(delivery.totalAmount),
        _DeliveryLedger._kAmtW,
      ),
    );
  }
}

class _RightTotal extends StatelessWidget {
  const _RightTotal({required this.grandTotal});
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DeliveryLedger._kTotalH,
      decoration: const BoxDecoration(
        color: MonthlyBillColors.tableTotalBg,
        border: Border(top: BorderSide(color: MonthlyBillColors.tableBorder)),
      ),
      child: _TCell(
        CurrencyUtils.format(grandTotal),
        _DeliveryLedger._kAmtW,
        TextAlign.right,
        isGrandTotal: true,
      ),
    );
  }
}

// ── Shared cell widgets ───────────────────────────────────────────────────────

class _HCell extends StatelessWidget {
  const _HCell(this.label, this.width, this.align);
  final String label;
  final double width;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: MonthlyBillColors.tableNavy,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: switch (align) {
        TextAlign.center => Alignment.center,
        TextAlign.right  => Alignment.centerRight,
        _                => Alignment.centerLeft,
      },
      child: Text(
        label,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }
}

class _VDiv extends StatelessWidget {
  const _VDiv({this.header = false});
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: header
          ? Colors.white.withValues(alpha: 0.22)
          : MonthlyBillColors.cardBorder,
    );
  }
}

class _DCell extends StatelessWidget {
  const _DCell(this.text, this.width, this.align, {this.muted = false});
  final String text;
  final double width;
  final TextAlign align;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(
            fontSize: muted ? 11 : 12,
            fontWeight: muted ? FontWeight.w400 : FontWeight.w500,
            color: muted
                ? MonthlyBillColors.labelGrey
                : MonthlyBillColors.titleNavy,
          ),
        ),
      ),
    );
  }
}

class _QtyCell extends StatelessWidget {
  const _QtyCell(this.qty, this.width);
  final int qty;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
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
      ),
    );
  }
}

class _DashCell extends StatelessWidget {
  const _DashCell(this.width);
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        '—',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: MonthlyBillColors.dashColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _AmtCell extends StatelessWidget {
  const _AmtCell(this.amount, this.width);
  final String amount;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          amount,
          textAlign: TextAlign.right,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MonthlyBillColors.amountGreen,
          ),
        ),
      ),
    );
  }
}

class _TCell extends StatelessWidget {
  const _TCell(
    this.text,
    this.width,
    this.align, {
    this.highlight    = false,
    this.isGrandTotal = false,
  });
  final String text;
  final double width;
  final TextAlign align;
  final bool highlight;
  final bool isGrandTotal;

  @override
  Widget build(BuildContext context) {
    final color = isGrandTotal
        ? MonthlyBillColors.amountGreen
        : highlight
            ? MonthlyBillColors.qtyBlue
            : MonthlyBillColors.titleNavy;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
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
