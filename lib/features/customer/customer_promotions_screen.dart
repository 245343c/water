import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/promotion.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerPromotionsScreen extends StatelessWidget {
  const CustomerPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final linkedShopIds = user == null
        ? <String>{}
        : repo
            .linkedShopsForAppUser(user.id, phone: user.phone)
            .map((s) => s.id)
            .toSet();
    final promos = repo.promotions
        .where((promo) => linkedShopIds.contains(promo.shopId))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PromoBanner(),
            Expanded(
              child: promos.isEmpty
                  ? const CustomerEmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'No promotions yet',
                      message:
                          'Offers from your linked water plant will appear here.',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: customerBottomInset(context, extra: 12),
                      ),
                      itemCount: promos.length,
                      itemBuilder: (context, i) => _PromoCard(
                        promo: promos[i],
                        onTap: () =>
                            context.push('/customer/shop/${promos[i].shopId}'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: CustomerColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promotions',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Offers & deals from shops near you',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.onTap});

  final Promotion promo;
  final VoidCallback onTap;

  static const _gradients = [
    [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    [Color(0xFF7C3AED), Color(0xFFA855F7)],
    [Color(0xFF0D9488), Color(0xFF2DD4BF)],
    [Color(0xFFEA580C), Color(0xFFFB923C)],
    [Color(0xFF0F172A), Color(0xFF1E40AF)],
  ];

  List<Color> _gradient(String id) {
    final i = id.codeUnits.fold(0, (s, c) => s + c) % _gradients.length;
    return _gradients[i];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient(promo.id);
    final isVideo = promo.mediaType == PromotionMediaType.video;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Media / illustrated hero ─────────────────────────────────
              SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _PromoBgPainter(colors),
                      ),
                    ),
                    // Illustrated water-themed decoration
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(
                          isVideo ? Icons.play_circle_fill_rounded : Icons.water_drop_rounded,
                          size: 160,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Content overlay
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (promo.badge != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    promo.badge!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (isVideo)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 22),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            promo.headline,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Card body ────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors[0].withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.storefront_rounded,
                              size: 16, color: colors[0]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            promo.shopName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CustomerColors.titleNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      promo.body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: CustomerColors.labelGrey,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors[0],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          promo.ctaLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
  }
}

class _PromoBgPainter extends CustomPainter {
  const _PromoBgPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (var i = 0; i < 4; i++) {
      final r = size.width * (0.2 + i * 0.12);
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * (0.1 + i * 0.2)),
        r,
        paint,
      );
    }
    // Wave
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, size.height * 0.7);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y = size.height * 0.7 + math.sin((x / size.width) * math.pi * 3) * 14;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
