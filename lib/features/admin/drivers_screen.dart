import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/driver.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/admin/widgets/drivers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  Future<void> _showAddDriver(BuildContext context) async {
    final result = await showModalBottomSheet<AddDriverResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddDriverSheet(),
    );
    if (result == null || !context.mounted) return;

    final repo = context.read<WaterPlantRepository>();
    final auth = context.read<AuthRepository>();

    final driver = await repo.addDriver(
      name: result.name,
      phone: result.phone,
      email: result.email,
    );

    final err = await auth.createDriverAccountAsync(
      driverId: driver.id,
      name: result.name,
      phone: result.phone,
      email: result.email,
      password: result.password,
    );

    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Driver created', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share these credentials with ${driver.name}:', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 12),
            _CredentialRow(label: 'Email', value: result.email),
            _CredentialRow(label: 'Password', value: result.password),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'Email: ${result.email}\nPassword: ${result.password}'),
              );
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: Text('Copy', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WaterPlantRepository, AuthRepository>(
      builder: (context, repo, auth, _) {
        final drivers = repo.drivers;

        return Scaffold(
          backgroundColor: DriversColors.screenBg,
          body: DriversScaffold(
            child: Column(
              children: [
                DriversHeader(
                  onBack: () => Navigator.pop(context),
                  onAdd: () => _showAddDriver(context),
                ),
                Expanded(
                  child: drivers.isEmpty
                      ? Center(
                          child: Text(
                            'No drivers yet',
                            style: GoogleFonts.poppins(color: DriversColors.labelGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: drivers.length,
                          itemBuilder: (_, i) => _DriverCard(
                            driver: drivers[i],
                            hasLogin: repo.driverHasLoginAccount(drivers[i].id),
                            accountEmail: drivers[i].hasLoginAccount
                                ? drivers[i].email
                                : null,
                            onToggleActive: (active) => repo.setDriverActive(drivers[i].id, active),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.hasLogin,
    required this.accountEmail,
    required this.onToggleActive,
  });

  final Driver driver;
  final bool hasLogin;
  final String? accountEmail;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: DriversColors.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: CustomersColors.addButton.withValues(alpha: 0.12),
                child: Text(
                  driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: CustomersColors.addButton,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DriversColors.titleNavy,
                      ),
                    ),
                    Text(
                      driver.phone,
                      style: GoogleFonts.poppins(fontSize: 12, color: DriversColors.labelGrey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: driver.active,
                activeTrackColor: DriversColors.accent,
                onChanged: onToggleActive,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasLogin && accountEmail != null)
            Row(
              children: [
                const Icon(Icons.login_rounded, size: 16, color: DriversColors.accent),
                const SizedBox(width: 6),
                Text(
                  accountEmail!,
                  style: GoogleFonts.poppins(fontSize: 12, color: DriversColors.labelGrey),
                ),
              ],
            )
          else
            Text(
              'No login — recreate from admin',
              style: GoogleFonts.poppins(fontSize: 12, color: DriversColors.warning),
            ),
          if (!driver.active)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Inactive — driver cannot sign in',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DriversColors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 13, color: DriversColors.titleNavy),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
