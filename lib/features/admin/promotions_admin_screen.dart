import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/promotion.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

class PromotionsAdminScreen extends StatelessWidget {
  const PromotionsAdminScreen({super.key});

  Future<void> _openEditor(
    BuildContext context, {
    Promotion? promotion,
  }) async {
    final result = await showModalBottomSheet<_PromotionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromotionEditorSheet(existing: promotion),
    );
    if (result == null || !context.mounted) return;

    final repo = context.read<WaterPlantRepository>();
    if (promotion == null) {
      await repo.createPromotion(
        headline: result.headline,
        body: result.body,
        badge: result.badge,
        ctaLabel: result.ctaLabel,
        mediaUrl: result.mediaUrl,
        mediaType: result.mediaType,
        isActive: result.isActive,
      );
    } else {
      await repo.updatePromotion(
        id: promotion.id,
        headline: result.headline,
        body: result.body,
        badge: result.badge,
        ctaLabel: result.ctaLabel,
        mediaUrl: result.mediaUrl,
        mediaType: result.mediaType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final promos = repo.promotions.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          appBar: AppBar(
            title: const Text('Promotions'),
            actions: [
              IconButton(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add),
                tooltip: 'Add promotion',
              ),
            ],
          ),
          body: promos.isEmpty
              ? Center(
                  child: Text(
                    'No promotions yet.',
                    style: GoogleFonts.poppins(color: CustomersColors.labelGrey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: promos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PromotionTile(
                    promotion: promos[i],
                    onEdit: () => _openEditor(context, promotion: promos[i]),
                    onToggle: (v) =>
                        repo.setPromotionActive(id: promos[i].id, active: v),
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Delete promotion?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Text(
                            promos[i].headline,
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await repo.deletePromotion(promos[i].id);
                      }
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _PromotionTile extends StatelessWidget {
  const _PromotionTile({
    required this.promotion,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final Promotion promotion;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomersColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          promotion.headline,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          promotion.body.isEmpty ? '—' : promotion.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: promotion.isActive, onChanged: onToggle),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionDraft {
  const _PromotionDraft({
    required this.headline,
    required this.body,
    required this.mediaUrl,
    required this.mediaType,
    required this.badge,
    required this.ctaLabel,
    required this.isActive,
  });

  final String headline;
  final String body;
  final String? mediaUrl;
  final PromotionMediaType mediaType;
  final String? badge;
  final String? ctaLabel;
  final bool isActive;
}

class _PromotionEditorSheet extends StatefulWidget {
  const _PromotionEditorSheet({required this.existing});

  final Promotion? existing;

  @override
  State<_PromotionEditorSheet> createState() => _PromotionEditorSheetState();
}

class _PromotionEditorSheetState extends State<_PromotionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _headline;
  late final TextEditingController _body;
  late final TextEditingController _mediaUrl;
  late final TextEditingController _badge;
  late final TextEditingController _cta;
  bool _active = true;
  PromotionMediaType _mediaType = PromotionMediaType.image;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _headline = TextEditingController(text: p?.headline ?? '');
    _body = TextEditingController(text: p?.body ?? '');
    _mediaUrl = TextEditingController(text: p?.mediaUrl ?? '');
    _badge = TextEditingController(text: p?.badge ?? '');
    _cta = TextEditingController(text: p?.ctaLabel ?? 'Order now');
    _active = true;
  }

  @override
  void dispose() {
    _headline.dispose();
    _body.dispose();
    _mediaUrl.dispose();
    _badge.dispose();
    _cta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottom + 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.existing == null ? 'Add promotion' : 'Edit promotion',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _headline,
                    decoration: const InputDecoration(labelText: 'Headline'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Headline is required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _body,
                    decoration: const InputDecoration(labelText: 'Body'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _mediaUrl,
                    decoration: const InputDecoration(labelText: 'Media URL (optional)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PromotionMediaType>(
                          value: _mediaType,
                          items: const [
                            DropdownMenuItem(
                              value: PromotionMediaType.image,
                              child: Text('Image'),
                            ),
                            DropdownMenuItem(
                              value: PromotionMediaType.video,
                              child: Text('Video'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _mediaType = v ?? _mediaType),
                          decoration: const InputDecoration(labelText: 'Media type'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _badge,
                          decoration: const InputDecoration(labelText: 'Badge (optional)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _cta,
                    decoration: const InputDecoration(labelText: 'CTA label (optional)'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    title: const Text('Active'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            Navigator.pop(
                              context,
                              _PromotionDraft(
                                headline: _headline.text,
                                body: _body.text,
                                mediaUrl:
                                    _mediaUrl.text.trim().isEmpty ? null : _mediaUrl.text.trim(),
                                mediaType: _mediaType,
                                badge: _badge.text.trim().isEmpty ? null : _badge.text.trim(),
                                ctaLabel: _cta.text.trim().isEmpty ? null : _cta.text.trim(),
                                isActive: _active,
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

