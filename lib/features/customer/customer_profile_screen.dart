import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final profile = user != null ? repo.customerProfileByUserId(user.id) : null;
    final isContract = user != null &&
        repo.isMonthlyContractAppUser(user.id, phone: user.phone);
    final crm = user != null ? repo.linkedCrmCustomerForAppUser(user.id) : null;
    final shopCount = user != null ? repo.shopBillingsForAppUser(user.id).length : 0;
    final displayName = crm?.name ?? profile?.name ?? user?.ownerName ?? 'Customer';
    final hasDelivery = profile != null && profile.onboardingComplete;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return CustomerScaffold(
      child: Column(
        children: [
          _ProfileHero(
            name: displayName,
            phone: user?.phone ?? '',
            initial: initial,
            isContract: isContract,
            shopCount: shopCount,
          ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: customerBottomInset(context, extra: 16)),
                children: [
                  CustomerSectionTitle(title: 'Account'),
                  _ProfileTile(
                    icon: Icons.phone_android_rounded,
                    label: 'Mobile',
                    value: user?.phone ?? '—',
                    iconColor: CustomerColors.accent,
                  ),
                  if (isContract && shopCount > 0)
                    _ProfileTile(
                      icon: Icons.storefront_rounded,
                      label: 'Linked shops',
                      value: '$shopCount shops with monthly billing',
                      iconColor: CustomerColors.contractPurple,
                    ),
                  CustomerSectionTitle(title: 'Delivery'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 0,
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.customerOnboarding),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: CustomerColors.cardBorder),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                CustomerColors.accent.withValues(alpha: 0.06),
                                Colors.white,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CustomerColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: CustomerColors.accent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasDelivery ? 'Deliver to' : 'Set delivery address',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: CustomerColors.labelGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasDelivery
                                          ? profile.address
                                          : 'Add home address & map pin for orders',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: CustomerColors.titleNavy,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: CustomerColors.accent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomerSectionTitle(title: 'Session'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomerPrimaryButton(
                      label: 'Sign out',
                      icon: Icons.logout_rounded,
                      onPressed: () {
                        auth.logout();
                        context.go(AppRoutes.welcome);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, auth),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      label: Text(
                        'Delete account',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Text(
                      'Deleting your account removes your profile from this device. '
                      'Required by Google Play & App Store for apps with sign-in.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: CustomerColors.labelGrey,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AuthRepository auth) {
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete account?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'This permanently deletes your app account and saved delivery details. '
          'Monthly billing with shops is managed by each shop separately.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: CustomerColors.labelGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              auth.deleteCustomerAccount(userId);
              context.go(AppRoutes.welcome);
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.phone,
    required this.initial,
    required this.isContract,
    required this.shopCount,
  });

  final String name;
  final String phone;
  final String initial;
  final bool isContract;
  final int shopCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: CustomerColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        28,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: CustomerColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          if (isContract) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shopCount > 1
                    ? 'Bulk · $shopCount shop accounts'
                    : 'Bulk / monthly account',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: CustomerColors.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CustomerColors.labelGrey,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CustomerColors.titleNavy,
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
