import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/constants/delivery_route_constants.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/routes/widgets/delivery_routes_widgets.dart';

class DeliveryRouteDetailScreen extends StatefulWidget {
  const DeliveryRouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  bool get isUnassigned => routeId == DeliveryRouteFilters.unassigned;

  @override
  State<DeliveryRouteDetailScreen> createState() =>
      _DeliveryRouteDetailScreenState();
}

class _DeliveryRouteDetailScreenState extends State<DeliveryRouteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<WaterPlantRepository>().loadDeliveryRoutesForCurrentAdmin();
    });
  }

  List<Customer> _customers(WaterPlantRepository repo) {
    if (widget.isUnassigned) {
      return repo.customersOnRoute(null);
    }
    return repo.customersOnRoute(widget.routeId);
  }

  String _title(WaterPlantRepository repo) {
    if (widget.isUnassigned) return 'No route yet';
    return repo.deliveryRouteName(widget.routeId);
  }

  Future<void> _renameRoute(WaterPlantRepository repo) async {
    final route = repo.deliveryRouteById(widget.routeId);
    if (route == null) return;
    final name = await showDeliveryRouteNameDialog(
      context,
      title: 'Rename route',
      initialName: route.name,
      confirmLabel: 'Save',
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      await repo.renameDeliveryRoute(widget.routeId, name);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('ArgumentError: ', ''));
    }
  }

  Future<void> _archiveRoute(WaterPlantRepository repo) async {
    final confirmed = await showRemoveDeliveryRouteDialog(
      context,
      routeName: repo.deliveryRouteName(widget.routeId),
    );
    if (confirmed != true || !mounted) return;
    try {
      await repo.archiveDeliveryRoute(widget.routeId);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('ArgumentError: ', ''));
    }
  }

  Future<void> _assignCustomers(WaterPlantRepository repo) async {
    if (widget.isUnassigned) return;
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AssignCustomersSheet(
        routeName: repo.deliveryRouteName(widget.routeId),
        candidates: repo.customersOnRoute(null),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    await repo.assignCustomersToRoute(picked, widget.routeId);
    if (!mounted) return;
    _snack('${picked.length} customer${picked.length == 1 ? '' : 's'} added to route');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins()), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customers = _customers(repo);
        final title = _title(repo);

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            usePageGradient: true,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DeliveryRoutesHeader(
                    onBack: () => context.pop(),
                    title: title,
                    subtitle: widget.isUnassigned
                        ? 'Assign these customers to a route'
                        : '${customers.length} customers on this route',
                  ),
                  if (!widget.isUnassigned)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _renameRoute(repo),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text('Rename', style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _archiveRoute(repo),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: Text('Remove', style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: customers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                widget.isUnassigned
                                    ? 'All customers are on a route — great!'
                                    : 'No customers on this route yet.\nTap Add customers below.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: DeliveryRoutesColors.labelGrey,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                            itemCount: customers.length,
                            itemBuilder: (_, i) {
                              final c = customers[i];
                              return _RouteCustomerTile(
                                customer: c,
                                onTap: () => context.push('/customers/${c.id}'),
                                onMoveOff: widget.isUnassigned
                                    ? null
                                    : () => repo.setCustomerRoute(c.id, null),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: widget.isUnassigned
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  child: DeliveryRoutesAddFab(
                    label: 'Add customers',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: () => _assignCustomers(repo),
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

class _RouteCustomerTile extends StatelessWidget {
  const _RouteCustomerTile({
    required this.customer,
    required this.onTap,
    this.onMoveOff,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback? onMoveOff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CustomersColors.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        customer.place.isNotEmpty ? customer.place : customer.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: DeliveryRoutesColors.labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onMoveOff != null)
                  IconButton(
                    tooltip: 'Remove from route',
                    onPressed: onMoveOff,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: DeliveryRoutesColors.labelGrey,
                  ),
                const Icon(Icons.chevron_right_rounded, color: DeliveryRoutesColors.labelGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignCustomersSheet extends StatefulWidget {
  const _AssignCustomersSheet({
    required this.routeName,
    required this.candidates,
  });

  final String routeName;
  final List<Customer> candidates;

  @override
  State<_AssignCustomersSheet> createState() => _AssignCustomersSheetState();
}

class _AssignCustomersSheetState extends State<_AssignCustomersSheet> {
  final _selected = <String>{};
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Customer> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.candidates;
    return widget.candidates
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.contains(q) ||
              c.place.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final list = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CustomersColors.cardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add to ${widget.routeName}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Customers with no route yet',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: DeliveryRoutesColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search name, phone, area…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'No unassigned customers',
                        style: GoogleFonts.poppins(color: DeliveryRoutesColors.labelGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final sel = _selected.contains(c.id);
                        return CheckboxListTile(
                          value: sel,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selected.add(c.id);
                            } else {
                              _selected.remove(c.id);
                            }
                          }),
                          title: Text(c.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.place, style: GoogleFonts.poppins(fontSize: 12)),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected.toList()),
                style: FilledButton.styleFrom(
                  backgroundColor: DeliveryRoutesColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _selected.isEmpty
                      ? 'Select customers'
                      : 'Add ${_selected.length} to route',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
