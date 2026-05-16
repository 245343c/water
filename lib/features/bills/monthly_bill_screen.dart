import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/bill_share_service.dart';
import 'package:sri_sai_ro_water/core/services/monthly_bill_pdf_service.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_bill_widgets.dart';

class MonthlyBillScreen extends StatefulWidget {
  const MonthlyBillScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<MonthlyBillScreen> createState() => _MonthlyBillScreenState();
}

class _MonthlyBillScreenState extends State<MonthlyBillScreen> {
  late DateTime _month;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : null,
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
      final deliveries = List.of(repo.deliveriesForCustomer(widget.customerId, month: _month))
        ..sort((a, b) => a.date.compareTo(b.date));
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
      _snack('PDF saved (${CurrencySymbol.rupee} amounts)\n$savedPath');
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
            appBar: AppBar(title: const Text('Monthly Bill (PDF)')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final settings = repo.settings;
        final deliveries = List.of(repo.deliveriesForCustomer(widget.customerId, month: _month))
          ..sort((a, b) => a.date.compareTo(b.date));
        final stats = repo.monthlyStatsForCustomer(widget.customerId, _month);

        return Scaffold(
          backgroundColor: MonthlyBillColors.screenBg,
          body: Stack(
            children: [
              MonthlyBillScaffold(
                child: Column(
                  children: [
                    MonthlyBillHeader(
                      onBack: () => context.pop(),
                      onShare: _busy ? null : () => _sharePdf(),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
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
                      onWhatsApp: _busy ? () {} : () => _sharePdf(forWhatsApp: true),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          ),
        );
      },
    );
  }
}
