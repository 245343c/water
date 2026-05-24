import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/customer_delete_dialog.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_pricing_widgets.dart';
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
  bool _loaded = false;
  bool _pricingReady = false;
  String? _routeId;
  List<CustomerProductPrice> _productPrices = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _placeController = TextEditingController();
    _addressController = TextEditingController();
  }

  void _loadCustomer(Customer? customer, WaterPlantRepository repo) {
    if (_loaded) return;
    if (customer != null) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
      _placeController.text = customer.place;
      _addressController.text = customer.address;
      _routeId = customer.routeId;
      _productPrices = customer.productPrices.isEmpty
          ? repo.defaultCustomerPricing()
          : List<CustomerProductPrice>.from(customer.productPrices);
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
    super.dispose();
  }

  Future<void> _save(WaterPlantRepository repo) async {
    if (!_formKey.currentState!.validate()) return;

    final data = (
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      place: _placeController.text.trim(),
      address: _addressController.text.trim(),
      routeId: _routeId,
    );

    try {
      if (widget.isEditing) {
        final existing = repo.customerById(widget.customerId!);
        if (existing != null) {
          await repo.updateCustomer(
            existing.copyWith(
              name: data.name,
              phone: data.phone,
              email: data.email,
              place: data.place,
              routeId: data.routeId,
              clearRoute: data.routeId == null,
              address: data.address,
              productPrices: _productPrices,
            ),
          );
        }
      } else {
        await repo.addCustomer(
          name: data.name,
          phone: data.phone,
          email: data.email,
          place: data.place,
          routeId: data.routeId,
          address: data.address,
          productPrices: _productPrices,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    await repo.deleteCustomer(widget.customerId!);
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
              child: Column(
                children: [
                  AddEditCustomerHeader(
                    title: 'Edit Customer',
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
          );
        }

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: AddEditCustomerScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AddEditCustomerHeader(
                  title: widget.isEditing ? 'Edit Customer' : 'Add Customer',
                  onBack: () => context.pop(),
                  onDelete: widget.isEditing
                      ? () => _delete(repo, customer!.name)
                      : null,
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        AddEditCustomerFormCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Text(
                                'Customer details',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AddEditCustomerColors.labelGrey,
                                ),
                              ),
                            ),
                            AddEditCustomerField(
                              label: 'Full Name',
                              controller: _nameController,
                              hint: 'Enter customer name',
                              icon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: (v) => v == null || v.trim().isEmpty
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
                              validator: (v) {
                                final digits =
                                    v?.replaceAll(RegExp(r'\D'), '') ?? '';
                                if (digits.length < 10) {
                                  return 'Valid phone required';
                                }
                                return null;
                              },
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _phoneController,
                              builder: (context, value, _) {
                                return CustomerAppAccessInfoCard(
                                  phone: value.text,
                                  shopName: repo.settings.businessName,
                                  isEditing: widget.isEditing,
                                );
                              },
                            ),
                            AddEditCustomerField(
                              label: 'Email',
                              controller: _emailController,
                              hint: 'email@example.com (optional)',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: validateEmailOptional,
                            ),
                            AddEditCustomerField(
                              label: 'Place / Locality',
                              controller: _placeController,
                              hint: 'Example: Gandhi Nagar, Main Road',
                              icon: Icons.place_outlined,
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Place is required'
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: DropdownButtonFormField<String?>(
                                value: _routeId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Delivery Route',
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AddEditCustomerColors.titleNavy,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.route_rounded,
                                    size: 20,
                                    color: AddEditCustomerColors.labelGrey,
                                  ),
                                  filled: true,
                                  fillColor: AddEditCustomerColors.fieldFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AddEditCustomerColors.fieldBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AddEditCustomerColors.fieldBorder,
                                    ),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      'Unassigned',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  for (final route in repo.deliveryRoutes)
                                    DropdownMenuItem<String?>(
                                      value: route.id,
                                      child: Text(
                                        route.name,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _routeId = value),
                              ),
                            ),
                            AddEditCustomerField(
                              label: 'Address',
                              controller: _addressController,
                              hint: 'Door no, street, landmark',
                              icon: Icons.home_outlined,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 3,
                              required: true,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Address is required'
                                  : null,
                            ),
                            const AddEditCustomerFormDivider(),
                            AddEditCustomerSubsectionHeader(
                              title: 'Product rates',
                              subtitle:
                                  'Customer-specific rates shown in admin, driver, and customer app',
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
                                    horizontal: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Shop rates',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            CustomerPricingEditor(
                              repo: repo,
                              entries: _productPrices,
                              embedded: true,
                              onChanged: (list) =>
                                  setState(() => _productPrices = list),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AddEditCustomerSaveButton(
                  label: widget.isEditing ? 'Save Changes' : 'Add Customer',
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
