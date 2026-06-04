import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_list_card.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController();
  String _query = '';
  CustomerListFilter _filter = CustomerListFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Customer> _list(WaterPlantRepository repo) {
    final month = DateTime.now();
    final all = List<Customer>.from(repo.searchCustomers(_query))
      ..sort((a, b) => a.name.compareTo(b.name));

    if (_filter == CustomerListFilter.all) return all;

    return all.where((c) {
      final category = _categoryFor(repo, c, month);
      return switch (_filter) {
        CustomerListFilter.pending => category == CustomerPaymentCategory.pending,
        CustomerListFilter.paid => category == CustomerPaymentCategory.paid,
        CustomerListFilter.overdue => category == CustomerPaymentCategory.overdue,
        CustomerListFilter.all => true,
      };
    }).toList();
  }

  CustomerPaymentCategory _categoryFor(
    WaterPlantRepository repo,
    Customer c,
    DateTime month,
  ) {
    final monthly = repo.monthlyStatsForCustomer(c.id, month);
    final prior = repo.previousBalanceForMonth(c.id, month);
    final total = repo.customerBalance(c.id);
    return customerPaymentCategory(
      totalBalance: total,
      monthBalance: monthly.balance,
      priorBalance: prior,
      monthTotal: monthly.totalAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customers = _list(repo);
        final month = DateTime.now();
        void openAddCustomer() => context.push('/customers/add');

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            usePageGradient: true,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomersHeader(
                    showAddButton: false,
                    onAdd: openAddCustomer,
                    onMenu: () => context.go(AppRoutes.more),
                  ),
                  CustomersSearchRow(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  CustomersFilterChips(
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  Expanded(
                    child: customers.isEmpty
                        ? _EmptyCustomers(
                            isSearch: _query.isNotEmpty || _filter != CustomerListFilter.all,
                            onAdd: openAddCustomer,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                            itemCount: customers.length,
                            itemBuilder: (_, i) {
                              final c = customers[i];
                              final monthly = repo.monthlyStatsForCustomer(c.id, month);
                              final deliveries = repo.deliveriesForCustomer(c.id);
                              final last = deliveries.isEmpty ? null : deliveries.first.date;
                              final idx = repo.customers.indexWhere((x) => x.id == c.id);
                              return CustomerListCard(
                                customer: c,
                                colorIndex: idx >= 0 ? idx : i,
                                unitsThisMonth: monthly.totalUnits,
                                lastDeliveryLabel: lastDeliveryRelativeLabel(last),
                                balance: repo.customerBalance(c.id).clamp(0, double.infinity),
                                category: _categoryFor(repo, c, month),
                                onTap: () => context.push('/customers/${c.id}'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: CustomersAddButton(onPressed: openAddCustomer),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.isSearch, required this.onAdd});

  final bool isSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 56,
              color: CustomersColors.labelGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isSearch ? 'No customers match your filters' : 'No customers yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: CustomersColors.labelGrey,
              ),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 8),
              Text(
                'Tap Add customer below',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: CustomersColors.labelGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
