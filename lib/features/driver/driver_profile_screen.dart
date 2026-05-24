import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
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
    final today = DateTime.now();
    final deliveries = repo.deliveriesOnDateForDriver(today, driverId);
    final cans = repo.cansDeliveredOnDateForDriver(today, driverId);
    final customers = repo.customersForDriver(driverId).length;
    final name = driver?.name ?? user?.ownerName ?? 'Driver';
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'D';

    return Scaffold(
      backgroundColor: DriverColors.screenBg,
      body: DriverScaffold(
        child: Column(
          children: [
            _DriverProfileHeader(
              name: name,
              email: driver?.email ?? user?.email ?? '',
              initial: initial,
              active: driver?.active ?? true,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  MediaQuery.paddingOf(context).bottom + 18,
                ),
                children: [
                  _DriverDetailsPanel(
                    phone: driver?.phone ?? user?.phone ?? '-',
                    email: driver?.email ?? user?.email ?? '-',
                    plant: assignedShop?.name ?? 'No plant assigned',
                    customers: '$customers assigned customers',
                  ),
                  const SizedBox(height: 14),
                  _TodaySummary(
                    deliveries: deliveries.length,
                    cans: cans,
                  ),
                  const SizedBox(height: 14),
                  _AvailabilityCard(
                    active: driver?.active ?? true,
                    onChanged: (v) => repo.setMyDriverAvailability(v),
                  ),
                  const SizedBox(height: 14),
                  _ReadOnlyNotice(),
                  const SizedBox(height: 18),
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
      ),
    );
  }
}

class _DriverProfileHeader extends StatelessWidget {
  const _DriverProfileHeader({
    required this.name,
    required this.email,
    required this.initial,
    required this.active,
  });

  final String name;
  final String email;
  final String initial;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: DriverColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 18,
        20,
        22,
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
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
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isEmpty ? 'Delivery staff' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    active ? 'Active driver' : 'Inactive driver',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _DriverDetailsPanel extends StatelessWidget {
  const _DriverDetailsPanel({
    required this.phone,
    required this.email,
    required this.plant,
    required this.customers,
  });

  final String phone;
  final String email;
  final String plant;
  final String customers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: _profileCardDecoration,
      child: Column(
        children: [
          _ProfileRow(
            icon: Icons.phone_iphone_rounded,
            label: 'Mobile number',
            value: phone.isEmpty ? '-' : phone,
          ),
          const _InsetDivider(),
          _ProfileRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: email.isEmpty ? '-' : email,
          ),
          const _InsetDivider(),
          _ProfileRow(
            icon: Icons.storefront_rounded,
            label: 'Assigned plant',
            value: plant,
          ),
          const _InsetDivider(),
          _ProfileRow(
            icon: Icons.groups_rounded,
            label: 'Customer access',
            value: customers,
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.deliveries,
    required this.cans,
  });

  final int deliveries;
  final int cans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _profileCardDecoration,
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.local_shipping_rounded,
              label: 'Deliveries',
              value: '$deliveries',
            ),
          ),
          Container(width: 1, height: 46, color: DriverColors.cardBorder),
          Expanded(
            child: _SummaryItem(
              icon: Icons.water_drop_rounded,
              label: 'Cans today',
              value: '$cans',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: DriverColors.accent, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: DriverColors.titleNavy,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DriverColors.labelGrey,
          ),
        ),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.active,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: DriverColors.cardDecoration,
      child: Row(
        children: [
          const Icon(Icons.toggle_on_outlined, color: DriverColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Available for deliveries',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: DriverColors.titleNavy,
              ),
            ),
          ),
          Switch(value: active, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DriverColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DriverColors.accent.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: DriverColors.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Profile details are managed by the admin.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DriverColors.titleNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DriverColors.accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DriverColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DriverColors.labelGrey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DriverColors.titleNavy,
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

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: 66),
        child: Divider(height: 1, color: DriverColors.cardBorder),
      );
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Text(
                'Sign out',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
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

BoxDecoration get _profileCardDecoration => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: DriverColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
