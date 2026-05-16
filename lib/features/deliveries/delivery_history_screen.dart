import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/delivery_history_widgets.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Filter options will be available when backend is connected.',
              style: GoogleFonts.poppins(color: DeliveryHistoryColors.labelGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Delivery History')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final deliveries = List.of(repo.deliveriesForCustomer(widget.customerId, month: _month))
          ..sort((a, b) => b.date.compareTo(a.date));

        final normalTotal = deliveries.fold<int>(0, (s, d) => s + d.normalQty);
        final coolTotal = deliveries.fold<int>(0, (s, d) => s + d.coolQty);
        final amountTotal = deliveries.fold<double>(0, (s, d) => s + d.totalAmount);
        final colorIndex = repo.customers.indexWhere((c) => c.id == widget.customerId);

        return Scaffold(
          backgroundColor: DeliveryHistoryColors.screenBg,
          body: DeliveryHistoryScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeliveryHistoryHeader(
                  onBack: () => context.pop(),
                  onFilter: _showFilterSheet,
                ),
                DeliveryHistoryCustomerBar(
                  customer: customer,
                  colorIndex: colorIndex >= 0 ? colorIndex : 0,
                ),
                DeliveryHistoryMonthNav(
                  month: _month,
                  onPrev: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                ),
                Expanded(
                  child: DeliveryHistoryListCard(deliveries: deliveries),
                ),
                DeliveryHistoryMonthTotalCard(
                  normalCans: normalTotal,
                  coolCans: coolTotal,
                  totalAmount: amountTotal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
