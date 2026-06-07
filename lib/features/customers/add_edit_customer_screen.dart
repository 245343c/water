import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/input_validators.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/customer_delete_dialog.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_pricing_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_route_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class AddEditCustomerScreen extends StatefulWidget {
  const AddEditCustomerScreen({super.key, this.customerId});

  final String? customerId;

  bool get isEditing => customerId != null;

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _placeController;
  late final TextEditingController _addressController;
  late final TextEditingController _driverNameTeController;
  late final TextEditingController _driverNameHiController;
  late final TextEditingController _driverAddressNoteTeController;
  late final TextEditingController _driverAddressNoteHiController;
  bool _loaded = false;
  bool _pricingReady = false;
  List<CustomerProductPrice> _productPrices = [];
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context
          .read<WaterPlantRepository>()
          .loadDeliveryRoutesForCurrentAdmin();
    });
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _placeController = TextEditingController();
    _addressController = TextEditingController();
    _driverNameTeController = TextEditingController();
    _driverNameHiController = TextEditingController();
    _driverAddressNoteTeController = TextEditingController();
    _driverAddressNoteHiController = TextEditingController();
  }

  void _loadCustomer(Customer? customer, WaterPlantRepository repo) {
    if (_loaded) return;
    if (customer != null) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
      _placeController.text = customer.place;
      _addressController.text = customer.address;
      _driverNameTeController.text = customer.driverNameTe;
      _driverNameHiController.text = customer.driverNameHi;
      _driverAddressNoteTeController.text = customer.driverAddressNoteTe;
      _driverAddressNoteHiController.text = customer.driverAddressNoteHi;
      _productPrices = customer.productPrices.isEmpty
          ? repo.defaultCustomerPricing()
          : List<CustomerProductPrice>.from(customer.productPrices);
      _selectedRouteId = customer.routeId;
    }
    _loaded = true;
  }

  void _initPricingForNewCustomer(WaterPlantRepository repo) {
    if (_pricingReady) return;
    if (!widget.isEditing) {
      _productPrices = repo.defaultCustomerPricing();
    }
    _pricingReady = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _placeController.dispose();
    _addressController.dispose();
    _driverNameTeController.dispose();
    _driverNameHiController.dispose();
    _driverAddressNoteTeController.dispose();
    _driverAddressNoteHiController.dispose();
    super.dispose();
  }

  Future<void> _save(WaterPlantRepository repo) async {
    if (!_formKey.currentState!.validate()) return;

    final data = (
      name: _nameController.text.trim(),
      phone: InputValidators.phoneDigits(_phoneController.text),
      email: _emailController.text.trim(),
      place: _placeController.text.trim(),
      address: _addressController.text.trim(),
      driverNameTe: _driverNameTeController.text.trim(),
      driverNameHi: _driverNameHiController.text.trim(),
      driverAddressNoteTe: _driverAddressNoteTeController.text.trim(),
      driverAddressNoteHi: _driverAddressNoteHiController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        final existing = repo.customerById(widget.customerId!);
        if (existing != null) {
          final updated = existing.copyWith(
            name: data.name,
            phone: data.phone,
            email: data.email,
            place: data.place,
            address: data.address,
            driverNameTe: data.driverNameTe,
            driverNameHi: data.driverNameHi,
            driverAddressNoteTe: data.driverAddressNoteTe,
            driverAddressNoteHi: data.driverAddressNoteHi,
            productPrices: _productPrices,
            routeId: _selectedRouteId,
            clearRoute: _selectedRouteId == null,
          );
          await repo.updateCustomerInCurrentAdminShop(updated);
        }
      } else {
        await repo.addCustomerToCurrentAdminShop(
          name: data.name,
          phone: data.phone,
          email: data.email,
          place: data.place,
          address: data.address,
          driverNameTe: data.driverNameTe,
          driverNameHi: data.driverNameHi,
          driverAddressNoteTe: data.driverAddressNoteTe,
          driverAddressNoteHi: data.driverAddressNoteHi,
          productPrices: _productPrices,
          routeId: _selectedRouteId,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('StateError: ', ''),
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Customer updated' : 'Customer added',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Future<void> _delete(WaterPlantRepository repo, String customerName) async {
    final confirmed = await confirmDeleteCustomer(
      context,
      customerName: customerName,
    );
    if (!confirmed || !mounted) return;
    try {
      await repo.deleteCustomerFromCurrentAdminShop(widget.customerId!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('StateError: ', ''),
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Customer deleted', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go(AppRoutes.customers);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = widget.isEditing
            ? repo.customerById(widget.customerId!)
            : null;
        _loadCustomer(customer, repo);
        _initPricingForNewCustomer(repo);

        if (widget.isEditing && customer == null) {
          return Scaffold(
            backgroundColor: CustomersColors.screenBg,
            body: AddEditCustomerScaffold(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    AddEditCustomerHeader(
                      title: 'Edit Customer',
                      subtitle: null,
                      onBack: () => context.pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Customer not found',
                          style: GoogleFonts.poppins(
                            color: AddEditCustomerColors.labelGrey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: AddEditCustomerScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddEditCustomerHeader(
                    title: widget.isEditing ? 'Edit Customer' : 'Add Customer',
                    subtitle: widget.isEditing
                        ? null
                        : 'Monthly customer account',
                    onBack: () => context.pop(),
                    onDelete: widget.isEditing
                        ? () => _delete(repo, customer!.name)
                        : null,
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
                        children: [
                          AddEditCustomerSectionCard(
                            title: 'Customer details',
                            child: Column(
                              children: [
                                AddEditCustomerField(
                                  label: 'Full Name',
                                  controller: _nameController,
                                  hint: 'Enter customer name',
                                  icon: Icons.person_outline_rounded,
                                  textCapitalization: TextCapitalization.words,
                                  required: true,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Name is required'
                                      : null,
                                ),
                                AddEditCustomerField(
                                  label: 'Phone Number',
                                  controller: _phoneController,
                                  hint: '10-digit mobile number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  required: true,
                                  validator:
                                      InputValidators.requiredIndianMobile,
                                ),
                                AddEditCustomerField(
                                  label: 'Email',
                                  controller: _emailController,
                                  hint: 'email@example.com (optional)',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: validateEmailOptional,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                                AddEditCustomerField(
                                  label: 'Place',
                                  controller: _placeController,
                                  hint: 'Area, locality or city',
                                  icon: Icons.place_outlined,
                                  textCapitalization: TextCapitalization.words,
                                  required: true,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Place is required'
                                      : null,
                                ),
                                AddEditCustomerField(
                                  label: 'Address',
                                  controller: _addressController,
                                  hint: 'Door no, street, landmark',
                                  icon: Icons.home_outlined,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 3,
                                  required: true,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Address is required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AddEditCustomerSectionCard(
                            title: 'Driver language display',
                            subtitle:
                                'Optional. Driver app shows these names only when that language is selected.',
                            child: Column(
                              children: [
                                AddEditCustomerField(
                                  label: 'Telugu driver name',
                                  controller: _driverNameTeController,
                                  hint: 'Example: రమేష్ కుమార్',
                                  icon: Icons.translate_rounded,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                AddEditCustomerField(
                                  label: 'Hindi driver name',
                                  controller: _driverNameHiController,
                                  hint: 'Example: रमेश कुमार',
                                  icon: Icons.translate_rounded,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                AddEditCustomerField(
                                  label: 'Telugu driver address note',
                                  controller: _driverAddressNoteTeController,
                                  hint: 'Example: గుడి పక్కన, మెయిన్ రోడ్',
                                  icon: Icons.edit_location_alt_outlined,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 2,
                                ),
                                AddEditCustomerField(
                                  label: 'Hindi driver address note',
                                  controller: _driverAddressNoteHiController,
                                  hint: 'Example: मंदिर के पास, मेन रोड',
                                  icon: Icons.edit_location_alt_outlined,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AddEditCustomerSectionCard(
                            title: 'Delivery route',
                            child: CustomerRoutePickerField(
                              routes: repo.activeDeliveryRoutes,
                              selectedRouteId: _selectedRouteId,
                              onChanged: (id) =>
                                  setState(() => _selectedRouteId = id),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AddEditCustomerSectionCard(
                            title: 'Product rates',
                            subtitle:
                                'Tap to enable · set price for enabled items',
                            trailing: TextButton(
                              onPressed: () {
                                setState(() {
                                  _productPrices = repo
                                      .defaultCustomerPricing();
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    AddEditCustomerColors.primaryBtn,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Shop rates',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            child: CustomerPricingEditor(
                              repo: repo,
                              entries: _productPrices,
                              embedded: true,
                              onChanged: (list) =>
                                  setState(() => _productPrices = list),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AddEditCustomerSaveButton(
                    label: widget.isEditing ? 'Save changes' : 'Add customer',
                    onPressed: () => _save(repo),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
