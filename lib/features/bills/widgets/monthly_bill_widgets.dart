import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class MonthlyBillColors {
  static const Color billBlue = Color(0xFF1E40AF);
  static const Color titleNavy = Color(0xFF111827);
  static const Color tableHeaderBg = Color(0xFFF3F4F6);
  static const Color tableTotalBg = Color(0xFFEFF6FF);
  static const Color screenBg = Color(0xFFF3F4F6);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color balanceRed = Color(0xFFDC2626);
  static const Color primaryBtn = Color(0xFF1A73E8);
  static const Color whatsappBtn = Color(0xFF25D366);
  static const Color tableBorder = Color(0xFFD1D5DB);
  static const Color cardBorder = Color(0xFFE5E7EB);
}

class MonthlyBillHeader extends StatelessWidget {
  const MonthlyBillHeader({
    super.key,
    required this.onBack,
    this.onShare,
  });

  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 4, 16),
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

  int get _normalTotal => deliveries.fold(0, (s, d) => s + d.normalQty);
  int get _coolTotal => deliveries.fold(0, (s, d) => s + d.coolQty);
  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            businessName.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MonthlyBillColors.billBlue,
              letterSpacing: 0.6,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            businessAddress,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.45,
              color: MonthlyBillColors.labelGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ph: $businessPhone',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11, color: MonthlyBillColors.labelGrey),
          ),
          if (businessEmail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              businessEmail,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: MonthlyBillColors.labelGrey),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'MONTHLY BILL - ${month.monthYear}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MonthlyBillColors.billBlue,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 20),
          _CustomerBlock(customer: customer),
          const SizedBox(height: 20),
          _BillTable(
            deliveries: deliveries,
            stats: stats,
            normalTotal: _normalTotal,
            coolTotal: _coolTotal,
            amountTotal: stats.totalAmount,
          ),
          const SizedBox(height: 18),
          _AmountSummary(stats: stats),
          const SizedBox(height: 22),
          Text(
            'Thank you!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MonthlyBillColors.titleNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '- $businessName',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: MonthlyBillColors.labelGrey),
          ),
        ],
      ),
    );
  }
}

class _CustomerBlock extends StatelessWidget {
  const _CustomerBlock({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          width: 108,
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

class _BillTable extends StatelessWidget {
  const _BillTable({
    required this.deliveries,
    required this.stats,
    required this.normalTotal,
    required this.coolTotal,
    required this.amountTotal,
  });

  final List<Delivery> deliveries;
  final MonthlyStats stats;
  final int normalTotal;
  final int coolTotal;
  final double amountTotal;

  static const _headers = ['Date', 'Description', 'Normal', 'Cool', 'Amount'];
  static const _colWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(1.3),
    1: FlexColumnWidth(1.5),
    2: FlexColumnWidth(0.85),
    3: FlexColumnWidth(0.85),
    4: FlexColumnWidth(1.2),
  };

  String _bottleTotalNote() {
    if (stats.bottleUnits <= 0) return '';
    final parts = stats.bottlesByLabel.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.value}×${e.key}')
        .join(', ');
    return parts.isEmpty ? '' : 'Bottles: $parts';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      if (deliveries.isEmpty)
        ['—', 'No deliveries', '0', '0', CurrencyUtils.format(0)]
      else
        ...deliveries.map(
          (d) => [
            d.date.dayMonth,
            d.billTableDescription,
            '${d.normalQty}',
            '${d.coolQty}',
            CurrencyUtils.format(d.totalAmount),
          ],
        ),
    ];
    final bottleNote = _bottleTotalNote();

    return Table(
      border: TableBorder.all(color: MonthlyBillColors.tableBorder, width: 1),
      columnWidths: _colWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: MonthlyBillColors.tableHeaderBg),
          children: _headers
              .map((h) => _TableCell(text: h, bold: true, isHeader: true))
              .toList(),
        ),
        ...rows.map(
          (cells) => TableRow(
            children: [
              for (var i = 0; i < cells.length; i++)
                _TableCell(
                  text: cells[i],
                  align: i >= 2 && i < 4 ? TextAlign.center : (i == 4 ? TextAlign.end : TextAlign.start),
                  amountCol: i == 4,
                ),
            ],
          ),
        ),
        TableRow(
          decoration: const BoxDecoration(color: MonthlyBillColors.tableTotalBg),
          children: [
            _TableCell(text: 'Total', bold: true),
            _TableCell(text: bottleNote, bold: true),
            _TableCell(text: '$normalTotal', bold: true, align: TextAlign.center),
            _TableCell(text: '$coolTotal', bold: true, align: TextAlign.center),
            _TableCell(
              text: CurrencyUtils.format(amountTotal),
              bold: true,
              align: TextAlign.end,
              amountCol: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.text,
    this.bold = false,
    this.isHeader = false,
    this.align = TextAlign.start,
    this.amountCol = false,
  });

  final String text;
  final bool bold;
  final bool isHeader;
  final TextAlign align;
  final bool amountCol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.poppins(
          fontSize: isHeader ? 10 : 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? MonthlyBillColors.titleNavy : const Color(0xFF374151),
        ),
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  const _AmountSummary({required this.stats});

  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _SummaryLine(label: 'Total Amount', value: CurrencyUtils.format(stats.totalAmount)),
        const SizedBox(height: 8),
        _SummaryLine(label: 'Paid Amount', value: CurrencyUtils.format(stats.paidAmount)),
        const SizedBox(height: 8),
        _SummaryLine(
          label: 'Balance Amount',
          value: CurrencyUtils.format(stats.balance),
          valueColor: MonthlyBillColors.balanceRed,
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 13, color: MonthlyBillColors.titleNavy),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor ?? MonthlyBillColors.titleNavy,
            ),
          ),
        ],
      ),
    );
  }
}

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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
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
