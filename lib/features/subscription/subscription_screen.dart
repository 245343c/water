import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final shop = repo.shopById(WaterPlantRepository.defaultShopId);
        final customers = repo.customersForShop(
          WaterPlantRepository.defaultShopId,
        );
        final drivers = repo.drivers
            .where(
              (d) =>
                  repo.shopIdForDriver(d.id) ==
                  WaterPlantRepository.defaultShopId,
            )
            .length;

        return Scaffold(
          backgroundColor: MoreColors.screenBg,
          body: PremiumResponsiveBody(
            maxWidth: 1180,
            child: Column(
              children: [
                _SubscriptionHeader(
                  shopName: shop?.name ?? repo.settings.businessName,
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _CurrentPlanCard(
                        status:
                            shop?.subscriptionStatus ??
                            ShopSubscriptionStatus.trial,
                        customerCount: customers.length,
                        driverCount: drivers,
                      ),
                      const SizedBox(height: 14),
                      const _SaasNoteCard(),
                      const SizedBox(height: 18),
                      const _SectionLabel('Recommended plans'),
                      const SizedBox(height: 10),
                      _PlanCard(
                        name: 'Starter',
                        price: 299,
                        subtitle: 'For small RO plants',
                        limits: const [
                          'Up to 100 customers',
                          '1 driver account',
                          'Orders, deliveries, reports',
                        ],
                        onSelect: () =>
                            _mockAction(context, 'Starter plan selected'),
                      ),
                      const SizedBox(height: 10),
                      _PlanCard(
                        name: 'Growth',
                        price: 499,
                        subtitle: 'Best for your current use case',
                        highlighted: true,
                        limits: const [
                          'Up to 500 customers',
                          '5 driver accounts',
                          'Customer app access',
                          'Monthly bills and notifications',
                        ],
                        onSelect: () =>
                            _mockAction(context, 'Growth plan selected'),
                      ),
                      const SizedBox(height: 10),
                      _PlanCard(
                        name: 'Pro',
                        price: 999,
                        subtitle: 'For larger delivery teams',
                        limits: const [
                          'Up to 2000 customers',
                          '20 driver accounts',
                          'Priority support',
                          'Future multi-plant controls',
                        ],
                        onSelect: () =>
                            _mockAction(context, 'Pro plan selected'),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Payment setup'),
                      const SizedBox(height: 10),
                      _PaymentSetupCard(
                        onActivate: () => _mockAction(
                          context,
                          'Payment gateway will connect later',
                        ),
                      ),
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

  static void _mockAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SubscriptionHeader extends StatelessWidget {
  const _SubscriptionHeader({required this.shopName, required this.onBack});

  final String shopName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Subscription',
      subtitle: shopName,
      onBack: onBack,
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.status,
    required this.customerCount,
    required this.driverCount,
  });

  final ShopSubscriptionStatus status;
  final int customerCount;
  final int driverCount;

  String get _statusLabel => switch (status) {
    ShopSubscriptionStatus.trial => 'Trial',
    ShopSubscriptionStatus.active => 'Active',
    ShopSubscriptionStatus.grace => 'Grace period',
    ShopSubscriptionStatus.expired => 'Expired',
  };

  Color get _statusColor => switch (status) {
    ShopSubscriptionStatus.trial => const Color(0xFFEA580C),
    ShopSubscriptionStatus.active => const Color(0xFF16A34A),
    ShopSubscriptionStatus.grace => const Color(0xFFD97706),
    ShopSubscriptionStatus.expired => const Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin subscription',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Customers and drivers use the app free',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PlanStat(label: 'Customers', value: '$customerCount'),
              const SizedBox(width: 8),
              _PlanStat(label: 'Drivers', value: '$driverCount'),
              const SizedBox(width: 8),
              const _PlanStat(label: 'Renewal', value: 'Mock'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaasNoteCard extends StatelessWidget {
  const _SaasNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2563EB),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Subscription applies only to the water plant admin. Customers and drivers should never pay for app access.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.4,
                color: MoreColors.titleNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.subtitle,
    required this.limits,
    required this.onSelect,
    this.highlighted = false,
  });

  final String name;
  final double price;
  final String subtitle;
  final List<String> limits;
  final VoidCallback onSelect;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final accent = highlighted ? const Color(0xFF2563EB) : MoreColors.iconNavy;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? const Color(0xFF93C5FD) : MoreColors.cardBorder,
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: MoreColors.titleNavy,
                          ),
                        ),
                        if (highlighted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Recommended',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: MoreColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${CurrencyUtils.format(price)}/mo',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...limits.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: accent, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.3,
                        color: MoreColors.titleNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSelect,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                highlighted ? 'Activate Growth' : 'Select plan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSetupCard extends StatelessWidget {
  const _PaymentSetupCard({required this.onActivate});

  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoreColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Razorpay later, mock now',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MoreColors.titleNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This screen is ready for Firebase subscription status and Razorpay payment webhooks in the backend phase.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.4,
              color: MoreColors.labelGrey,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onActivate,
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: Text(
              'Connect payment gateway later',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: MoreColors.iconNavy,
              side: const BorderSide(color: MoreColors.iconNavy),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: MoreColors.labelGrey,
      ),
    );
  }
}
