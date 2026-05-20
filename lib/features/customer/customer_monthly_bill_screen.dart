import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart'; // isSameMonth
import 'package:sri_sai_ro_water/core/utils/delivery_day_grouping.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_bill_widgets.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

/// Read-only monthly bill — same layout as admin PDF preview.
class CustomerMonthlyBillScreen extends StatefulWidget {
  const CustomerMonthlyBillScreen({
    super.key,
    required this.customerId,
    required this.shopId,
    this.initialMonth,
  });

  final String customerId;
  final String shopId;
  final DateTime? initialMonth;

  @override
  State<CustomerMonthlyBillScreen> createState() =>
      _CustomerMonthlyBillScreenState();
}

class _CustomerMonthlyBillScreenState extends State<CustomerMonthlyBillScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialMonth;
    _month = initial != null
        ? DateTime(initial.year, initial.month)
        : DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        final shop = repo.shopById(widget.shopId);
        if (customer == null || shop == null) {
          return Scaffold(
            backgroundColor: CustomerColors.screenBg,
            appBar: AppBar(title: const Text('Monthly bill')),
            body: const Center(child: Text('Bill not found')),
          );
        }

        final stats =
            repo.monthlyStatsForCustomer(widget.customerId, _month);
        final deliveries = groupDeliveriesByDay(
          repo.deliveriesForCustomer(widget.customerId, month: _month),
        );
        final businessName = widget.shopId == WaterPlantRepository.defaultShopId
            ? repo.settings.businessName
            : shop.name;
        final businessAddress = widget.shopId == WaterPlantRepository.defaultShopId
            ? repo.settings.address
            : shop.address;
        final businessPhone = widget.shopId == WaterPlantRepository.defaultShopId
            ? repo.settings.phone
            : shop.phone;
        final businessEmail = widget.shopId == WaterPlantRepository.defaultShopId
            ? repo.settings.email
            : shop.email;

        return MonthlyBillScaffold(
          child: Scaffold(
            backgroundColor: MonthlyBillColors.screenBg,
            body: Column(
              children: [
                Container(
                  decoration: CustomerColors.headerGradient,
                  padding: EdgeInsets.fromLTRB(
                    4,
                    MediaQuery.paddingOf(context).top + 4,
                    4,
                    14,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Monthly bill',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  shop.name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: Colors.white),
                          ),
                          Text(
                            _month.monthYear,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: _month.isSameMonth(DateTime.now())
                                ? null
                                : () => _changeMonth(1),
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: _month.isSameMonth(DateTime.now())
                                  ? Colors.white38
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      MonthlyBillDocument(
                        businessName: businessName,
                        businessAddress: businessAddress,
                        businessPhone: businessPhone,
                        businessEmail: businessEmail,
                        month: _month,
                        customer: customer,
                        deliveries: deliveries,
                        stats: stats,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'This bill matches what your shop generates in the admin app. Contact the shop for corrections.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: CustomerColors.labelGrey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
