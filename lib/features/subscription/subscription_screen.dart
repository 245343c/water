import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/subscription_service.dart';
import 'package:sri_sai_ro_water/core/subscription/shop_subscription_logic.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/models/subscription_plan.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/subscription/widgets/subscription_widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlanId = SubscriptionPlans.starter.id;
  SubscriptionBillingCycle _billingCycle = SubscriptionBillingCycle.monthly;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await context.read<SubscriptionService>().refreshSubscription();
        if (!mounted) return;
        final shop = context.read<SubscriptionService>().currentShop;
        if (shop?.planId != null && shop!.planId!.isNotEmpty) {
          setState(() => _selectedPlanId = shop.planId!);
        }
      } catch (_) {}
    });
  }

  Future<void> _activate() async {
    setState(() => _busy = true);
    try {
      await context.read<SubscriptionService>().activatePlan(
            planId: _selectedPlanId,
            billingCycle: _billingCycle,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plan activated · full access restored',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SubscriptionService>();
    final shop = service.currentShop;
    final view = shop?.subscriptionView;
    final status = view?.effectiveStatus ?? ShopSubscriptionStatus.trial;
    final selectedPlan =
        SubscriptionPlans.byId(_selectedPlanId) ?? SubscriptionPlans.standard;
    final price = _billingCycle == SubscriptionBillingCycle.annual
        ? selectedPlan.annualPriceInr
        : selectedPlan.monthlyPriceInr;

    return Scaffold(
      backgroundColor: MoreColors.screenBg,
      body: MoreScaffold(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              MoreHeader(title: 'Subscription'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
                  children: [
                    _HeroCard(status: status, view: view, shop: shop),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: CustomersColors.whiteCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Choose your plan',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: CustomersColors.titleNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Every new shop gets ${SubscriptionPlans.trialDays} days free with full access. Customers and drivers never pay.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: CustomersColors.labelGrey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<SubscriptionBillingCycle>(
                            segments: const [
                              ButtonSegment(
                                value: SubscriptionBillingCycle.monthly,
                                label: Text('Monthly'),
                              ),
                              ButtonSegment(
                                value: SubscriptionBillingCycle.annual,
                                label: Text('Annual · save'),
                              ),
                            ],
                            selected: {_billingCycle},
                            onSelectionChanged: _busy
                                ? null
                                : (value) => setState(
                                      () => _billingCycle = value.first,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...SubscriptionPlans.catalog.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SubscriptionPlanCard(
                          plan: plan,
                          selected: plan.id == _selectedPlanId,
                          billingCycle: _billingCycle,
                          onTap: _busy
                              ? () {}
                              : () => setState(() => _selectedPlanId = plan.id),
                        ),
                      ),
                    ),
                    _FaqCard(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      status == ShopSubscriptionStatus.trial
                          ? 'Activate now to lock in your plan before trial ends'
                          : 'Mock payment · Razorpay coming soon',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: CustomersColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _busy ? null : _activate,
                      style: FilledButton.styleFrom(
                        backgroundColor: CustomersColors.addButton,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              status == ShopSubscriptionStatus.active
                                  ? 'Switch to ${selectedPlan.name} · ${CurrencyUtils.format(price.toDouble())}'
                                  : 'Activate ${selectedPlan.name} · ${CurrencyUtils.format(price.toDouble())}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
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
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.status,
    required this.view,
    required this.shop,
  });

  final ShopSubscriptionStatus status;
  final ShopSubscriptionView? view;
  final Shop? shop;

  @override
  Widget build(BuildContext context) {
    final headline = switch (status) {
      ShopSubscriptionStatus.trial =>
        '${view?.trialDaysRemaining ?? SubscriptionPlans.trialDays} days left in free trial',
      ShopSubscriptionStatus.active => 'Your shop subscription is active',
      ShopSubscriptionStatus.grace =>
        '${view?.graceDaysRemaining ?? 0} days of grace access',
      ShopSubscriptionStatus.expired => 'Renew to continue operations',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.18),
            blurRadius: 14,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  status == ShopSubscriptionStatus.trial
                      ? Icons.celebration_rounded
                      : Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  shop?.name ?? 'Your water plant',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (status == ShopSubscriptionStatus.trial && view != null) ...[
            const SizedBox(height: 8),
            Text(
              '${view!.trialDaysRemaining ?? SubscriptionPlans.trialDays} of ${SubscriptionPlans.trialDays} trial days left · full access now',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: view!.trialProgress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                color: Colors.white,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Customers and drivers stay free · only the shop pays',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomersColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good to know',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CustomersColors.titleNavy,
            ),
          ),
          const SizedBox(height: 10),
          _faqRow(
            'Who pays?',
            'Only the shop owner (admin). Customers and drivers use the app free.',
          ),
          _faqRow(
            'Trial',
            '${SubscriptionPlans.trialDays} days full access for every new account — no card required today.',
          ),
          _faqRow(
            'After trial',
            '${SubscriptionPlans.graceDays}-day grace period, then renew to keep your shop listed and staff logins active.',
          ),
        ],
      ),
    );
  }

  Widget _faqRow(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CustomersColors.titleNavy,
            ),
          ),
          Text(
            a,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: CustomersColors.labelGrey,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
