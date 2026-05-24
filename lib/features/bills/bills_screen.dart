import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/bill_list_tile.dart';
import 'package:sri_sai_ro_water/core/widgets/content_width.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late DateTime _month;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshBills());
  }

  Future<void> _refreshBills() async {
    setState(() => _loading = true);
    final repo = context.read<WaterPlantRepository>();
    await repo.refreshMonthlyBills(_month);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final monthLabel = _month.monthYear;

        final customers = List<Customer>.from(repo.customers)
          ..sort((a, b) {
            final ba = repo.monthlyStatsForCustomer(a.id, _month).balance;
            final bb = repo.monthlyStatsForCustomer(b.id, _month).balance;
            return bb.compareTo(ba);
          });

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: const Text('Bills'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh bills',
                onPressed: _loading ? null : _refreshBills,
              ),
            ],
          ),
          body: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    'Monthly bills · $monthLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final c = customers[index];
                        final stats = repo.monthlyStatsForCustomer(c.id, _month);
                        return BillListTile(
                          customer: c,
                          stats: stats,
                          colorIndex: index,
                          onTap: () => context.push('/customers/${c.id}/summary'),
                        );
                      },
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
