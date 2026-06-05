import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer_app_profile.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/auth_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/shop_location_picker.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  State<CustomerOnboardingScreen> createState() =>
      _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  double? _lat;
  double? _lng;
  String _place = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();
    final user = auth.currentUser;
    if (user != null) {
      final p = repo.customerProfileByUserId(user.id);
      if (p != null) {
        _nameController.text = p.name;
        _addressController.text = p.address;
        _emailController.text = p.email;
        _lat = p.latitude;
        _lng = p.longitude;
        _place = p.place;
      } else {
        _nameController.text = user.ownerName != 'Customer'
            ? user.ownerName
            : '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Set your delivery location on the map',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    final profile = CustomerAppProfile(
      userId: user.id,
      name: _capitalizeWords(_nameController.text.trim()),
      phone: user.phone,
      address: _capitalizeSentence(_addressController.text.trim()),
      latitude: _lat!,
      longitude: _lng!,
      email: _emailController.text.trim(),
      place: _place,
      linkedCrmCustomerId: repo
          .customerProfileByUserId(user.id)
          ?.linkedCrmCustomerId,
      onboardingComplete: true,
    );
    await repo.saveCustomerProfileToFirestore(profile);
    auth.markCustomerOnboardingComplete(user.id, name: profile.name);
    if (!mounted) return;
    setState(() => _saving = false);
    context.go(AppRoutes.customerHome);
  }

  static String _capitalizeWords(String s) {
    if (s.isEmpty) return s;
    return s
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }

  static String _capitalizeSentence(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPremiumScreenLayout(
      heroTitle: 'Delivery address',
      heroSubtitle: 'We deliver RO water to this location',
      heroIcon: Icons.local_shipping_rounded,
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.customerHome),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Almost there',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Confirm your details for delivery',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 16),
            AuthFormCard(
              premium: true,
              title: 'Your details',
              children: [
                AuthTextField(
                  premium: true,
                  label: 'Your name',
                  controller: _nameController,
                  hint: 'e.g. Ramesh Kumar',
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  required: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                AuthTextField(
                  premium: true,
                  label: 'Full address',
                  controller: _addressController,
                  hint: 'House no., street, area, city',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  required: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().length < 8
                      ? 'Enter your full address'
                      : null,
                ),
                AuthTextField(
                  premium: true,
                  label: 'Email',
                  controller: _emailController,
                  hint: 'you@email.com (optional)',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
            AuthFormCard(
              premium: true,
              title: 'Delivery location',
              subtitle: 'Pin your home on the map',
              children: [
                ShopLocationPicker(
                  minimal: true,
                  embedded: true,
                  latitude: _lat,
                  longitude: _lng,
                  addressText: _addressController.text,
                  onChanged: (lat, lng, place) {
                    setState(() {
                      _lat = lat;
                      _lng = lng;
                      if (place != null && place.isNotEmpty) {
                        _place = place;
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
            AuthPrimaryButton(
              premium: true,
              label: 'Save & continue',
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
