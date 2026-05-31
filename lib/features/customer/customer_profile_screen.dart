import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer_app_profile.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/features/more/widgets/shop_location_picker.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  String? _loadedUserId;
  double? _lat;
  double? _lng;
  String _place = '';
  Uint8List? _photoBytes;
  bool _saving = false;
  bool _editing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();
    final user = auth.currentUser;
    if (user == null || _loadedUserId == user.id) return;

    final profile = repo.customerProfileByUserId(user.id);
    final crm = repo.linkedCrmCustomerForAppUser(user.id);
    _loadedUserId = user.id;
    _nameController.text =
        profile?.name ?? crm?.name ?? user.ownerName.replaceAll('Customer', '');
    _addressController.text = profile?.address ?? crm?.address ?? '';
    _emailController.text = profile?.email ?? '';
    _lat = profile?.latitude;
    _lng = profile?.longitude;
    _place = profile?.place ?? '';
    _photoBytes = profile?.photoBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set your delivery location on the map'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();
    final user = auth.currentUser;
    if (user == null) return;

    final existing = repo.customerProfileByUserId(user.id);
    final profile = CustomerAppProfile(
      userId: user.id,
      name: _capitalizeWords(_nameController.text.trim()),
      phone: user.phone,
      address: _capitalizeSentence(_addressController.text.trim()),
      latitude: _lat!,
      longitude: _lng!,
      email: _emailController.text.trim(),
      place: _place,
      photoBytes: _photoBytes,
      linkedCrmCustomerId: existing?.linkedCrmCustomerId,
      onboardingComplete: true,
    );

    setState(() => _saving = true);
    await repo.saveCustomerProfileToFirestore(profile);
    auth.markCustomerOnboardingComplete(user.id, name: profile.name);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
      _nameController.text = profile.name;
      _addressController.text = profile.address;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _capitalizeWords(String s) {
    if (s.isEmpty) return s;
    return s
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static String _capitalizeSentence(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final profile = user != null ? repo.customerProfileByUserId(user.id) : null;
    final crm = user != null ? repo.linkedCrmCustomerForAppUser(user.id) : null;
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : crm?.name ?? profile?.name ?? user?.ownerName ?? 'Customer';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return CustomerScaffold(
      child: Column(
        children: [
          _ProfileHeader(
            title: 'My profile',
            onEdit: _editing ? null : () => setState(() => _editing = true),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  customerBottomInset(context, extra: 18),
                ),
                children: [
                  _IdentityCard(
                    photoBytes: _photoBytes,
                    initial: initial,
                    name: displayName,
                    phone: user?.phone ?? '-',
                    editing: _editing,
                    nameController: _nameController,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _ProfileDetailsPanel(
                    editing: _editing,
                    emailController: _emailController,
                    addressController: _addressController,
                  ),
                  const SizedBox(height: 14),
                  _LocationBar(
                    latitude: _lat,
                    longitude: _lng,
                    place: _place,
                    address: _addressController.text,
                    onTap: () => _showLocationSheet(context),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    final latest = user == null
                                        ? null
                                        : repo.customerProfileByUserId(user.id);
                                    setState(() {
                                      _editing = false;
                                      _nameController.text =
                                          latest?.name ?? displayName;
                                      _addressController.text =
                                          latest?.address ??
                                          _addressController.text;
                                      _emailController.text =
                                          latest?.email ?? _emailController.text;
                                      _lat = latest?.latitude ?? _lat;
                                      _lng = latest?.longitude ?? _lng;
                                      _place = latest?.place ?? _place;
                                      _photoBytes = latest?.photoBytes;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: CustomerColors.labelGrey,
                              side: const BorderSide(
                                color: CustomerColors.cardBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: CustomerPrimaryButton(
                            label: 'Save profile',
                            icon: Icons.check_rounded,
                            loading: _saving,
                            onPressed: _saving ? null : _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  _AccountActions(
                    onSignOut: () {
                      auth.logout();
                      context.go(AppRoutes.welcome);
                    },
                    onDelete: () => _confirmDelete(context, auth),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationSheet(BuildContext context) async {
    var tempLat = _lat;
    var tempLng = _lng;
    var tempPlace = _place;
    var hasDraft = tempLat != null && tempLng != null;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                MediaQuery.paddingOf(ctx).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delivery location',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CustomerColors.titleNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Move the map, then use the selected delivery pin.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: CustomerColors.labelGrey,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: MediaQuery.sizeOf(ctx).height * 0.46,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ShopLocationPicker(
                        minimal: true,
                        latitude: tempLat,
                        longitude: tempLng,
                        addressText: _addressController.text,
                        onChanged: (lat, lng, place) {
                          if (lat == null || lng == null) return;
                          setSheetState(() {
                            tempLat = lat;
                            tempLng = lng;
                            hasDraft = true;
                            if (place != null && place.isNotEmpty) {
                              tempPlace = place;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomerPrimaryButton(
                    label: 'Use this location',
                    icon: Icons.location_on_rounded,
                    onPressed: !hasDraft || tempLat == null || tempLng == null
                        ? null
                        : () {
                            setState(() {
                              _lat = tempLat;
                              _lng = tempLng;
                              _place = tempPlace;
                              _editing = true;
                            });
                            Navigator.of(ctx).pop();
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AuthRepository auth) {
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete account?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This permanently deletes your app account and saved delivery details. Monthly billing with shops is managed separately.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: CustomerColors.labelGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              auth.deleteCustomerAccount(userId);
              context.go(AppRoutes.welcome);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.title,
    this.onEdit,
  });

  final String title;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: CustomerColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 18,
        20,
        22,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 10),
            Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.photoBytes,
    required this.initial,
    required this.name,
    required this.phone,
    required this.editing,
    required this.nameController,
    required this.onChanged,
  });

  final Uint8List? photoBytes;
  final String initial;
  final String name;
  final String phone;
  final bool editing;
  final TextEditingController nameController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CustomerColors.cardDecoration,
      child: Row(
        children: [
          _CustomerAvatar(photoBytes: photoBytes, initial: initial, size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (editing)
                  TextFormField(
                    controller: nameController,
                    onChanged: (_) => onChanged(),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Name is required'
                        : null,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CustomerColors.titleNavy,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Full name',
                    ),
                  )
                else
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CustomerColors.titleNavy,
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: CustomerColors.labelGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monthly water account',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CustomerColors.accent,
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

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({
    required this.photoBytes,
    required this.initial,
    required this.size,
  });

  final Uint8List? photoBytes;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CustomerColors.accent.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photoBytes == null
          ? Text(
              initial,
              style: GoogleFonts.poppins(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                color: CustomerColors.accent,
              ),
            )
          : Image.memory(
              photoBytes!,
              fit: BoxFit.cover,
              width: size,
              height: size,
            ),
    );
  }
}

class _ProfileDetailsPanel extends StatelessWidget {
  const _ProfileDetailsPanel({
    required this.editing,
    required this.emailController,
    required this.addressController,
  });

  final bool editing;
  final TextEditingController emailController;
  final TextEditingController addressController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CustomerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: emailController.text.trim().isEmpty
                ? 'Not added'
                : emailController.text.trim(),
            editing: editing,
            controller: emailController,
            hint: 'Optional',
            keyboardType: TextInputType.emailAddress,
          ),
          const _ProfileInsetDivider(),
          _ProfileRow(
            icon: Icons.home_outlined,
            label: 'Delivery address',
            value: addressController.text.trim().isEmpty
                ? 'Add delivery address'
                : addressController.text.trim(),
            editing: editing,
            controller: addressController,
            hint: 'House no., street, area, city',
            maxLines: 2,
            validator: (v) => v == null || v.trim().length < 8
                ? 'Enter full address'
                : null,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.editing,
    this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final bool editing;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final canEdit = editing && controller != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          _FieldIcon(icon: icon),
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
                    color: CustomerColors.labelGrey,
                  ),
                ),
                const SizedBox(height: 4),
                if (canEdit)
                  TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    maxLines: maxLines,
                    onChanged: onChanged,
                    textCapitalization: textCapitalization,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CustomerColors.titleNavy,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: CustomerColors.labelGrey,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CustomerColors.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CustomerColors.accent,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    maxLines: maxLines > 1 ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: value == 'Not added' ||
                              value == 'Add delivery address'
                          ? CustomerColors.labelGrey
                          : CustomerColors.titleNavy,
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

class _FieldIcon extends StatelessWidget {
  const _FieldIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: CustomerColors.accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: CustomerColors.accent, size: 20),
    );
  }
}

class _ProfileInsetDivider extends StatelessWidget {
  const _ProfileInsetDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: 66),
        child: Divider(height: 1, color: CustomerColors.cardBorder),
      );
}

class _LocationBar extends StatelessWidget {
  const _LocationBar({
    required this.latitude,
    required this.longitude,
    required this.place,
    required this.address,
    required this.onTap,
  });

  final double? latitude;
  final double? longitude;
  final String place;
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude != null && longitude != null;
    final selectedLabel = place.trim().isNotEmpty
        ? place.trim()
        : hasPin
            ? 'Selected pin: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
            : 'Tap to set delivery pin';
    final coordinateLabel = hasPin
        ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
        : 'No pin selected';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CustomerColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: CustomerColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: CustomerColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.titleNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.trim().isEmpty
                          ? coordinateLabel
                          : '${address.trim()} - $coordinateLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CustomerColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CustomerColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.onSignOut,
    required this.onDelete,
  });

  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'Sign out',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: CustomerColors.accent,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: CustomerColors.cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFFFECACA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
