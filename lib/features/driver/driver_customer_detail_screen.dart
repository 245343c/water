import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/services/shop_map_launcher.dart';

import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';

import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_billing_mode.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

import 'package:sri_sai_ro_water/features/driver/driver_empty_can_sheet.dart';

import 'package:sri_sai_ro_water/features/driver/widgets/driver_can_balance_card.dart';

import 'package:sri_sai_ro_water/features/driver/widgets/driver_customer_detail_widgets.dart';

import 'package:sri_sai_ro_water/features/driver/widgets/driver_dispatch_fulfill_card.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_field_delivery_card.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_result_feedback.dart';

import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';



class DriverCustomerDetailScreen extends StatelessWidget {
  const DriverCustomerDetailScreen({
    super.key,
    required this.customerId,
    this.dispatchOrderId,
  });

  final String customerId;
  final String? dispatchOrderId;



  void _copyPhone(BuildContext context, String phone) {

    Clipboard.setData(ClipboardData(text: phone));

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(
          context.l10n.copiedPhone(phone),
          style: GoogleFonts.poppins(),
        ),

        behavior: SnackBarBehavior.floating,

      ),

    );

  }



  @override

  Widget build(BuildContext context) {
    final strings = context.l10n;

    return Consumer2<WaterPlantRepository, AuthRepository>(

      builder: (context, repo, auth, _) {

        final driverId = auth.currentUser?.driverId;

        final assignedShop = repo.shopForDriver(driverId);

        final customer = _resolveCustomer(
          repo,
          customerId,
          dispatchOrderId,
          strings,
        );

        if (!repo.canDriverAccessCustomer(driverId, customerId)) {

          return Scaffold(

            backgroundColor: DriverColors.contentBg,

            body: Column(

              children: [

                DriverCustomerDetailBar(

                  customer: customer,

                  deliveredToday: false,

                  onBack: () => context.pop(),

                ),

                Expanded(

                  child: Center(

                    child: Padding(

                      padding: const EdgeInsets.all(24),

                      child: Text(

                        assignedShop == null

                            ? strings.driverNotLinked

                            : strings.customerAnotherPlant,

                        textAlign: TextAlign.center,

                        style: GoogleFonts.poppins(color: DriverColors.labelGrey),

                      ),

                    ),

                  ),

                ),

              ],

            ),

          );

        }



        final deliveries = repo.deliveriesForCustomer(customerId);

        final lastDelivery = deliveries.isEmpty ? null : deliveries.first;

        final deliveredToday = repo.hasDeliveryToday(customerId);

        final routeNote = repo.routeNoteForCustomer(customerId);

        final canBalance = repo.customerCanBalance(customerId);

        final showNormalCans = repo.customerUsesNormalCans(customer);

        final showCoolCans = repo.customerUsesCoolCans(customer);



        return Scaffold(

          backgroundColor: DriverColors.contentBg,

          body: Column(

            children: [

              DriverCustomerDetailBar(
                customer: customer,
                deliveredToday: deliveredToday,
                onBack: () => context.pop(),
              ),

              Expanded(

                child: ListView(

                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),

                  children: [
                    DriverContentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DriverAddressBlock(customer: customer),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: DriverColors.cardBorder),
                          const SizedBox(height: 12),
                          DriverLastVisitLine(
                            lastDelivery: lastDelivery,
                            deliveredToday: deliveredToday,
                          ),
                          if (routeNote != null) ...[
                            const SizedBox(height: 12),
                            DriverRouteNoteLine(note: routeNote),
                          ],
                          const SizedBox(height: 14),
                          DriverContactRow(
                            onDirections: () => ShopMapLauncher.directions(
                              address: customer.address,
                            ),
                            onCall: () => _copyPhone(context, customer.phone),
                          ),
                        ],
                      ),
                    ),

                    if ((showNormalCans || showCoolCans) &&
                        !customer.isInstantDispatch) ...[

                      DriverSectionLabel(text: strings.emptyCans),

                      DriverCanBalanceCard(

                        balance: canBalance,

                        showNormal: showNormalCans,

                        showCool: showCoolCans,

                        onRecordReturn: () async {

                          final saved = await showDriverRecordEmptyCanSheet(

                            context,

                            customerId: customerId,

                          );

                          if (!context.mounted || saved != true) return;

                          ScaffoldMessenger.of(context).showSnackBar(

                            SnackBar(

                              content: Text(

                                strings.emptyReturnSaved,

                                style: GoogleFonts.poppins(fontSize: 13),

                              ),

                              behavior: SnackBarBehavior.floating,

                              backgroundColor: DriverColors.accent,

                            ),

                          );

                        },

                      ),

                    ],

                    DriverSectionLabel(text: strings.recordDelivery),
                    Builder(
                      builder: (context) {
                        final activeDispatch = repo.acceptedOrderForCustomer(
                          customerId,
                          driverId: driverId,
                          orderId: dispatchOrderId,
                        );
                        void onSaved(Delivery delivery) {
                          showDriverResultFeedback(
                            context,
                            success: true,
                            title: delivery.isEmptyReturnOnly
                                ? strings.emptyReturnSaved
                                : strings.deliverySaved,
                            message: delivery.isEmptyReturnOnly
                                ? null
                                : strings.adminUpdated,
                          );
                        }
                        if (activeDispatch != null && activeDispatch.isOpenForDriver) {
                          return DriverDispatchFulfillCard(
                            customer: customer,
                            dispatch: activeDispatch,
                            onSaved: onSaved,
                          );
                        }
                        return DriverFieldDeliveryCard(
                          customer: customer,
                          suggestedOrder: activeDispatch,
                          onSaved: onSaved,
                        );
                      },
                    ),

                  ],

                ),

              ),

            ],

          ),

        );

      },

    );

  }

  Customer _resolveCustomer(
    WaterPlantRepository repo,
    String customerId,
    String? dispatchOrderId,
    AppStrings strings,
  ) {
    final stored = repo.customerById(customerId);
    if (dispatchOrderId == null) {
      return stored ??
          Customer(
            id: customerId,
            name: strings.customers,
            phone: '',
            address: '',
          );
    }
    final dispatch = repo.orderById(dispatchOrderId);
    final walkIn = dispatch?.walkInContact;
    if (walkIn != null) {
      return Customer(
        id: customerId,
        name: walkIn.name,
        phone: walkIn.phone,
        address: walkIn.address,
        place: walkIn.place,
        billingMode: CustomerBillingMode.instantDispatch,
        productPrices: stored?.productPrices ?? repo.walkInDispatchPricing(),
      );
    }
    return stored ??
        Customer(
          id: customerId,
          name: strings.customers,
          phone: '',
          address: '',
        );
  }
}

