import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/constants/delivery_route_constants.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/routes/widgets/delivery_routes_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class DeliveryRoutesScreen extends StatefulWidget {
  const DeliveryRoutesScreen({super.key});

  @override
  State<DeliveryRoutesScreen> createState() => _DeliveryRoutesScreenState();
}

class _DeliveryRoutesScreenState extends State<DeliveryRoutesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<WaterPlantRepository>().loadDeliveryRoutesForCurrentAdmin();
    });
  }

  Future<void> _createRoute(WaterPlantRepository repo) async {
    final name = await showDeliveryRouteNameDialog(context);
    if (name == null || name.isEmpty || !mounted) return;
    try {
      await repo.addDeliveryRoute(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route "$name" created', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ArgumentError: ', ''),
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final routes = repo.activeDeliveryRoutes;
        final unassigned = repo.customerCountForRoute(null);

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            usePageGradient: true,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DeliveryRoutesHeader(onBack: () => context.pop()),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                          child: Text(
                            'Drivers pick a route to see only those customers. '
                            'Quick orders are not on routes.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (unassigned > 0)
                          DeliveryRoutesUnassignedCard(
                            count: unassigned,
                            onTap: () => context.push(
                              '${AppRoutes.deliveryRoutes}/${DeliveryRouteFilters.unassigned}',
                            ),
                          ),
                        if (routes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No routes yet.\nTap Add route to create your first area.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: DeliveryRoutesColors.labelGrey,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          )
                        else
                          ...routes.map(
                            (route) => DeliveryRouteListCard(
                              route: route,
                              customerCount:
                                  repo.customerCountForRoute(route.id),
                              onTap: () => context.push(
                                '${AppRoutes.deliveryRoutes}/${route.id}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton:
              DeliveryRoutesAddFab(onPressed: () => _createRoute(repo)),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
