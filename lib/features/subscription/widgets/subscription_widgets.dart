import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/subscription_banner_prefs.dart';
import 'package:sri_sai_ro_water/core/services/subscription_service.dart';
import 'package:sri_sai_ro_water/core/subscription/shop_subscription_logic.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/models/subscription_plan.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

abstract final class SubscriptionColors {
  static const trial = Color(0xFF1A73E8);
  static const active = Color(0xFF16A34A);
  static const grace = Color(0xFFEA580C);
  static const expired = Color(0xFFDC2626);
}

class SubscriptionStatusBanner extends StatefulWidget {
  const SubscriptionStatusBanner({super.key, this.compact = false});

  final bool compact;

  @override
  State<SubscriptionStatusBanner> createState() =>
      _SubscriptionStatusBannerState();
}

class _SubscriptionStatusBannerState extends State<SubscriptionStatusBanner> {
  bool _dismissedToday = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDismissState();
  }

  Future<void> _loadDismissState() async {
    final shopId = context.read<SubscriptionService>().currentShop?.id;
    if (shopId == null) {
      if (mounted) setState(() => _prefsLoaded = true);
      return;
    }
    final dismissed = await SubscriptionBannerPrefs.wasDismissedToday(shopId);
    if (!mounted) return;
    setState(() {
      _dismissedToday = dismissed;
      _prefsLoaded = true;
    });
  }

  Future<void> _dismissForToday(String shopId) async {
    await SubscriptionBannerPrefs.dismissForToday(shopId);
    if (!mounted) return;
    setState(() => _dismissedToday = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) return const SizedBox.shrink();

    final service = context.watch<SubscriptionService>();
    final shop = service.currentShop;
    if (shop == null) return const SizedBox.shrink();

    final view = shop.subscriptionView;
    final status = view.effectiveStatus;
    if (status == ShopSubscriptionStatus.active && !widget.compact) {
      return const SizedBox.shrink();
    }
    if (status == ShopSubscriptionStatus.trial && _dismissedToday) {
      return const SizedBox.shrink();
    }

    final (Color bg, Color fg, IconData icon, String title, String subtitle) =
        switch (status) {
          ShopSubscriptionStatus.trial => (
            const Color(0xFFEFF6FF),
            SubscriptionColors.trial,
            Icons.celebration_rounded,
            view.isTrialEndingSoon ? 'Trial ending soon' : 'Free trial active',
            _trialSubtitle(view),
          ),
          ShopSubscriptionStatus.grace => (
            const Color(0xFFFFF7ED),
            SubscriptionColors.grace,
            Icons.schedule_rounded,
            'Renewal grace period',
            'Your plan expired · ${view.graceDaysRemaining ?? 0} day(s) left before access pauses',
          ),
          ShopSubscriptionStatus.expired => (
            const Color(0xFFFEF2F2),
            SubscriptionColors.expired,
            Icons.lock_rounded,
            'Subscription expired',
            'Renew to keep drivers, orders, and customer records working',
          ),
          ShopSubscriptionStatus.active => (
            const Color(0xFFECFDF5),
            SubscriptionColors.active,
            Icons.verified_rounded,
            '${service.currentPlan.name} plan active',
            _activeSubtitle(shop, service.currentPlan),
          ),
        };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 0 : 8,
        widget.compact ? 0 : 8,
        widget.compact ? 0 : 8,
        0,
      ),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push(AppRoutes.subscription),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: fg.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: fg, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: widget.compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: CustomersColors.titleNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: widget.compact ? 11 : 12,
                          color: CustomersColors.labelGrey,
                          height: 1.35,
                        ),
                      ),
                      if (status == ShopSubscriptionStatus.trial) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: view.trialProgress,
                            minHeight: 5,
                            backgroundColor: Colors.white,
                            color: fg,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (status == ShopSubscriptionStatus.trial)
                  IconButton(
                    tooltip: 'Dismiss for today',
                    onPressed: () => _dismissForToday(shop.id),
                    icon: Icon(Icons.close_rounded, color: fg.withValues(alpha: 0.7)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _trialSubtitle(ShopSubscriptionView view) {
    final days = view.trialDaysRemaining ?? SubscriptionPlans.trialDays;
    final end = view.renewalDate;
    final endLabel = end == null
        ? ''
        : ' · ends ${DateFormat('d MMM').format(end)}';
    return '$days day(s) left in your ${SubscriptionPlans.trialDays}-day trial$endLabel';
  }

  static String _activeSubtitle(Shop shop, SubscriptionPlan plan) {
    final renews = shop.currentPeriodEndsAt;
    if (renews == null) return '${plan.name} · full access';
    return 'Renews ${DateFormat('d MMM yyyy').format(renews)}';
  }
}

class AccountSubscriptionCard extends StatelessWidget {
  const AccountSubscriptionCard({super.key});

  static String subtitleFor({
    required ShopSubscriptionStatus status,
    required ShopSubscriptionView view,
    required SubscriptionPlan plan,
    required Shop shop,
  }) {
    return switch (status) {
      ShopSubscriptionStatus.trial =>
        'Tap to manage · ${view.trialDaysRemaining ?? SubscriptionPlans.trialDays} days left on trial',
      ShopSubscriptionStatus.grace =>
        'Renew within ${view.graceDaysRemaining ?? 0} day(s) to keep drivers, orders, and records active',
      ShopSubscriptionStatus.expired =>
        'Renew now to restore drivers, quick orders, and customer records',
      ShopSubscriptionStatus.active => () {
        final renews = shop.currentPeriodEndsAt;
        if (renews == null) return '${plan.name} plan · full access';
        return '${plan.name} plan · renews ${DateFormat('d MMM yyyy').format(renews)}';
      }(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SubscriptionService>();
    final shop = service.currentShop;
    if (shop == null) return const AccountSubscriptionCardPlaceholder();

    final view = shop.subscriptionView;
    final status = view.effectiveStatus;
    final plan = service.currentPlan;

    final badge = switch (status) {
      ShopSubscriptionStatus.trial => 'Free trial',
      ShopSubscriptionStatus.active => 'Active',
      ShopSubscriptionStatus.grace => 'Grace',
      ShopSubscriptionStatus.expired => 'Expired',
    };

    final badgeColor = switch (status) {
      ShopSubscriptionStatus.trial => SubscriptionColors.trial,
      ShopSubscriptionStatus.active => SubscriptionColors.active,
      ShopSubscriptionStatus.grace => SubscriptionColors.grace,
      ShopSubscriptionStatus.expired => SubscriptionColors.expired,
    };

    final subtitle = subtitleFor(
      status: status,
      view: view,
      plan: plan,
      shop: shop,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push(AppRoutes.subscription),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CustomersColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspace_premium_rounded, color: badgeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CustomersColors.titleNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: CustomersColors.labelGrey,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AccountSubscriptionCardPlaceholder extends StatelessWidget {
  const AccountSubscriptionCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CustomersColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.billingCycle,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final SubscriptionBillingCycle billingCycle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = billingCycle == SubscriptionBillingCycle.annual
        ? plan.annualPriceInr
        : plan.monthlyPriceInr;
    final period = billingCycle == SubscriptionBillingCycle.annual
        ? '/ year'
        : '/ month';

    return Material(
      color: selected ? const Color(0xFFF8FAFF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? CustomersColors.addButton
                  : CustomersColors.cardBorder,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: CustomersColors.addButton.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CustomersColors.titleNavy,
                      ),
                    ),
                  ),
                  if (plan.recommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CustomersColors.addButton,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Popular',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan.tagline,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: CustomersColors.labelGrey,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: CurrencyUtils.format(price.toDouble()),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: CustomersColors.titleNavy,
                      ),
                    ),
                    TextSpan(
                      text: period,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: CustomersColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: selected
                            ? CustomersColors.addButton
                            : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: CustomersColors.titleNavy,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
