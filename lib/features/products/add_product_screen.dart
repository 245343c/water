import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/models/product_icon_choice.dart';
import 'package:sri_sai_ro_water/features/products/widgets/add_product_widgets.dart';

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
  final _picker = ImagePicker();

  String _iconKey = kProductIconChoices.first.key;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameController, _sizeController, _priceController, _stockController]) {
      c.addListener(_refreshPreview);
    }
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_nameController, _sizeController, _priceController, _stockController]) {
      c.removeListener(_refreshPreview);
    }
    _nameController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) setState(() => _imagePath = file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}.',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        imageSourcePath: _imagePath,
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
          body: AddEditCustomerScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AddProductHeader(onBack: () => context.pop()),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        AddProductLivePreview(
                          name: _nameController.text,
                          sizeLabel: _sizeController.text,
                          priceText: _priceController.text,
                          category: ProductCategory.bottle,
                          isCool: false,
                          iconKey: _iconKey,
                          imagePath: _imagePath,
                        ),
                        AddProductPhotoSection(
                          imagePath: _imagePath,
                          onPickCamera: () => _pickImage(ImageSource.camera),
                          onPickGallery: () => _pickImage(ImageSource.gallery),
                          onRemove: () => setState(() => _imagePath = null),
                        ),
                        AddProductIconSelector(
                          selectedKey: _iconKey,
                          onSelected: (key) => setState(() => _iconKey = key),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text(
                            'DETAILS',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AddProductColors.labelGrey,
                            ),
                          ),
                        ),
                        AddEditCustomerFormCard(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF2563EB),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Add the product here. Final customer price is assigned later in each customer profile.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: AddProductColors.labelGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            AddEditCustomerField(
                              label: 'Product name',
                              controller: _nameController,
                              hint: 'e.g. RO Water 1 L Bottle',
                              icon: Icons.inventory_2_outlined,
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Name is required' : null,
                            ),
                            AddProductQuantityField(
                              controller: _sizeController,
                              category: ProductCategory.bottle,
                              isCool: false,
                            ),
                            AddEditCustomerField(
                              label: 'Default rate',
                              controller: _priceController,
                              hint: 'Used only as starting rate for customers',
                              icon: Icons.currency_rupee,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              required: true,
                              validator: validateProductPrice,
                            ),
                            AddEditCustomerField(
                              label: 'Stock quantity (optional)',
                              controller: _stockController,
                              hint: 'e.g. 50',
                              icon: Icons.numbers_outlined,
                              keyboardType: TextInputType.number,
                              validator: validateStockQty,
                            ),
                            AddEditCustomerField(
                              label: 'Notes (optional)',
                              controller: _notesController,
                              hint: 'For your team',
                              icon: Icons.notes_outlined,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AddEditCustomerSaveButton(
                  label: _saving ? 'Saving...' : 'Save catalog product',
                  onPressed: _saving ? () {} : () => _save(repo),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
