import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/admin_dispatch_service.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/order_line_item.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/add_delivery_widgets.dart';

Future<bool?> showCreateDispatchSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _WalkInDispatchSheet(),
  );
}

/// Phone / walk-in caller — instant delivery (not in customer list).
class _WalkInDispatchSheet extends StatefulWidget {
  const _WalkInDispatchSheet();

  @override
  State<_WalkInDispatchSheet> createState() => _WalkInDispatchSheetState();
}

class _WalkInDispatchSheetState extends State<_WalkInDispatchSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _place = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _normal = ValueNotifier<int>(0);
  final _cool = ValueNotifier<int>(0);
  final Map<String, int> _channelQty = {};
  final Map<String, TextEditingController> _volumeQty = {};
  final Map<String, int> _bottleQty = {};
  bool _saving = false;

  TextEditingController _volumeController(String variantId) {
    return _volumeQty.putIfAbsent(variantId, TextEditingController.new);
  }

  int _volumeQuantity(String variantId) {
    final raw = _volumeQty[variantId]?.text.trim() ?? '';
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _place.dispose();
    _address.dispose();
    _note.dispose();
    _normal.dispose();
    _cool.dispose();
    for (final c in _volumeQty.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<OrderLineItem> _lineItems(WaterPlantRepository repo) {
    final items = <OrderLineItem>[];
    if (_normal.value > 0) {
      items.add(
        OrderLineItem.fromDeliveryType(
          type: DeliveryProductType.normalCan,
          quantity: _normal.value,
        ),
      );
    }
    if (_cool.value > 0) {
      items.add(
        OrderLineItem.fromDeliveryType(
          type: DeliveryProductType.coolCan,
          quantity: _cool.value,
        ),
      );
    }
    for (final type in repo.enabledChannelTypesForWalkIn()) {
      final qty = type.quantityIsVolumeLiters
          ? _volumeQuantity(type.variantId)
          : (_channelQty[type.variantId] ?? 0);
      if (qty > 0) {
        items.add(OrderLineItem.fromDeliveryType(type: type, quantity: qty));
      }
    }
    for (final product in repo.catalogProducts()) {
      for (final variant in product.variants) {
        final key = '${product.id}|${variant.id}';
        final qty = _bottleQty[key] ?? 0;
        if (qty > 0) {
          items.add(
            OrderLineItem(
              productId: product.id,
              variantId: variant.id,
              label: variant.label,
              quantity: qty,
            ),
          );
        }
      }
    }
    return items;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('Who called? Enter a name');
      return;
    }
    if (_phone.text.trim().isEmpty) {
      _snack('Enter their phone number');
      return;
    }
    if (_address.text.trim().isEmpty) {
      _snack('Where should we deliver?');
      return;
    }
    final repo = context.read<WaterPlantRepository>();
    final items = _lineItems(repo);
    if (items.isEmpty) {
      _snack('What did they ask for? Add at least one product');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AdminDispatchService>().createInstantDelivery(
        callerName: _name.text.trim(),
        callerPhone: _phone.text.trim(),
        callerAddress: _address.text.trim(),
        callerPlace: _place.text.trim(),
        lineItems: items,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        sendToDriver: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent to driver - they will deliver and collect payment',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _snack(_messageForError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.poppins())));
  }

  String _messageForError(Object error) {
    if (error is FirebaseFunctionsException) {
      if (error.code == 'internal') {
        final detail = (error.message ?? '').trim();
        if (detail.isNotEmpty && detail.toLowerCase() != 'internal') {
          return detail;
        }
        return 'Server error. Saving directly — if this repeats, deploy '
            'cloud functions (createWalkInDispatch) from the project folder.';
      }
      if (error.code == 'invalid-argument') {
        return error.message ?? 'Check name, 10-digit phone, and products.';
      }
      return error.message ?? error.code;
    }
    return error.toString().replaceFirst('ArgumentError: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final bottom = MediaQuery.paddingOf(context).bottom;
        final channelTypes = repo.enabledChannelTypesForWalkIn();
        final catalog = repo.catalogProducts();
        final items = _lineItems(repo);
        final total = repo.estimateWalkInDispatchTotal(items);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CustomersColors.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New quick order',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: CustomersColors.titleNavy,
                                ),
                              ),
                              Text(
                                'Phone order - one-time delivery',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: CustomersColors.labelGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _Field(
                          controller: _name,
                          label: 'Caller name',
                          hint: 'e.g. Ravi',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        _Field(
                          controller: _phone,
                          label: 'Phone',
                          hint: '10-digit mobile',
                          icon: Icons.phone_outlined,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        _Field(
                          controller: _place,
                          label: 'Area / landmark (optional)',
                          hint: 'e.g. Near temple',
                          icon: Icons.place_outlined,
                        ),
                        const SizedBox(height: 10),
                        _Field(
                          controller: _address,
                          label: 'Delivery address',
                          hint: 'Full address for driver',
                          icon: Icons.home_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Water for today',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CustomersColors.labelGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<int>(
                          valueListenable: _normal,
                          builder: (context, v, child) => AddDeliveryCanStepper(
                            label: 'Normal Can',
                            value: v,
                            onChanged: (n) => _normal.value = n,
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _cool,
                          builder: (context, v, child) => AddDeliveryCanStepper(
                            label: 'Cool Can',
                            value: v,
                            onChanged: (n) => _cool.value = n,
                          ),
                        ),
                        ...channelTypes.map((type) {
                          if (type.quantityIsVolumeLiters) {
                            return AddDeliveryVolumeQuantityField(
                              compact: true,
                              type: type,
                              controller: _volumeController(type.variantId),
                              onChanged: () => setState(() {}),
                            );
                          }
                          return AddDeliveryCanStepper(
                            compact: true,
                            label: type.title,
                            value: _channelQty[type.variantId] ?? 0,
                            onChanged: (n) =>
                                setState(() => _channelQty[type.variantId] = n),
                          );
                        }),
                        if (catalog.isNotEmpty)
                          AddDeliveryBottleCatalog(
                            products: catalog,
                            quantities: _bottleQty,
                            onChanged: (key, qty) =>
                                setState(() => _bottleQty[key] = qty),
                            unitPriceFor: (productId, variantId) {
                              for (final p in catalog) {
                                if (p.id != productId) continue;
                                for (final v in p.variants) {
                                  if (v.id == variantId) return v.price;
                                }
                              }
                              return 0;
                            },
                          ),
                        const SizedBox(height: 10),
                        _Field(
                          controller: _note,
                          label: 'Note for driver (optional)',
                          hint: 'Gate colour, timing…',
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        if (total > 0) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.payments_outlined,
                                  color: Color(0xFF16A34A),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Driver collects about ${CurrencyUtils.format(total)} at door',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CustomersColors.titleNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Not added to your customer list — one-time delivery only.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: CustomersColors.labelGrey,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: CustomersColors.addButton,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Send to driver',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ],
                    ),
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: CustomersColors.labelGrey),
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        hintStyle: GoogleFonts.poppins(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
