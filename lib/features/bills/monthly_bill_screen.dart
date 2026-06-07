import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/bill_share_service.dart';
import 'package:sri_sai_ro_water/core/services/monthly_bill_pdf_service.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/utils/delivery_day_grouping.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_bill_widgets.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_summary_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

class MonthlyBillScreen extends StatefulWidget {
  const MonthlyBillScreen({
    super.key,
    required this.customerId,
    this.initialMonth,
  });

  final String customerId;
  final DateTime? initialMonth;

  @override
  State<MonthlyBillScreen> createState() => _MonthlyBillScreenState();
}

class _MonthlyBillScreenState extends State<MonthlyBillScreen> {
  late DateTime _month;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialMonth;
    _month = initial != null
        ? DateTime(initial.year, initial.month)
        : DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = context.read<WaterPlantRepository>();
      await repo.loadCustomersForCurrentAdminFromFirestore();
      await repo.loadLedgerForCurrentShopFromFirestore(month: _month);
    });
  }

  Future<void> _shiftMonth(int delta) async {
    final nextMonth = DateTime(_month.year, _month.month + delta);
    setState(() {
      _month = nextMonth;
    });
    await context
        .read<WaterPlantRepository>()
        .loadLedgerForCurrentShopFromFirestore(month: nextMonth);
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final next = DateTime(_month.year, _month.month + 1);
    return !next.isAfter(current);
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _withPdf(Future<void> Function(File file) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = context.read<WaterPlantRepository>();
      final customer = repo.customerById(widget.customerId);
      if (customer == null) {
        _snack('Customer not found', isError: true);
        return;
      }
      final settings = repo.settings;
      final deliveries = groupDeliveriesByDay(
        repo.deliveriesForCustomer(widget.customerId, month: _month),
      );
      final stats = repo.monthlyStatsForCustomer(widget.customerId, _month);

      final file = await MonthlyBillPdfService.buildAndSave(
        businessName: settings.businessName,
        businessAddress: settings.address,
        businessPhone: settings.phone,
        businessEmail: settings.email,
        month: _month,
        customer: customer,
        deliveries: deliveries,
        stats: stats,
      );
      await action(file);
    } catch (e) {
      _snack('Could not create PDF. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPdf() async {
    await _withPdf((file) async {
      final savedPath = await BillShareService.saveToDocuments(
        file,
        file.uri.pathSegments.last,
      );
      _snack('PDF saved (${CurrencyUtils.symbol} amounts)\n$savedPath');
    });
  }

  Future<void> _sharePdf({bool forWhatsApp = false}) async {
    await _withPdf((file) async {
      final repo = context.read<WaterPlantRepository>();
      final customer = repo.customerById(widget.customerId)!;
      await BillShareService.sharePdf(
        file: file,
        customer: customer,
        businessName: repo.settings.businessName,
        monthLabel: _month.monthYear,
      );
      if (forWhatsApp && mounted) {
        _snack('Choose WhatsApp from the share menu');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            backgroundColor: CustomersColors.screenBg,
            body: MonthlyBillScaffold(
              child: Column(
                children: [
                  MonthlyBillHeader(onBack: () => context.pop()),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Customer not found',
                        style: GoogleFonts.poppins(
                          color: CustomersColors.labelGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final settings = repo.settings;
        final deliveries = groupDeliveriesByDay(
          repo.deliveriesForCustomer(widget.customerId, month: _month),
        );
        final stats = repo.monthlyStatsForCustomer(widget.customerId, _month);
        final colorIndex = repo.customers.indexWhere(
          (c) => c.id == widget.customerId,
        );

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: Stack(
            children: [
              MonthlyBillScaffold(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MonthlyBillHeader(
                      onBack: () => context.pop(),
                      monthLabel: _month.monthYear,
                      onShare: _busy ? null : () => _sharePdf(),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                        children: [
                          MonthlyBillCustomerBar(
                            customer: customer,
                            colorIndex: colorIndex >= 0 ? colorIndex : 0,
                          ),
                          const SizedBox(height: 10),
                          MonthlySummaryMonthNav(
                            month: _month,
                            onPrev: () => _shiftMonth(-1),
                            onNext: () => _shiftMonth(1),
                            canGoNext: _canGoNext,
                            contentPadding: const EdgeInsets.only(top: 4),
                          ),
                          const SizedBox(height: 10),
                          MonthlyBillDocument(
                            businessName: settings.businessName,
                            businessAddress: settings.address,
                            businessPhone: settings.phone,
                            businessEmail: settings.email,
                            month: _month,
                            customer: customer,
                            deliveries: deliveries,
                            stats: stats,
                          ),
                        ],
                      ),
                    ),
                    MonthlyBillActionBar(
                      onDownload: _busy ? () {} : _downloadPdf,
                      onWhatsApp: _busy
                          ? () {}
                          : () => _sharePdf(forWhatsApp: true),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
