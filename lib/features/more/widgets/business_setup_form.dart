import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/settings_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/shop_location_picker.dart';

/// Business profile, map pin and customer app — prices live under Products.
class BusinessSetupForm extends StatefulWidget {
  const BusinessSetupForm({
    super.key,
    this.showSaveButton = true,
    this.onSaved,
  });

  final bool showSaveButton;
  final VoidCallback? onSaved;

  @override
  State<BusinessSetupForm> createState() => BusinessSetupFormState();
}

class BusinessSetupFormState extends State<BusinessSetupForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _load(BusinessSettings s) {
    if (_initialized) return;
    _nameController.text = s.businessName;
    _addressController.text = s.address;
    _phoneController.text = s.phone;
    _emailController.text = s.email;
    _shopLat = s.shopLatitude;
    _shopLng = s.shopLongitude;
    _homeDelivery = s.homeDeliveryAvailable;
    _initialized = true;
  }

  bool save(WaterPlantRepository repo) {
    if (!_formKey.currentState!.validate()) return false;

    final current = repo.settings;
    repo.updateSettings(
      current.copyWith(
        businessName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        shopLatitude: _shopLat,
        shopLongitude: _shopLng,
        homeDeliveryAvailable: _homeDelivery,
        clearMapPin: _shopLat == null || _shopLng == null,
      ),
    );
    return true;
  }

  void _onSavePressed() {
    final repo = context.read<WaterPlantRepository>();
    if (!save(repo)) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Business settings saved', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        _load(repo.settings);

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AddEditCustomerField(
                label: 'Business name',
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
                label: 'Phone number',
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
              const _BusinessSetupDivider(),
              Text(
                'Shop on map',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AddEditCustomerColors.titleNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pan the map — pin stays at center',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AddEditCustomerColors.labelGrey,
                ),
              ),
              const SizedBox(height: 10),
              ShopLocationPicker(
                minimal: true,
                embedded: true,
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
              const _BusinessSetupDivider(),
              SettingsHomeDeliverySwitch(
                value: _homeDelivery,
                onChanged: (v) => setState(() => _homeDelivery = v),
              ),
              if (widget.showSaveButton) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _onSavePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomersColors.addButton,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save business settings',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BusinessSetupDivider extends StatelessWidget {
  const _BusinessSetupDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: CustomersColors.divider),
    );
  }
}
