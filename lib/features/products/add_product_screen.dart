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
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  ProductCategory _category = ProductCategory.bottle;
  bool _isCoolCan = false;
  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(ProductCategory category) {
    setState(() {
      _category = category;
      if (category == ProductCategory.bottle) {
        if (_sizeController.text == 'Normal Can' || _sizeController.text == 'Cool Can') {
          _sizeController.text = '1 L';
        }
      } else {
        _sizeController.text = _isCoolCan ? 'Cool Can' : 'Normal Can';
      }
    });
  }

  void _onCanTypeChanged(bool isCool) {
    setState(() {
      _isCoolCan = isCool;
      _sizeController.text = isCool ? 'Cool Can' : 'Normal Can';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _imagePath = file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}. Check permissions.',
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
      await repo.addProduct(
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
                        AddProductPhotoSection(
                          imagePath: _imagePath,
                          onPickCamera: () => _pickImage(ImageSource.camera),
                          onPickGallery: () => _pickImage(ImageSource.gallery),
                          onRemove: () => setState(() => _imagePath = null),
                        ),
                        AddProductCategorySelector(
                          selected: _category,
                          onSelected: _onCategoryChanged,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text(
                            'Product details',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AddProductColors.labelGrey,
                            ),
                          ),
                        ),
                        AddEditCustomerFormCard(
                          children: [
                            AddEditCustomerField(
                              label: 'Product Name',
                              controller: _nameController,
                              hint: 'e.g. RO Water 2 L Bottle',
                              icon: Icons.inventory_2_outlined,
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'Product name is required' : null,
                            ),
                            if (_category == ProductCategory.can) ...[
                              const SizedBox(height: 4),
                              AddProductCanTypeSelector(
                                isCool: _isCoolCan,
                                onChanged: _onCanTypeChanged,
                              ),
                              const SizedBox(height: 8),
                            ] else
                              AddEditCustomerField(
                                label: 'Bottle Size',
                                controller: _sizeController,
                                hint: 'e.g. 1/2 L, 1 L, 2 L, 25 L',
                                icon: Icons.straighten_outlined,
                                required: true,
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Size is required' : null,
                              ),
                            AddEditCustomerField(
                              label: 'Price (₹)',
                              controller: _priceController,
                              hint: 'Enter selling price',
                              icon: Icons.currency_rupee,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              required: true,
                              validator: validateProductPrice,
                            ),
                            AddEditCustomerField(
                              label: 'Notes (optional)',
                              controller: _notesController,
                              hint: 'Short description for your team',
                              icon: Icons.notes_outlined,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AddEditCustomerSaveButton(
                  label: _saving ? 'Saving…' : 'Save Product',
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
