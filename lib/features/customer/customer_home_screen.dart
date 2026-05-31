import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final userId = user?.id;
    final crm = userId != null
        ? repo.linkedCrmCustomerForAppUser(userId)
        : null;
    final profile = userId != null ? repo.customerProfileByUserId(userId) : null;
    final firstName = (crm?.name ?? user?.ownerName ?? 'Guest')
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    final shops = userId == null
        ? <Shop>[]
        : repo.linkedShopsForAppUser(userId, phone: user?.phone);
    final greeting = _greetingFor(DateTime.now());

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _CustomerHomeHeader(
          name: firstName,
          greeting: greeting,
          photoBytes: profile?.photoBytes,
        ),
        _HomeSectionHeading(
          title: shops.length == 1 ? 'Your water plant' : 'Linked water plants',
          subtitle: shops.length == 1
              ? 'Your monthly account and quick ordering'
              : 'Choose a plant to view your monthly account',
        ),
        if (shops.isEmpty)
          CustomerEmptyState(
            icon: Icons.storefront_rounded,
            title: userId == null
                ? 'Sign in required'
                : 'No water plant linked yet',
            message: userId == null
                ? 'Please sign in to view your water plant.'
                : 'Ask your RO plant owner to add this mobile number in the customer list.',
          )
        else
          ...shops.map(
            (shop) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _ShopCard(shop: shop),
            ),
          ),
        SizedBox(height: customerBottomInset(context, extra: 20)),
      ],
    );
  }

  String _greetingFor(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _CustomerHomeHeader extends StatelessWidget {
  const _CustomerHomeHeader({
    required this.name,
    required this.greeting,
    required this.photoBytes,
  });

  final String name;
  final String greeting;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: CustomerColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF7DD3FC),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'HOME DELIVERY',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your fresh water account is ready',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: photoBytes == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Image.memory(
                        photoBytes!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeSectionHeading extends StatelessWidget {
  const _HomeSectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: CustomerColors.accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CustomerColors.titleNavy,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: CustomerColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/customer/account?shopId=${shop.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: CustomerColors.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CustomerColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: CustomerColors.accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.titleNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: CustomerColors.labelGrey,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _ShopActionButton(
                      label: 'Order water',
                      icon: Icons.water_drop_outlined,
                      onTap: () => context.push('/customer/shop/${shop.id}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopActionButton extends StatelessWidget {
  const _ShopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? CustomerColors.accent : Colors.white;
    return Material(
      color: outlined ? Colors.white : CustomerColors.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CustomerColors.accent),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
