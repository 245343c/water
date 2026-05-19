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
          content: Text('Please set your delivery location on the map'),
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
      name: _nameController.text.trim(),
      phone: user.phone,
      address: _addressController.text.trim(),
      latitude: _lat!,
      longitude: _lng!,
      email: _emailController.text.trim(),
      place: _place,
      linkedCrmCustomerId:
          repo.customerProfileByUserId(user.id)?.linkedCrmCustomerId,
      onboardingComplete: true,
    );
    repo.saveCustomerProfile(profile);
    auth.markCustomerOnboardingComplete(user.id, name: profile.name);
    if (!mounted) return;
    setState(() => _saving = false);
    context.go(AppRoutes.customerHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          children: [
            CustomerHeader(
              title: 'Delivery setup',
              subtitle: 'Address + map pin for home delivery',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: CustomerColors.cardDecoration,
                      child: Column(
                        children: [
                          CustomerTextField(
                            label: 'Your name',
                            controller: _nameController,
                            required: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          CustomerTextField(
                            label: 'Delivery address',
                            controller: _addressController,
                            maxLines: 2,
                            required: true,
                            validator: (v) => v == null || v.trim().length < 8
                                ? 'Enter full address'
                                : null,
                          ),
                          CustomerTextField(
                            label: 'Email (optional)',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pin on map *',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShopLocationPicker(
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
                    const SizedBox(height: 20),
                    CustomerPrimaryButton(
                      label: 'Save & find shops',
                      loading: _saving,
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
