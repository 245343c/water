import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/settings_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/shop_location_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _normalPriceController;
  late final TextEditingController _coolPriceController;
  bool _initialized = false;

  double? _shopLat;
  double? _shopLng;
  bool _homeDelivery = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _normalPriceController = TextEditingController();
    _coolPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _normalPriceController.dispose();
    _coolPriceController.dispose();
    super.dispose();
  }

  void _load(BusinessSettings s) {
    if (_initialized) return;
    _nameController.text = s.businessName;
    _addressController.text = s.address;
    _phoneController.text = s.phone;
    _emailController.text = s.email;
    _normalPriceController.text = s.normalPrice.toStringAsFixed(0);
    _coolPriceController.text = s.coolPrice.toStringAsFixed(0);
    _shopLat = s.shopLatitude;
    _shopLng = s.shopLongitude;
    _homeDelivery = s.homeDeliveryAvailable;
    _initialized = true;
  }

  void _save(WaterPlantRepository repo) {
    if (!_formKey.currentState!.validate()) return;

    repo.updateSettings(
      repo.settings.copyWith(
        businessName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        normalPrice: double.parse(_normalPriceController.text),
        coolPrice: double.parse(_coolPriceController.text),
        shopLatitude: _shopLat,
        shopLongitude: _shopLng,
        homeDeliveryAvailable: _homeDelivery,
        clearMapPin: _shopLat == null || _shopLng == null,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        _load(repo.settings);

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: AddEditCustomerScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AddEditCustomerHeader(
                  title: 'Business Settings',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        const SettingsSectionLabel(title: 'Business details'),
                        AddEditCustomerFormCard(
                          children: [
                            AddEditCustomerField(
                              label: 'Business Name',
                              controller: _nameController,
                              hint: 'Your water plant name',
                              icon: Icons.storefront_outlined,
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Business name is required' : null,
                            ),
                            AddEditCustomerField(
                              label: 'Address',
                              controller: _addressController,
                              hint: 'Shop / plant address',
                              icon: Icons.location_on_outlined,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                              required: true,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Address is required' : null,
                            ),
                            AddEditCustomerField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              hint: 'Contact number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              required: true,
                              validator: (v) {
                                final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                                if (digits.length < 10) return 'Valid phone required';
                                return null;
                              },
                            ),
                            AddEditCustomerField(
                              label: 'Email',
                              controller: _emailController,
                              hint: 'business@email.com (optional)',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: validateEmailOptional,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        const SettingsSectionLabel(title: 'Customer app'),
                        AddEditCustomerFormCard(
                          children: [
                            SettingsHomeDeliverySwitch(
                              value: _homeDelivery,
                              onChanged: (v) => setState(() => _homeDelivery = v),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                        const SettingsSectionLabel(title: 'Map location'),
                        ShopLocationPicker(
                          minimal: true,
                          latitude: _shopLat,
                          longitude: _shopLng,
                          addressText: _addressController.text,
                          onChanged: (lat, lng, _) {
                            setState(() {
                              _shopLat = lat;
                              _shopLng = lng;
                            });
                          },
                        ),
                        const SettingsSectionLabel(title: 'Can prices'),
                        AddEditCustomerFormCard(
                          children: [
                            AddEditCustomerField(
                              label: 'Normal can price (₹)',
                              controller: _normalPriceController,
                              hint: 'e.g. 20',
                              icon: Icons.water_drop_outlined,
                              keyboardType: TextInputType.number,
                              required: true,
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n <= 0) return 'Enter a valid price';
                                return null;
                              },
                            ),
                            AddEditCustomerField(
                              label: 'Cool can price (₹)',
                              controller: _coolPriceController,
                              hint: 'e.g. 30',
                              icon: Icons.ac_unit_outlined,
                              keyboardType: TextInputType.number,
                              required: true,
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n <= 0) return 'Enter a valid price';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AddEditCustomerSaveButton(
                  label: 'Save Settings',
                  onPressed: () => _save(repo),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
