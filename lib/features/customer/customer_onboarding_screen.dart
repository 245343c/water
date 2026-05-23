import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer_app_profile.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/features/more/widgets/shop_location_picker.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  State<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
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
        _nameController.text =
            user.ownerName != 'Customer' ? user.ownerName : '';
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
        const SnackBar(
          content: Text('Set your delivery location on the map'),
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
      linkedCrmCustomerId:
          repo.customerProfileByUserId(user.id)?.linkedCrmCustomerId,
      onboardingComplete: true,
    );
    try {
      await repo.saveCustomerProfile(profile);
      auth.markCustomerOnboardingComplete(user.id, name: profile.name);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    context.go(AppRoutes.customerHome);
  }

  static String _capitalizeWords(String s) {
    if (s.isEmpty) return s;
    return s.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  static String _capitalizeSentence(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = customerBottomInset(context, extra: 12);

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.customerHome),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: CustomerColors.titleNavy,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery address',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CustomerColors.titleNavy,
                          ),
                        ),
                        Text(
                          'We deliver RO water to this location',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: CustomerColors.labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: CustomerColors.cardDecoration,
                      child: Column(
                        children: [
                          CustomerTextField(
                            label: 'Your name',
                            controller: _nameController,
                            hint: 'e.g. Ramesh Kumar',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            required: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          CustomerTextField(
                            label: 'Full address',
                            controller: _addressController,
                            hint: 'House no., street, area, city',
                            icon: Icons.home_outlined,
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences,
                            required: true,
                            validator: (v) => v == null || v.trim().length < 8
                                ? 'Enter your full address'
                                : null,
                          ),
                          CustomerTextField(
                            label: 'Email (optional)',
                            controller: _emailController,
                            hint: 'you@email.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DELIVERY LOCATION ON MAP',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: CustomerColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShopLocationPicker(
                      minimal: true,
                      latitude: _lat,
                      longitude: _lng,
                      addressText: _addressController.text,
                      onChanged: (lat, lng, place) {
                        setState(() {
                          _lat = lat;
                          _lng = lng;
                          if (place != null && place.isNotEmpty) _place = place;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
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
              child: CustomerPrimaryButton(
                label: 'Save & continue',
                loading: _saving,
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
