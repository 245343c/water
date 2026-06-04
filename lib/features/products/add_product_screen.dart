import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/models/product_icon_choice.dart';
import 'package:sri_sai_ro_water/features/products/widgets/add_product_widgets.dart';
import 'package:sri_sai_ro_water/features/products/widgets/products_screen_widgets.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController(text: '1 L');
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _notesController = TextEditingController();

  String _iconKey = kProductIconChoices.first.key;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(WaterPlantRepository repo) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final price = double.parse(_priceController.text.replaceAll(',', '').trim());
      final stockNote = _stockController.text.trim();
      final notes = [
        if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
        if (stockNote.isNotEmpty) 'Stock: $stockNote',
      ].join(' · ');

      await repo.addProduct(
        name: _nameController.text,
        description: notes,
        category: ProductCategory.bottle,
        variantLabel: _sizeController.text,
        price: price,
        isCool: false,
        iconKey: _iconKey,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product saved', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: ProductsScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddProductHeader(onBack: () => context.pop()),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
                        children: [
                          AddProductSectionCard(
                            title: 'Catalog product',
                            child: Column(
                              children: [
                                AddProductIconSelector(
                                  selectedKey: _iconKey,
                                  onSelected: (key) =>
                                      setState(() => _iconKey = key),
                                ),
                                const SizedBox(height: 8),
                                AddEditCustomerField(
                                  label: 'Product name',
                                  controller: _nameController,
                                  hint: 'e.g. RO Water 1 L Bottle',
                                  icon: Icons.inventory_2_outlined,
                                  textCapitalization: TextCapitalization.words,
                                  required: true,
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'Name is required'
                                      : null,
                                ),
                                AddProductQuantityField(
                                  controller: _sizeController,
                                  category: ProductCategory.bottle,
                                  isCool: false,
                                ),
                                AddEditCustomerField(
                                  label: 'Shop default rate',
                                  controller: _priceController,
                                  hint: 'Per customer price set later',
                                  icon: Icons.currency_rupee,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  required: true,
                                  validator: validateProductPrice,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AddProductAdvancedSection(
                            stockController: _stockController,
                            notesController: _notesController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AddEditCustomerSaveButton(
                    label: _saving ? 'Saving...' : 'Save product',
                    onPressed: _saving ? () {} : () => _save(repo),
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
