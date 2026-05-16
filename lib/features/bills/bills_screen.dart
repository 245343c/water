import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/bill_list_tile.dart';
import 'package:sri_sai_ro_water/core/widgets/content_width.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final month = DateTime(DateTime.now().year, DateTime.now().month);
        final monthLabel = month.monthYear;

        final customers = List<Customer>.from(repo.customers)
          ..sort((a, b) {
            final ba = repo.monthlyStatsForCustomer(a.id, month).balance;
            final bb = repo.monthlyStatsForCustomer(b.id, month).balance;
            return bb.compareTo(ba);
          });

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(title: const Text('Bills')),
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      final stats = repo.monthlyStatsForCustomer(c.id, month);
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
