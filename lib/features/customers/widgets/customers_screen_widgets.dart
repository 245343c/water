import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/constants/delivery_route_constants.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/widgets/admin_tab_header.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/routes/widgets/delivery_routes_widgets.dart';

/// Customers screen theme (matches mockup).
abstract final class CustomersColors {
  static const Color headerTop = Color(0xFF001F3F);
  static const Color headerBottom = Color(0xFF002B5C);
  static const Color addButton = Color(0xFF1A73E8);
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color searchFill = Color(0xFFF9FAFB);
  static const Color searchBorder = Color(0xFFE5E7EB);
  static const Color balanceRed = Color(0xFFDC2626);
  static const Color balanceGreen = Color(0xFF16A34A);
  static const Color screenBg = Color(0xFFF3F4F6);
  static const Color cardBorder = Color(0xFFE5E7EB);

  /// Solid avatar backgrounds with white initials (mockup).
  static const List<Color> avatarBgs = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  static BoxDecoration get headerGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [headerTop, headerBottom],
        ),
      );

  /// Matches dashboard / products list chrome.
  static BoxDecoration get screenGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.36, 1],
          colors: [headerTop, headerBottom, AppColors.surface],
        ),
      );

  static BoxDecoration get whiteCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      );
}

class CustomersHeader extends StatelessWidget {
  const CustomersHeader({
    super.key,
    this.title = 'Customers',
    this.subtitle,
    this.icon = Icons.people_rounded,
    this.iconColor,
    this.trailing,
    required this.onAdd,
    this.onMenu,
    this.showAddButton = true,
    this.searchController,
    this.onSearchChanged,
    this.searchHint = 'Search customers...',
    this.onFilter,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onAdd;
  final VoidCallback? onMenu;
  final bool showAddButton;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return AdminTabPageHeader(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      trailing: trailing,
      onMenu: onMenu,
      onAdd: onAdd,
      showAddButton: showAddButton,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      searchHint: searchHint,
      onFilter: onFilter,
    );
  }
}

/// Shared navy header for admin sub-screens (back + title + optional trailing).
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.paddingOf(context).top + 16,
        12,
        18,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class CustomersListPanel extends StatelessWidget {
  const CustomersListPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ColoredBox(
            color: CustomersColors.screenBg,
            child: child,
          ),
        ),
      ),
    );
  }
}

class CustomersSearchRow extends StatelessWidget {
  const CustomersSearchRow({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search customers...',
    this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: GoogleFonts.poppins(fontSize: 14, color: CustomersColors.titleNavy),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: CustomersColors.addButton,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onFilter != null) ...[
            const SizedBox(width: 10),
            Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onFilter,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
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

enum CustomerListFilter { all, pending, paid, overdue }

extension CustomerListFilterX on CustomerListFilter {
  String get label => switch (this) {
        CustomerListFilter.all => 'All',
        CustomerListFilter.pending => 'Pending',
        CustomerListFilter.paid => 'Paid',
        CustomerListFilter.overdue => 'Overdue',
      };

  Color get accent => switch (this) {
        CustomerListFilter.all => CustomersColors.titleNavy,
        CustomerListFilter.pending => const Color(0xFFEA580C),
        CustomerListFilter.paid => const Color(0xFF16A34A),
        CustomerListFilter.overdue => const Color(0xFFDC2626),
      };
}

/// Side-by-side route + payment filters (scales to many routes via bottom sheet).
class CustomersDualFilterBar extends StatelessWidget {
  const CustomersDualFilterBar({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.selectedPayment,
    required this.routeCounts,
    required this.paymentCounts,
    required this.onRouteChanged,
    required this.onPaymentChanged,
    required this.onCreateRouteRequested,
    required this.routeCountsFor,
    required this.onRouteRemoved,
  });

  /// `null` = all routes; [DeliveryRouteFilters.unassigned] = no route.
  final String? selectedRouteId;
  final CustomerListFilter selectedPayment;
  final List<DeliveryRoute> routes;
  final Map<String?, int> routeCounts;
  final Map<CustomerListFilter, int> paymentCounts;
  final ValueChanged<String?> onRouteChanged;
  final ValueChanged<CustomerListFilter> onPaymentChanged;
  final Future<String?> Function() onCreateRouteRequested;
  final Map<String?, int> Function(WaterPlantRepository repo) routeCountsFor;
  final ValueChanged<String> onRouteRemoved;

  bool get _routeActive => selectedRouteId != null;
  bool get _paymentActive => selectedPayment != CustomerListFilter.all;

  String _routeLabel() {
    if (selectedRouteId == null) return 'All routes';
    if (selectedRouteId == DeliveryRouteFilters.unassigned) return 'No route';
    final match = routes.where((r) => r.id == selectedRouteId);
    return match.isEmpty ? 'Route' : match.first.name;
  }

  Future<void> _openRouteSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CustomersRouteFilterSheet(
        selectedRouteId: selectedRouteId,
        routeCountsFor: routeCountsFor,
        onCreateRouteRequested: onCreateRouteRequested,
        onRouteRemoved: onRouteRemoved,
      ),
    );
    if (picked == null) return;
    onRouteChanged(
      picked == _CustomersRouteFilterPick.all ? null : picked,
    );
  }

  Future<void> _openPaymentSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<CustomerListFilter?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CustomersPaymentFilterSheet(
        selected: selectedPayment,
        paymentCounts: paymentCounts,
      ),
    );
    if (picked == null) return;
    onPaymentChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: _CustomersFilterPill(
              label: _routeLabel(),
              icon: Icons.route_rounded,
              active: _routeActive,
              accent: _routeActive &&
                      selectedRouteId == DeliveryRouteFilters.unassigned
                  ? const Color(0xFFEA580C)
                  : CustomersColors.addButton,
              onTap: () => _openRouteSheet(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CustomersFilterPill(
              label: selectedPayment.label,
              icon: Icons.payments_outlined,
              active: _paymentActive,
              accent: selectedPayment.accent,
              onTap: () => _openPaymentSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomersFilterPill extends StatelessWidget {
  const _CustomersFilterPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = active ? accent : CustomersColors.cardBorder;
    final bg = active ? accent.withValues(alpha: 0.08) : Colors.white;

    return Material(
      color: bg,
      elevation: active ? 0 : 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: active ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: active ? accent : CustomersColors.labelGrey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? accent : CustomersColors.titleNavy,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: active ? accent : CustomersColors.labelGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Distinguishes "All routes" from sheet dismiss (both would otherwise be null).
abstract final class _CustomersRouteFilterPick {
  static const all = '__all_routes__';
}

class _CustomersRouteFilterSheet extends StatefulWidget {
  const _CustomersRouteFilterSheet({
    required this.selectedRouteId,
    required this.routeCountsFor,
    required this.onCreateRouteRequested,
    required this.onRouteRemoved,
  });

  final String? selectedRouteId;
  final Map<String?, int> Function(WaterPlantRepository repo) routeCountsFor;
  final Future<String?> Function() onCreateRouteRequested;
  final ValueChanged<String> onRouteRemoved;

  @override
  State<_CustomersRouteFilterSheet> createState() =>
      _CustomersRouteFilterSheetState();
}

class _CustomersRouteFilterSheetState extends State<_CustomersRouteFilterSheet> {
  final _search = TextEditingController();
  bool _creating = false;
  String? _removingRouteId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DeliveryRoute> _filteredRoutes(List<DeliveryRoute> routes) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return routes;
    return routes.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  void _pickAll() => Navigator.pop(context, _CustomersRouteFilterPick.all);

  void _pickRoute(String id) => Navigator.pop(context, id);

  Future<void> _createRoute() async {
    if (_creating) return;
    setState(() => _creating = true);
    final createdRouteId = await widget.onCreateRouteRequested();
    if (!mounted) return;
    setState(() => _creating = false);
    if (createdRouteId == null || createdRouteId.trim().isEmpty) return;
    Navigator.pop(context, createdRouteId);
  }

  Future<void> _removeRoute(WaterPlantRepository repo, DeliveryRoute route) async {
    if (_removingRouteId != null) return;
    setState(() => _removingRouteId = route.id);
    final confirmed = await showRemoveDeliveryRouteDialog(
      context,
      routeName: route.name,
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _removingRouteId = null);
      return;
    }
    try {
      await repo.archiveDeliveryRoute(route.id);
      if (!mounted) return;
      widget.onRouteRemoved(route.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Route "${route.name}" removed',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('ArgumentError: ', ''),
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _removingRouteId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final routes = repo.activeDeliveryRoutes;
        final routeCounts = widget.routeCountsFor(repo);
        final bottom = MediaQuery.paddingOf(context).bottom;
        final filtered = _filteredRoutes(routes);
        final unassigned = routeCounts[DeliveryRouteFilters.unassigned] ?? 0;

        return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CustomersColors.cardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Filter by route',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search routes…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: CustomersColors.searchFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CustomersColors.searchBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 12 + bottom),
                children: [
                  _RouteFilterTile(
                    label: 'All routes',
                    count: routeCounts[null] ?? 0,
                    selected: widget.selectedRouteId == null,
                    onTap: _pickAll,
                  ),
                  if (unassigned > 0)
                    _RouteFilterTile(
                      label: 'No route yet',
                      count: unassigned,
                      selected:
                          widget.selectedRouteId == DeliveryRouteFilters.unassigned,
                      warn: true,
                      onTap: () => _pickRoute(DeliveryRouteFilters.unassigned),
                    ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No routes match your search',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: CustomersColors.labelGrey),
                      ),
                    )
                  else
                    ...filtered.map(
                      (r) => _RouteFilterTile(
                        label: r.name,
                        count: routeCounts[r.id] ?? 0,
                        selected: widget.selectedRouteId == r.id,
                        onTap: () => _pickRoute(r.id),
                        onRemove: _removingRouteId == r.id
                            ? null
                            : () => _removeRoute(repo, r),
                        removing: _removingRouteId == r.id,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
              child: OutlinedButton.icon(
                onPressed: _creating ? null : _createRoute,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CustomersColors.addButton,
                  side: const BorderSide(color: CustomersColors.addButton),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _creating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  _creating ? 'Creating route...' : 'Create new route',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
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

class _RouteFilterTile extends StatelessWidget {
  const _RouteFilterTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.warn = false,
    this.onRemove,
    this.removing = false,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final bool warn;
  final VoidCallback? onRemove;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    final accent = warn ? const Color(0xFFEA580C) : CustomersColors.addButton;

    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? accent : CustomersColors.labelGrey,
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 14,
          color: warn && !selected ? accent : CustomersColors.titleNavy,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.12)
                  : CustomersColors.searchFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? accent : CustomersColors.labelGrey,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            removing
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Remove route',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: const Color(0xFFDC2626),
                    visualDensity: VisualDensity.compact,
                  ),
          ],
        ],
      ),
    );
  }
}

class _CustomersPaymentFilterSheet extends StatelessWidget {
  const _CustomersPaymentFilterSheet({
    required this.selected,
    required this.paymentCounts,
  });

  final CustomerListFilter selected;
  final Map<CustomerListFilter, int> paymentCounts;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CustomersColors.cardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Filter by payment',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...CustomerListFilter.values.map((f) {
            final isSel = f == selected;
            final accent = f.accent;
            return ListTile(
              onTap: () => Navigator.pop(context, f),
              leading: Icon(
                isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSel ? accent : CustomersColors.labelGrey,
              ),
              title: Text(
                f.label,
                style: GoogleFonts.poppins(
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                  color: isSel ? accent : CustomersColors.titleNavy,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSel
                      ? accent.withValues(alpha: 0.12)
                      : CustomersColors.searchFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${paymentCounts[f] ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSel ? accent : CustomersColors.labelGrey,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class CustomersFilterChips extends StatelessWidget {
  const CustomersFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CustomerListFilter selected;
  final ValueChanged<CustomerListFilter> onSelected;

  static const _labels = {
    CustomerListFilter.all: 'All',
    CustomerListFilter.pending: 'Pending',
    CustomerListFilter.paid: 'Paid',
    CustomerListFilter.overdue: 'Overdue',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: CustomerListFilter.values.map((f) {
          final isSel = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSel ? CustomersColors.addButton : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onSelected(f),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel ? CustomersColors.addButton : CustomersColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    _labels[f]!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : CustomersColors.titleNavy,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CustomersScaffold extends StatelessWidget {
  const CustomersScaffold({
    super.key,
    required this.child,
    this.usePageGradient = false,
  });

  final Widget child;
  /// When true, uses dashboard-style gradient + wide layout (Customers / Add customer).
  final bool usePageGradient;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: usePageGradient
          ? Container(
              decoration: CustomersColors.screenGradient,
              child: PremiumResponsiveBody(
                maxWidth: 1180,
                horizontalPadding: 4,
                child: child,
              ),
            )
          : child,
    );
  }
}

/// Fixed bottom-right add action (Customers list).
class CustomersAddButton extends StatelessWidget {
  const CustomersAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF16A34A),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                'Add customer',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
