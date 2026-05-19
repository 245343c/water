import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_list_card.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

class DriverCustomersScreen extends StatefulWidget {
  const DriverCustomersScreen({super.key});

  @override
  State<DriverCustomersScreen> createState() => _DriverCustomersScreenState();
}

class _DriverCustomersScreenState extends State<DriverCustomersScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final month = DateTime.now();
        final customers = List.of(repo.searchCustomers(_query))
          ..sort((a, b) => a.name.compareTo(b.name));

        return Scaffold(
          backgroundColor: DriverColors.screenBg,
          body: DriverScaffold(
            child: Column(
              children: [
                const DriverHeader(
                  title: 'Customers',
                  subtitle: 'View details & record delivery',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search name or phone…',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: DriverColors.labelGrey),
                      prefixIcon: const Icon(Icons.search_rounded, color: DriverColors.accent),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: DriverColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: DriverColors.cardBorder),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: customers.isEmpty
                      ? Center(
                          child: Text(
                            'No customers found',
                            style: GoogleFonts.poppins(color: DriverColors.labelGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          itemCount: customers.length,
                          itemBuilder: (_, i) {
                            final c = customers[i];
                            final monthly = repo.monthlyStatsForCustomer(c.id, month);
                            final deliveries = repo.deliveriesForCustomer(c.id);
                            final last = deliveries.isEmpty ? null : deliveries.first.date;
                            final idx = repo.customers.indexWhere((x) => x.id == c.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CustomerListCard(
                                customer: c,
                                colorIndex: idx >= 0 ? idx : i,
                                unitsThisMonth: monthly.totalUnits,
                                lastDeliveryLabel: lastDeliveryRelativeLabel(last),
                                balance: 0,
                                category: CustomerPaymentCategory.paid,
                                onTap: () => context.push('/driver/customers/${c.id}'),
                              ),
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
