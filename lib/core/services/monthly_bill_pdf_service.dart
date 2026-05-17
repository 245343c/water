import 'dart:io';

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

/// Builds monthly bill PDFs on-device (matches on-screen bill layout).
abstract final class MonthlyBillPdfService {
  static const _billBlue = PdfColor.fromInt(0xFF1E40AF);
  static const _headerBg = PdfColor.fromInt(0xFFF3F4F6);
  static const _totalBg = PdfColor.fromInt(0xFFEFF6FF);
  static const _border = PdfColor.fromInt(0xFFD1D5DB);
  static const _balanceRed = PdfColor.fromInt(0xFFDC2626);

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
    final bold = await PdfGoogleFonts.poppinsBold();
    final normalTotal = deliveries.fold<int>(0, (s, d) => s + d.normalQty);
    final coolTotal = deliveries.fold<int>(0, (s, d) => s + d.coolQty);

    final dataRows = <List<String>>[
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

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 44),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              businessName.toUpperCase(),
              style: pw.TextStyle(font: bold, fontSize: 15, color: _billBlue, letterSpacing: 0.6),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              businessAddress,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey700, lineSpacing: 1.35),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Ph: $businessPhone',
              style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          if (businessEmail.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                businessEmail,
                style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey700),
              ),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Center(
            child: pw.Text(
              'MONTHLY BILL - ${month.monthYear}',
              style: pw.TextStyle(font: bold, fontSize: 12, color: _billBlue),
            ),
          ),
          pw.SizedBox(height: 20),
          _customerLine('Customer Name', customer.name, regular, bold),
          pw.SizedBox(height: 8),
          _customerLine('Mobile Number', customer.phone, regular, bold),
          if (customer.email.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _customerLine('Email', customer.email, regular, bold),
          ],
          if (customer.place.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _customerLine('Place', customer.place, regular, bold),
          ],
          pw.SizedBox(height: 8),
          _customerLine('Address', customer.address, regular, bold),
          pw.SizedBox(height: 18),
          _billTable(
            regular: regular,
            bold: bold,
            dataRows: dataRows,
            stats: stats,
            normalTotal: normalTotal,
            coolTotal: coolTotal,
            amountTotal: stats.totalAmount,
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _summaryLine('Total Amount', CurrencyUtils.format(stats.totalAmount), regular, bold),
                pw.SizedBox(height: 8),
                _summaryLine('Paid Amount', CurrencyUtils.format(stats.paidAmount), regular, bold),
                pw.SizedBox(height: 8),
                _summaryLine(
                  'Balance Amount',
                  CurrencyUtils.format(stats.balance),
                  regular,
                  bold,
                  valueColor: _balanceRed,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Thank you!',
              style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.grey900),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              '- $businessName',
              style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _customerLine(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Text(': ', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.grey700)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static String _bottleTotalNote(MonthlyStats stats) {
    if (stats.bottleUnits <= 0) return '';
    final parts = stats.bottlesByLabel.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.value}×${e.key}')
        .join(', ');
    return parts.isEmpty ? '' : 'Bottles: $parts';
  }

  static pw.Widget _billTable({
    required pw.Font regular,
    required pw.Font bold,
    required List<List<String>> dataRows,
    required MonthlyStats stats,
    required int normalTotal,
    required int coolTotal,
    required double amountTotal,
  }) {
    const headers = ['Date', 'Description', 'Normal', 'Cool', 'Amount'];
    final bottleNote = _bottleTotalNote(stats);

    pw.Widget cell(
      String text, {
      bool header = false,
      bool total = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        alignment: switch (align) {
          pw.TextAlign.center => pw.Alignment.center,
          pw.TextAlign.right => pw.Alignment.centerRight,
          _ => pw.Alignment.centerLeft,
        },
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: header || total ? bold : regular,
            fontSize: header ? 9 : 10,
            color: PdfColors.grey900,
          ),
        ),
      );
    }

    pw.TableRow row(List<pw.Widget> children, {PdfColor? bg}) {
      return pw.TableRow(
        decoration: bg != null ? pw.BoxDecoration(color: bg) : null,
        children: children,
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(0.85),
        3: const pw.FlexColumnWidth(0.85),
        4: const pw.FlexColumnWidth(1.2),
      },
      children: [
        row(
          headers.map((h) => cell(h, header: true)).toList(),
          bg: _headerBg,
        ),
        ...dataRows.map(
          (cells) => row([
            cell(cells[0]),
            cell(cells[1]),
            cell(cells[2], align: pw.TextAlign.center),
            cell(cells[3], align: pw.TextAlign.center),
            cell(cells[4], align: pw.TextAlign.right),
          ]),
        ),
        row(
          [
            cell('Total', total: true),
            cell(bottleNote, total: true),
            cell('$normalTotal', total: true, align: pw.TextAlign.center),
            cell('$coolTotal', total: true, align: pw.TextAlign.center),
            cell(CurrencyUtils.format(amountTotal), total: true, align: pw.TextAlign.right),
          ],
          bg: _totalBg,
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
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.grey900),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              font: bold,
              fontSize: 11,
              color: valueColor ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  static String _fileName(String customerName, DateTime month) {
    final safe = customerName.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    return 'Bill_${safe}_${DateFormat('MMM_yyyy').format(month)}.pdf';
  }

  static Future<File> _writeTemp(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
