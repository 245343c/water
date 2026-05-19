import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_info_bar.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_shop_info_card.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_detail_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Bulk / monthly contract — same data as admin customer detail (read-only).
class CustomerContractAccountScreen extends StatelessWidget {
  const CustomerContractAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final userId = auth.currentUser?.id;
    final crm = userId != null ? repo.linkedCrmCustomerForAppUser(userId) : null;

    if (crm == null) {
      return Scaffold(
        backgroundColor: CustomerColors.screenBg,
        body: CustomerScaffold(
          child: Column(
            children: [
              const CustomerHeader(
                title: 'My account',
                subtitle: 'Monthly water customer',
              ),
              const Expanded(
                child: CustomerEmptyState(
                  icon: Icons.link_off_rounded,
                  title: 'Account not linked',
                  message:
                      'Ask your shop to add you with this mobile number, then sign in again.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _AccountBody(crm: crm);
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody({required this.crm});

  final Customer crm;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WaterPlantRepository>();
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final monthly = repo.monthlyStatsForCustomer(crm.id, currentMonth);
    final totalPending = repo.customerBalance(crm.id);
    final advanceCredit = repo.customerAdvanceCredit(crm.id);
    final previousPending = repo.previousBalanceForMonth(crm.id, currentMonth);
    final idx = repo.customers.indexWhere((c) => c.id == crm.id);
    final firstName = crm.name.split(' ').first;
    final pendingDisplay = totalPending > 0 ? totalPending : 0.0;

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomerHeader(
              title: 'Hello, $firstName',
              subtitle: 'Your monthly account with ${repo.settings.businessName}',
            ),
            Expanded(
              child: ListView(
                children: [
                  CustomerHeroStats(
                    leftLabel: 'Total pending',
                    leftValue: CurrencyUtils.format(pendingDisplay),
                    centerLabel: 'Paid (month)',
                    centerValue: CurrencyUtils.format(monthly.paidAmount),
                    rightLabel: 'This month bill',
                    rightValue: CurrencyUtils.format(monthly.totalAmount),
                  ),
                  CustomerInfoBanner(
                    icon: Icons.verified_user_rounded,
                    message:
                        'Bulk customer — deliveries & payments managed by your shop',
                    color: CustomerColors.contractPurple,
                  ),
                  CustomerInfoBar(
                    customer: crm,
                    colorIndex: idx >= 0 ? idx : 0,
                  ),
                  CustomerPendingCard(
                    totalPending: totalPending,
                    advanceCredit: advanceCredit,
                    previousPending: previousPending,
                    monthStats: monthly,
                  ),
                  CustomerMonthlyOverviewSection(
                    statsForMonth: (m) => repo.monthlyStatsForCustomer(crm.id, m),
                    onMonthTap: (m) => context.push(
                      '${AppRoutes.customerMonthDetail}?customerId=${crm.id}'
                      '&year=${m.year}&month=${m.month}',
                    ),
                    year: now.year,
                    initialMonth: now.month,
                    emptyHint: 'No deliveries yet on your account',
                    footerHint: 'Tap a month for deliveries & payments',
                  ),
                  CustomerSectionTitle(title: 'Your water shop'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomerShopInfoCard(settings: repo.settings),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
