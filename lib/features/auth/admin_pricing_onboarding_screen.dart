import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/widgets/delivery_product_type_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Shown once after new admin signup — must save rates before using the app.
class AdminPricingOnboardingScreen extends StatefulWidget {
  const AdminPricingOnboardingScreen({super.key});

  @override
  State<AdminPricingOnboardingScreen> createState() =>
      _AdminPricingOnboardingScreenState();
}

class _AdminPricingOnboardingScreenState
    extends State<AdminPricingOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<DeliveryProductType, TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final repo = context.read<WaterPlantRepository>();
    _controllers = {
      for (final type in DeliveryProductType.catalog)
        type: TextEditingController(
          text: _formatRate(repo.shopDefaultRateForDeliveryType(type)),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatRate(double rate) =>
      rate > 0 ? rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : 1) : '';

  double? _parseRate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 0;
    return double.tryParse(trimmed);
  }

  BusinessSettings _settingsFromForm(WaterPlantRepository repo) {
    final base = repo.settings;
    double rate(DeliveryProductType type) =>
        _parseRate(_controllers[type]!.text) ?? 0;

    return base.copyWith(
      normalPrice: rate(DeliveryProductType.normalCan),
      coolPrice: rate(DeliveryProductType.coolCan),
      lorryLiterPrice: rate(DeliveryProductType.lorryLiters),
      fullLorryPrice: rate(DeliveryProductType.fullLorry),
      autoLiterPrice: rate(DeliveryProductType.autoLiters),
      autoCanPrice: rate(DeliveryProductType.autoCans),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final normal = _parseRate(_controllers[DeliveryProductType.normalCan]!.text) ?? 0;
    final cool = _parseRate(_controllers[DeliveryProductType.coolCan]!.text) ?? 0;
    if (normal <= 0 || cool <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter Normal and Cool can rates (required)',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<WaterPlantRepository>();
      final auth = context.read<AuthRepository>();
      final settings = _settingsFromForm(repo);
      await repo.completePricingSetupInFirestore(settings);
      auth.markPricingSetupComplete();
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save rates. Try again.',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WaterPlantRepository>();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: CustomersColors.screenBg,
        body: CustomersScaffold(
          usePageGradient: true,
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.price_change_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Set your delivery prices',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'These rates apply to all customers and quick orders. '
                          'You can change them anytime under Products.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          repo.settings.businessName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(12, 16, 12, bottom + 96),
                      children: [
                        for (final type in DeliveryProductType.catalog) ...[
                          _PricingRateCard(
                            type: type,
                            controller: _controllers[type]!,
                            required: type == DeliveryProductType.normalCan ||
                                type == DeliveryProductType.coolCan,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: CustomersColors.addButton,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save prices & continue',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PricingRateCard extends StatelessWidget {
  const _PricingRateCard({
    required this.type,
    required this.controller,
    required this.required,
  });

  final DeliveryProductType type;
  final TextEditingController controller;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeliveryTypeIcon(type: type, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CustomersColors.titleNavy,
                          ),
                        ),
                      ),
                      if (required)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Required',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    type.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: CustomersColors.labelGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: CustomersColors.titleNavy,
                      ),
                      suffixText: type.rateLabel,
                      suffixStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        color: CustomersColors.labelGrey,
                      ),
                      hintText: required ? 'e.g. ${type == DeliveryProductType.normalCan ? 20 : 30}' : '0',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CustomersColors.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CustomersColors.cardBorder,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CustomersColors.titleNavy,
                    ),
                    validator: (value) {
                      if (!required) return null;
                      final rate = double.tryParse(value?.trim() ?? '');
                      if (rate == null || rate <= 0) {
                        return 'Enter a valid rate';
                      }
                      return null;
                    },
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
