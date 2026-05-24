import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/widgets/add_product_widgets.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.productId});

  final String productId;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  ProductCategory _category = ProductCategory.bottle;
  bool _isCoolCan = false;
  String? _imagePath;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameController, _sizeController, _priceController]) {
      c.addListener(_refreshPreview);
    }
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_nameController, _sizeController, _priceController]) {
      c.removeListener(_refreshPreview);
    }
    _nameController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadProduct(WaterPlantRepository repo) {
    if (_loaded) return;
    final product = repo.productById(widget.productId);
    if (product == null) return;
    _loaded = true;
    _nameController.text = product.name;
    _category = product.category;
    if (product.variants.isNotEmpty) {
      final v = product.variants.first;
      _sizeController.text = v.label;
      _priceController.text = v.price.toStringAsFixed(0);
      _isCoolCan = v.isCool;
    }
    _notesController.text = product.description;
    _imagePath = product.localImagePath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save(WaterPlantRepository repo) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final price = double.parse(_priceController.text.replaceAll(',', '').trim());
      await repo.updateProduct(
        id: widget.productId,
        name: _nameController.text,
        description: _notesController.text,
        category: _category,
        variantLabel: _sizeController.text,
        price: price,
        isCool: _category == ProductCategory.can && _isCoolCan,
        imageSourcePath: _imagePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product updated', style: GoogleFonts.poppins()),
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
        _loadProduct(repo);
        final product = repo.productById(widget.productId);
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit product')),
            body: const Center(child: Text('Product not found')),
          );
        }

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: AddEditCustomerScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AddEditCustomerHeader(title: 'Edit Product', onBack: () => context.pop()),
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
                          category: _category,
                          isCool: _isCoolCan,
                          imagePath: _imagePath,
                        ),
                        AddProductPhotoSection(
                          imagePath: _imagePath,
                          onPickCamera: () => _pickImage(ImageSource.camera),
                          onPickGallery: () => _pickImage(ImageSource.gallery),
                          onRemove: () => setState(() => _imagePath = null),
                        ),
                        AddProductCategorySelector(
                          selected: _category,
                          onSelected: (c) => setState(() => _category = c),
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
                            AddEditCustomerField(
                              label: 'Product name',
                              controller: _nameController,
                              icon: Icons.inventory_2_outlined,
                              required: true,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Name is required' : null,
                            ),
                            if (_category == ProductCategory.can)
                              AddProductCanTypeSelector(
                                isCool: _isCoolCan,
                                onChanged: (v) => setState(() {
                                  _isCoolCan = v;
                                  _sizeController.text = v ? 'Cool Can' : 'Normal Can';
                                }),
                              ),
                            AddEditCustomerField(
                              label: 'Default rate',
                              controller: _priceController,
                              icon: Icons.currency_rupee,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              required: true,
                              validator: validateProductPrice,
                            ),
                            AddEditCustomerField(
                              label: 'Description',
                              controller: _notesController,
                              icon: Icons.notes_outlined,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AddEditCustomerSaveButton(
                  label: _saving ? 'Saving…' : 'Save changes',
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
