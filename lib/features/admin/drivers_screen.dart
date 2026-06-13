import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/driver.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/core/services/subscription_service.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';
import 'package:sri_sai_ro_water/features/admin/widgets/drivers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<WaterPlantRepository>()
          .loadDriversForCurrentAdminFromFirestore();
    });
  }

  Future<void> _showAddDriver(BuildContext context) async {
    final sub = context.read<SubscriptionService>();
    final shop = sub.currentShop;
    if (shop != null && !shop.canAccessAdminFeatures) {
      context.push(AppRoutes.subscription);
      return;
    }
    final limitMsg = sub.driverLimitMessage();
    if (limitMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(limitMsg, style: GoogleFonts.poppins(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push(AppRoutes.subscription);
      return;
    }

    final result = await showModalBottomSheet<AddDriverResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddDriverSheet(),
    );
    if (result == null || !context.mounted) return;

    final repo = context.read<WaterPlantRepository>();
    Driver driver;
    try {
      driver = await repo.createDriverAccountInFirebase(
        name: result.name,
        phone: result.phone,
        email: result.email,
        password: result.password,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver not created. ${_messageForError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;

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
            _CredentialRow(label: 'Mobile', value: result.phone),
            _CredentialRow(label: 'Password', value: result.password),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'Mobile: ${result.phone}\nPassword: ${result.password}'),
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

  Future<void> _showEditDriver(BuildContext context, Driver driver) async {
    final result = await showModalBottomSheet<EditDriverResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditDriverSheet(
        initialName: driver.name,
        initialPhone: driver.phone,
        initialEmail: driver.email,
      ),
    );
    if (result == null || !context.mounted) return;

    final repo = context.read<WaterPlantRepository>();
    try {
      await repo.updateDriverAccountInFirebase(
        driverId: driver.id,
        name: result.name,
        phone: result.phone,
        email: result.email,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver not updated. ${_messageForError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Driver updated', style: GoogleFonts.poppins())),
    );
  }

  Future<void> _deleteDriver(BuildContext context, Driver driver) async {
    final repo = context.read<WaterPlantRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete driver?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This removes ${driver.name} and their login access.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await repo.deleteDriverAccountInFirebase(driver.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver not deleted. ${_messageForError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Driver deleted', style: GoogleFonts.poppins())),
    );
  }

  Future<void> _resetDriverPassword(BuildContext context, Driver driver) async {
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ResetDriverPasswordDialog(),
    );
    if (password == null || !context.mounted) return;

    final repo = context.read<WaterPlantRepository>();
    try {
      await repo.resetDriverPasswordInFirebase(
        driverId: driver.id,
        password: password,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password not reset. ${_messageForError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Password reset',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share these updated credentials with ${driver.name}:',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            _CredentialRow(label: 'Mobile', value: driver.phone),
            _CredentialRow(label: 'Password', value: password),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: 'Mobile: ${driver.phone}\nPassword: $password',
                ),
              );
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: Text(
              'Copy',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  String _messageForError(Object error) {
    if (error is FirebaseFunctionsException) {
      return error.message ?? error.code;
    }
    final text = error.toString();
    final marker = 'message: ';
    final index = text.indexOf(marker);
    if (index >= 0) return text.substring(index + marker.length);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final drivers = repo.drivers;

        return Scaffold(
          backgroundColor: DriversColors.screenBg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDriver(context),
            backgroundColor: CustomersColors.addButton,
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: Text(
              'Add driver',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          body: DriversScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  DriversHeader(
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: drivers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 48,
                                    color: DriversColors.labelGrey.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No drivers yet',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: DriversColors.titleNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap Add driver to create staff login',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: DriversColors.labelGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 88),
                            itemCount: drivers.length,
                            itemBuilder: (_, i) => _DriverCard(
                            driver: drivers[i],
                            hasLogin: true,
                            accountEmail: drivers[i].phone,
                            onToggleActive: (active) async {
                              try {
                                await repo.setDriverActiveInFirebase(
                                  drivers[i].id,
                                  active,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Driver status not changed. ${_messageForError(e)}',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            onEdit: () => _showEditDriver(context, drivers[i]),
                            onResetPassword: () =>
                                _resetDriverPassword(context, drivers[i]),
                            onDelete: () => _deleteDriver(context, drivers[i]),
                          ),
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

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.hasLogin,
    required this.accountEmail,
    required this.onToggleActive,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDelete,
  });

  final Driver driver;
  final bool hasLogin;
  final String? accountEmail;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              PopupMenuButton<String>(
                tooltip: 'Driver actions',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'reset') onResetPassword();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Edit', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        const Icon(Icons.key_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Reset password', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

class _ResetDriverPasswordDialog extends StatefulWidget {
  const _ResetDriverPasswordDialog();

  @override
  State<_ResetDriverPasswordDialog> createState() =>
      _ResetDriverPasswordDialogState();
}

class _ResetDriverPasswordDialogState
    extends State<_ResetDriverPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Reset password',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _password,
          obscureText: _obscure,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            if ((value ?? '').length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_reset_rounded),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text('Reset', style: GoogleFonts.poppins()),
        ),
      ],
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
