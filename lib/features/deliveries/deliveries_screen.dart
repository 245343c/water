import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/deliveries_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Delivery> _filtered(WaterPlantRepository repo) {
    final all = repo.deliveriesNewestFirst();
    if (_query.trim().isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((d) {
      final customer = repo.customerById(d.customerId);
      return (customer?.name.toLowerCase().contains(q) ?? false) ||
          (customer?.phone
                  .replaceAll(' ', '')
                  .contains(q.replaceAll(' ', '')) ??
              false) ||
          d.cansSummary.toLowerCase().contains(q);
    }).toList();
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
            Text(
              'Filter',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Filter options will be available when backend is connected.',
              style: GoogleFonts.poppins(color: CustomersColors.labelGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: repo.customers.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: CustomersColors.divider),
                itemBuilder: (_, i) {
                  final c = repo.customers[i];
                  final bg = CustomersColors
                      .avatarBgs[i % CustomersColors.avatarBgs.length];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: bg,
                      child: Text(
                        c.initials,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      c.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: CustomersColors.labelGrey,
                      ),
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
        final deliveries = _filtered(repo);
        final grouped = groupDeliveriesByDay(deliveries, DateTime.now());

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomersHeader(
                  title: 'Deliveries',
                  onAdd: () => _showCustomerPicker(context, repo),
                  onMenu: () => context.go(AppRoutes.more),
                ),
                CustomersSearchRow(
                  controller: _search,
                  hintText: 'Search deliveries...',
                  onChanged: (v) => setState(() => _query = v),
                  onFilter: _showFilterSheet,
                ),
                CustomersListPanel(
                  child: RefreshIndicator(
                    onRefresh: () => repo.refreshFromBackend(),
                    child: deliveries.isEmpty
                        ? _EmptyDeliveries(
                            isSearch: _query.isNotEmpty,
                            onAdd: () => _showCustomerPicker(context, repo),
                          )
                        : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          children: [
                            for (final entry in grouped) ...[
                              DeliveriesDayHeader(label: entry.label),
                              for (final d in entry.items)
                                Builder(
                                  builder: (context) {
                                    final customer = repo.customerById(
                                      d.customerId,
                                    );
                                    final customerIndex = customer == null
                                        ? 0
                                        : repo.customers.indexWhere(
                                            (c) => c.id == customer.id,
                                          );
                                    return DeliveryListCard(
                                      customerName: customer?.name ?? 'Unknown',
                                      initials: customer?.initials ?? '?',
                                      colorIndex: customerIndex >= 0
                                          ? customerIndex
                                          : 0,
                                      delivery: d,
                                      onTap: customer != null
                                          ? () => context.push(
                                              '/customers/${customer.id}',
                                            )
                                          : () {},
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
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

class _EmptyDeliveries extends StatelessWidget {
  const _EmptyDeliveries({required this.isSearch, required this.onAdd});

  final bool isSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 56,
            color: CustomersColors.labelGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'No results found' : 'No deliveries yet',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: CustomersColors.labelGrey,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Delivery'),
              style: FilledButton.styleFrom(
                backgroundColor: CustomersColors.addButton,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
