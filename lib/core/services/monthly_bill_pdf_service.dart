import 'dart:io';
import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_bill_widgets.dart'
    show generateBillNumber;

/// Builds professional A4/landscape monthly bill PDFs.
/// Table columns are auto-generated — one column per distinct product
/// delivered this month. Automatically switches to landscape when there
/// are more than 4 product columns.
abstract final class MonthlyBillPdfService {
  // ── Colours ─────────────────────────────────────────────────────────────────
  static const _billBlue    = PdfColor.fromInt(0xFF1E40AF);
  static const _tableNavy   = PdfColor.fromInt(0xFF1E3A8A);
  static const _altRowBg    = PdfColor.fromInt(0xFFF8FAFF);
  static const _totalBg     = PdfColor.fromInt(0xFFEFF6FF);
  static const _headerBg    = PdfColor.fromInt(0xFFF3F4F6);
  static const _paidBg      = PdfColor.fromInt(0xFFDCFCE7);
  static const _paidGreen   = PdfColor.fromInt(0xFF15803D);
  static const _border      = PdfColor.fromInt(0xFFD1D5DB);
  static const _balanceRed  = PdfColor.fromInt(0xFFDC2626);
  static const _textDark    = PdfColor.fromInt(0xFF111827);
  static const _textGrey    = PdfColor.fromInt(0xFF6B7280);
  static const _amountGreen = PdfColor.fromInt(0xFF16A34A);
  static const _qtyBlue     = PdfColor.fromInt(0xFF1D4ED8);
  static const _dashColor   = PdfColor.fromInt(0xFFCBD5E1);

  // A4 Landscape (width ↔ height swapped)
  static final _a4Landscape = PdfPageFormat(
    PdfPageFormat.a4.height,
    PdfPageFormat.a4.width,
  );

  // ── Public API ───────────────────────────────────────────────────────────────

  static Future<File> buildAndSave({
    required String businessName,
    required String businessAddress,
    required String businessPhone,
    String businessEmail = '',
    required DateTime month,
    required Customer customer,
    required List<Delivery> deliveries,
    required MonthlyStats stats,
  }) async {
    final bytes = await buildPdf(
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      businessEmail: businessEmail,
      month: month,
      customer: customer,
      deliveries: deliveries,
      stats: stats,
    );
    return _writeTemp(bytes, _fileName(customer.name, month));
  }

  static Future<List<int>> buildPdf({
    required String businessName,
    required String businessAddress,
    required String businessPhone,
    String businessEmail = '',
    required DateTime month,
    required Customer customer,
    required List<Delivery> deliveries,
    required MonthlyStats stats,
  }) async {
    final doc = await _document(
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      businessEmail: businessEmail,
      month: month,
      customer: customer,
      deliveries: deliveries,
      stats: stats,
    );
    return doc.save();
  }

  // ── Document builder ─────────────────────────────────────────────────────────

  static Future<pw.Document> _document({
    required String businessName,
    required String businessAddress,
    required String businessPhone,
    String businessEmail = '',
    required DateTime month,
    required Customer customer,
    required List<Delivery> deliveries,
    required MonthlyStats stats,
  }) async {
    final regular = await PdfGoogleFonts.poppinsRegular();
    final bold    = await PdfGoogleFonts.poppinsBold();

    // ── Determine columns & orientation ─────────────────────────────────────
    // Gather all distinct product labels that were actually delivered
    final productLabels = _extractProductLabels(deliveries);
    // Total columns: # | Date | [product…] | Amount
    final totalCols   = 3 + productLabels.length;
    final useLandscape = totalCols > 6; // switch to landscape for wide tables

    final pageFormat = useLandscape ? _a4Landscape : PdfPageFormat.a4;
    final margin     = useLandscape
        ? const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36)
        : const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40);

    final billNo = generateBillNumber(customer.id, month);
    final isPaid = stats.isPaid;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: margin,
        build: (context) {
          final content = <pw.Widget>[
            // ── Letterhead ───────────────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                businessName.toUpperCase(),
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 17,
                  color: _billBlue,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                businessAddress,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: _textGrey,
                  lineSpacing: 1.4,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Ph: $businessPhone'
                '${businessEmail.isNotEmpty ? '  |  $businessEmail' : ''}',
                style: pw.TextStyle(font: regular, fontSize: 9, color: _textGrey),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: _border, height: 1),
            pw.SizedBox(height: 12),

            // ── Bill meta row ────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MONTHLY BILL',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 14,
                        color: _billBlue,
                        letterSpacing: 0.6,
                      ),
                    ),
                    pw.Text(
                      month.monthYear,
                      style: pw.TextStyle(
                        font: regular,
                        fontSize: 10,
                        color: _textGrey,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      billNo,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: _textDark,
                      ),
                    ),
                    pw.Text(
                      'Bill Number',
                      style: pw.TextStyle(
                        font: regular,
                        fontSize: 9,
                        color: _textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: _border, height: 1),
            pw.SizedBox(height: 14),

            // ── Customer info ────────────────────────────────────────────────
            _customerLine('Customer Name', customer.name, regular, bold),
            pw.SizedBox(height: 6),
            _customerLine('Mobile Number', customer.phone, regular, bold),
            if (customer.email.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              _customerLine('Email', customer.email, regular, bold),
            ],
            if (customer.place.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              _customerLine('Place', customer.place, regular, bold),
            ],
            pw.SizedBox(height: 6),
            _customerLine('Address', customer.address, regular, bold),
            pw.SizedBox(height: 20),

            // ── Deliveries table (dynamic columns) ───────────────────────────
            _billTable(
              regular: regular,
              bold: bold,
              productLabels: productLabels,
              deliveries: deliveries,
              amountTotal: stats.totalAmount,
            ),
            pw.SizedBox(height: 22),

            // ── Financial summary ────────────────────────────────────────────
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 230,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _headerBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _border, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _summaryLine(
                      'Total Amount',
                      CurrencyUtils.format(stats.totalAmount),
                      regular,
                      bold,
                    ),
                    pw.SizedBox(height: 6),
                    _summaryLine(
                      'Paid Amount',
                      CurrencyUtils.format(stats.paidAmount),
                      regular,
                      bold,
                    ),
                    pw.Divider(color: _border, height: 12),
                    _summaryLine(
                      'Balance Due',
                      CurrencyUtils.format(stats.balance),
                      regular,
                      bold,
                      valueColor:
                          stats.balance > 0 ? _balanceRed : _amountGreen,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),

            // ── PAID stamp ───────────────────────────────────────────────────
            if (isPaid) ...[
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _paidBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _paidGreen, width: 1.5),
                  ),
                  child: pw.Text(
                    '✓  FULLY PAID',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 14,
                      color: _paidGreen,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 18),
            ],

            pw.Divider(color: _border, height: 1),
            pw.SizedBox(height: 18),

            // ── Signature block ──────────────────────────────────────────────
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 32),
                      pw.Container(height: 0.8, color: _border),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Received By',
                        style: pw.TextStyle(
                          font: regular,
                          fontSize: 9,
                          color: _textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 60),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 32),
                      pw.Container(height: 0.8, color: _border),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Authorized Signature',
                        style: pw.TextStyle(
                          font: regular,
                          fontSize: 9,
                          color: _textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 22),

            // ── Footer ───────────────────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 11,
                  color: _textDark,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                '— $businessName',
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: _textGrey,
                ),
              ),
            ),
          ];

          // ── Wrap with diagonal PAID watermark ────────────────────────────
          if (!isPaid) return content;
          return [
            pw.Stack(
              children: [
                pw.Column(children: content),
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Transform.rotate(
                      angle: -math.pi / 6,
                      child: pw.Opacity(
                        opacity: 0.06,
                        child: pw.Text(
                          'PAID',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 120,
                            color: PdfColors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc;
  }

  // ── Premium delivery table with one column per product ───────────────────────
  //
  // Columns: # | Date | [product1] | [product2] | … | Amount
  // - Header:    navy background, white bold text
  // - Data rows: alternating white / very-light-blue (zebra)
  // - Quantities: shown in blue; dashes in light grey for missing products
  // - Totals row: blue-tint background, bold totals per column + green amount
  //
  static pw.Widget _billTable({
    required pw.Font regular,
    required pw.Font bold,
    required List<String> productLabels,
    required List<Delivery> deliveries,
    required double amountTotal,
  }) {
    final prodCount = productLabels.length;
    // # | Date | product columns | Amount
    final colCount = 3 + prodCount;

    // ── Column widths (flex) ───────────────────────────────────────────────
    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.55), // #
      1: const pw.FlexColumnWidth(1.10), // Date
      for (var i = 0; i < prodCount; i++)
        i + 2: const pw.FlexColumnWidth(0.85), // each product
      colCount - 1: const pw.FlexColumnWidth(1.10), // Amount
    };

    // ── Cell builder ──────────────────────────────────────────────────────
    pw.Widget cell(
      String text, {
      bool isHeader = false,
      bool isTotal  = false,
      bool isDash   = false,
      bool isQty    = false,
      bool isAmount = false,
      pw.TextAlign align = pw.TextAlign.center,
      PdfColor? overrideColor,
    }) {
      PdfColor textColor;
      if (overrideColor != null) {
        textColor = overrideColor;
      } else if (isHeader) {
        textColor = PdfColors.white;
      } else if (isDash) {
        textColor = _dashColor;
      } else if (isQty) {
        textColor = _qtyBlue;
      } else if (isAmount) {
        textColor = _amountGreen;
      } else {
        textColor = _textDark;
      }

      final double vPad = isHeader ? 10 : 9;
      const double hPad = 7;

      return pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        alignment: switch (align) {
          pw.TextAlign.center => pw.Alignment.center,
          pw.TextAlign.right  => pw.Alignment.centerRight,
          _                   => pw.Alignment.centerLeft,
        },
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: (isHeader || isTotal) ? bold : regular,
            fontSize: isHeader ? 9.5 : 10,
            color: textColor,
          ),
          softWrap: true,
          overflow: pw.TextOverflow.clip,
        ),
      );
    }

    // ── Row builder ───────────────────────────────────────────────────────
    pw.TableRow tableRow(List<pw.Widget> cells, {PdfColor? bg}) {
      return pw.TableRow(
        decoration: bg != null ? pw.BoxDecoration(color: bg) : null,
        children: cells,
      );
    }

    // ── Compute per-column totals ─────────────────────────────────────────
    final colTotals = [
      for (final label in productLabels)
        deliveries.fold<int>(0, (s, d) => s + _qtyFor(d, label)),
    ];
    final grandTotal = amountTotal;

    // ── Build rows ────────────────────────────────────────────────────────
    final rows = <pw.TableRow>[];

    // Header
    rows.add(tableRow(
      [
        cell('#',       isHeader: true, align: pw.TextAlign.center),
        cell('Date',    isHeader: true, align: pw.TextAlign.left),
        ...productLabels.map(
          (l) => cell(l, isHeader: true, align: pw.TextAlign.center),
        ),
        cell('Amount',  isHeader: true, align: pw.TextAlign.right),
      ],
      bg: _tableNavy,
    ));

    // Data rows
    if (deliveries.isEmpty) {
      rows.add(tableRow([
        cell('—',                         align: pw.TextAlign.center),
        cell('No deliveries this month',  align: pw.TextAlign.left),
        ...List.filled(prodCount, cell('—', isDash: true)),
        cell(CurrencyUtils.format(0),     isAmount: true, align: pw.TextAlign.right),
      ]));
    } else {
      for (var i = 0; i < deliveries.length; i++) {
        final d      = deliveries[i];
        final isAlt  = i.isOdd;
        final cells  = <pw.Widget>[
          cell('${i + 1}',                     align: pw.TextAlign.center),
          cell(d.date.dayMonth,                align: pw.TextAlign.left),
          ...productLabels.map((label) {
            final qty = _qtyFor(d, label);
            return qty > 0
                ? cell('$qty', isQty: true, align: pw.TextAlign.center)
                : cell('—',   isDash: true, align: pw.TextAlign.center);
          }),
          cell(
            CurrencyUtils.format(d.totalAmount),
            isAmount: true,
            align: pw.TextAlign.right,
          ),
        ];
        rows.add(tableRow(cells, bg: isAlt ? _altRowBg : null));
      }

      // Totals row
      rows.add(tableRow(
        [
          cell('',       isTotal: true, align: pw.TextAlign.center),
          cell('Total',  isTotal: true, align: pw.TextAlign.left),
          ...List.generate(prodCount, (i) {
            final t = colTotals[i];
            return cell(
              t > 0 ? '$t' : '—',
              isTotal: true,
              align: pw.TextAlign.center,
              overrideColor: t > 0 ? _qtyBlue : _dashColor,
            );
          }),
          cell(
            CurrencyUtils.format(grandTotal),
            isTotal: true,
            align: pw.TextAlign.right,
            overrideColor: _amountGreen,
          ),
        ],
        bg: _totalBg,
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      columnWidths: colWidths,
      children: rows,
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────────

  static pw.Widget _customerLine(
    String label,
    String value,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: bold, fontSize: 10, color: _textGrey),
          ),
        ),
        pw.Text(
          ': ',
          style: pw.TextStyle(font: bold, fontSize: 10, color: _textGrey),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regular, fontSize: 10, color: _textDark),
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryLine(
    String label,
    String value,
    pw.Font regular,
    pw.Font bold, {
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: regular, fontSize: 10, color: _textGrey),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: bold,
            fontSize: 11,
            color: valueColor ?? _textDark,
          ),
        ),
      ],
    );
  }

  // ── Product label helpers ─────────────────────────────────────────────────────

  /// Collect all distinct product labels that appear across the given
  /// deliveries, sorted: Normal Can → Cool Can → Bottles (by size ascending).
  static List<String> _extractProductLabels(List<Delivery> deliveries) {
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

  /// 0 = Normal Can, 1 = Cool Can, 2 = Bottle (sorted by size).
  static int _labelPriority(String label) {
    final l = label.toLowerCase();
    if (l.contains('normal')) return 0;
    if (l.contains('cool'))   return 1;
    return 2;
  }

  /// Parse numeric bottle size from label for ascending sort (e.g. "½ L" → 0.5).
  static double _bottleSize(String label) {
    final clean = label.replaceAll(RegExp(r'[^0-9/.]'), '');
    if (clean.contains('/')) {
      final parts = clean.split('/');
      final n = double.tryParse(parts[0]) ?? 0;
      final d = double.tryParse(parts[1]) ?? 1;
      return d > 0 ? n / d : 0;
    }
    return double.tryParse(clean) ?? 999;
  }

  /// Sum the quantity of a specific product label within one delivery.
  static int _qtyFor(Delivery delivery, String label) {
    return delivery.lines
        .where((l) => l.label == label)
        .fold(0, (s, l) => s + l.quantity);
  }

  // ── File helpers ──────────────────────────────────────────────────────────────

  static String _fileName(String customerName, DateTime month) {
    final safe = customerName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(' ', '_');
    return 'Bill_${safe}_${DateFormat('MMM_yyyy').format(month)}.pdf';
  }

  static Future<File> _writeTemp(List<int> bytes, String fileName) async {
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
