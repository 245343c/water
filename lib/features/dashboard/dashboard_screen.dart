import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/month_year_wheel_picker.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/dashboard/widgets/dashboard_home_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _month;
  static final _countFmt = NumberFormat('#,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearWheelPicker(
      context,
      initial: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _month = picked);
  }

  void _showCustomerPicker(BuildContext context, WaterPlantRepository repo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CustomersColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Customer',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: repo.customers.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: CustomersColors.divider),
                itemBuilder: (_, i) {
                  final c = repo.customers[i];
                  final bg = CustomersColors.avatarBgs[i % CustomersColors.avatarBgs.length];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: bg,
                      child: Text(
                        c.initials,
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(c.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      c.phone,
                      style: GoogleFonts.poppins(fontSize: 13, color: CustomersColors.labelGrey),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/customers/${c.id}/delivery');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final stats = repo.dashboardStats(_month);
        final recent = repo.recentDeliveries(limit: 3);
        final business = repo.settings.businessName;

        final overview = DashboardOverviewData(
          totalSales: CurrencyUtils.format(stats.totalSales),
          totalDeliveries: _countFmt.format(stats.totalDeliveries),
          totalCans: _countFmt.format(stats.totalCans),
          activeCustomers: _countFmt.format(stats.activeCustomers),
          paidThisMonth: CurrencyUtils.format(stats.paidThisMonth),
          pendingAmount: CurrencyUtils.format(stats.pendingAmount),
        );

        int colorIndexFor(String customerId) {
          final i = repo.customers.indexWhere((c) => c.id == customerId);
          return i >= 0 ? i : 0;
        }

        void openAddDelivery() => _showCustomerPicker(context, repo);

        return Scaffold(
          backgroundColor: DashboardColors.bgTop,
          body: DashboardScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardHeader(title: business),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        DashboardQuickActions(
                          onAddDelivery: openAddDelivery,
                          onAddCustomer: () => context.push('/customers/add'),
                        ),
                        const SizedBox(height: 14),
                        DashboardOverviewCard(
                          month: _month,
                          onMonthTap: _pickMonth,
                          data: overview,
                        ),
                        const SizedBox(height: 16),
                        DashboardRecentCard(
                          deliveries: recent,
                          customerNameOf: (id) => repo.customerById(id)?.name ?? 'Unknown',
                          colorIndexOf: colorIndexFor,
                          onViewAll: () => context.go(AppRoutes.deliveries),
                          onAddDelivery: openAddDelivery,
                          onItemTap: (d) {
                            final c = repo.customerById(d.customerId);
                            if (c != null) context.push('/customers/${c.id}');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
