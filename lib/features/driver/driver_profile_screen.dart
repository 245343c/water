import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_customer_detail_widgets.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final driverId = user?.driverId;
    final driver = driverId != null ? repo.driverById(driverId) : null;
    final assignedShop = repo.shopForDriver(driverId);
    final customerCount = repo.customersForDriver(driverId).length;
    final name = driver?.name ?? user?.ownerName ?? 'Driver';
    final phone = driver?.phone ?? user?.phone ?? '';
    final email = driver?.email ?? user?.email ?? '';
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'D';
    final active = driver?.active ?? true;

    return Scaffold(
      backgroundColor: DriverColors.contentBg,
      body: Column(
        children: [
          _DriverProfileBar(
            name: name,
            phone: phone,
            initial: initial,
            active: active,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                DriverContentCard(
                  child: Column(
                    children: [
                      if (email.isNotEmpty)
                        _ProfileInfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: email,
                        ),
                      if (email.isNotEmpty) const _ProfileDivider(),
                      _ProfileInfoRow(
                        icon: Icons.storefront_rounded,
                        label: 'Water plant',
                        value: assignedShop?.name ?? 'Not assigned yet',
                      ),
                      const _ProfileDivider(),
                      _ProfileInfoRow(
                        icon: Icons.groups_rounded,
                        label: 'Customers',
                        value: customerCount == 0
                            ? 'None assigned'
                            : '$customerCount on your route',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                  child: Text(
                    'Contact and plant details are set by your admin.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: DriverColors.labelGrey,
                      height: 1.4,
                    ),
                  ),
                ),
                _SignOutButton(
                  onTap: () {
                    auth.logout();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverProfileBar extends StatelessWidget {
  const _DriverProfileBar({
    required this.name,
    required this.phone,
    required this.initial,
    required this.active,
  });

  final String name;
  final String phone;
  final String initial;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: DriverColors.headerStart,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 14,
        16,
        16,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DriverColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: DriverColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DriverColors.labelGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DriverColors.titleNavy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: DriverColors.cardBorder),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Text(
                'Sign out',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
