import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_info_bar.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/driver_delivery_success_sheet.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_field_delivery_card.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';
import 'package:sri_sai_ro_water/core/services/shop_map_launcher.dart';

class DriverCustomerDetailScreen extends StatelessWidget {
  const DriverCustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $phone', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WaterPlantRepository, AuthRepository>(
      builder: (context, repo, auth, _) {
        final driverId = auth.currentUser?.driverId;
        final assignedShop = repo.shopForDriver(driverId);
        final customer = repo.customerById(customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer')),
            body: const Center(child: Text('Not found')),
          );
        }

        if (!repo.canDriverAccessCustomer(driverId, customerId)) {
          return Scaffold(
            backgroundColor: DriverColors.screenBg,
            body: DriverScaffold(
              child: Column(
                children: [
                  DriverHeader(
                    title: 'Customer not assigned',
                    subtitle: assignedShop == null
                        ? 'Driver is not linked to a water plant'
                        : '${assignedShop.name} customers only',
                    onBack: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'This customer belongs to another water plant.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: DriverColors.labelGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final scopedCustomers = repo.customersForDriver(driverId);
        final idx = scopedCustomers.indexWhere((c) => c.id == customerId);
        final recent = repo.deliveriesForCustomer(customerId).take(5).toList();
        final deliveredToday = repo.hasDeliveryToday(customerId);
        final routeNote = repo.routeNoteForCustomer(customerId);

        return Scaffold(
          backgroundColor: DriverColors.screenBg,
          body: DriverScaffold(
            child: Column(
              children: [
                DriverHeader(
                  title: customer.name,
                  subtitle: deliveredToday
                      ? 'Delivered today'
                      : '${assignedShop?.name ?? 'Assigned plant'} customer',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      CustomerInfoBar(
                        customer: customer,
                        colorIndex: idx >= 0 ? idx : 0,
                      ),
                      if (routeNote != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: DriverColors.cardDecoration,
                            child: Row(
                              children: [
                                const Icon(Icons.route_rounded, color: DriverColors.accent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    routeNote,
                                    style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.labelGrey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      DriverFieldDeliveryCard(
                        customer: customer,
                        suggestedOrder: repo.acceptedOrderForCustomer(
                          customerId,
                          driverId: driverId,
                        ),
                        onSaved: (delivery) {
                          showDriverDeliverySuccessSheet(
                            context,
                            customerName: customer.name,
                            delivery: delivery,
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => ShopMapLauncher.directions(address: customer.address),
                                icon: const Icon(Icons.directions_rounded, size: 18),
                                label: Text('Directions', style: GoogleFonts.poppins(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: DriverColors.accent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: DriverColors.cardBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _copyPhone(context, customer.phone),
                                icon: const Icon(Icons.phone_outlined, size: 18),
                                label: Text('Call', style: GoogleFonts.poppins(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: DriverColors.accent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: DriverColors.cardBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recent.isNotEmpty) ...[
                        const DriverSectionTitle(title: 'Recent deliveries'),
                        ...recent.map(
                          (d) => _RecentTile(delivery: d),
                        ),
                      ],
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

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: DriverColors.cardDecoration,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.cansSummary,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    delivery.date.fullDate,
                    style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.labelGrey),
                  ),
                ],
              ),
            ),
            Text(
              '${delivery.normalQty + delivery.coolQty} cans',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DriverColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
