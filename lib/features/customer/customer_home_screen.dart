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
          linkedShopCount: shops.length,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _LinkedAccountCard(
            shopCount: shops.length,
            customerName: crm?.name ?? user?.ownerName ?? 'Customer',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Text(
            shops.length == 1 ? 'YOUR WATER PLANT' : 'LINKED WATER PLANTS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: CustomerColors.labelGrey,
              letterSpacing: 0.6,
            ),
          ),
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
    required this.linkedShopCount,
  });

  final String name;
  final String greeting;
  final int linkedShopCount;

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    linkedShopCount == 0
                        ? 'Only admin-added customers can order'
                        : linkedShopCount == 1
                        ? 'You can order from your linked plant'
                        : 'You can order from your linked plants',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _LinkedAccountCard extends StatelessWidget {
  const _LinkedAccountCard({
    required this.shopCount,
    required this.customerName,
  });

  final int shopCount;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CustomerColors.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CustomerColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: CustomerColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CustomerColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shopCount == 0
                      ? 'No linked water plant'
                      : '$shopCount linked water plant${shopCount == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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
          padding: const EdgeInsets.all(16),
          decoration: CustomerColors.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: CustomerColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: CustomerColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ShopActionButton(
                            label: 'Details',
                            icon: Icons.info_outline_rounded,
                            outlined: true,
                            onTap: () => context.go(
                              '/customer/account?shopId=${shop.id}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ShopActionButton(
                            label: 'Order Water',
                            icon: Icons.water_drop_outlined,
                            onTap: () =>
                                context.push('/customer/shop/${shop.id}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: CustomerColors.labelGrey,
              ),
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
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CustomerColors.accent),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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
