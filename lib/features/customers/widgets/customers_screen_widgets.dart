import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';

/// Customers screen theme (matches mockup).
abstract final class CustomersColors {
  static const Color headerTop = AppColors.headerTop;
  static const Color headerBottom = AppColors.headerBottom;
  static const Color headerGlow = AppColors.primary;
  static const Color addButton = AppColors.primary;
  static const Color titleNavy = AppColors.textPrimary;
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color divider = AppColors.cardBorder;
  static const Color searchFill = Color(0xFFF9FAFB);
  static const Color searchBorder = Color(0xFFE5E7EB);
  static const Color balanceRed = Color(0xFFDC2626);
  static const Color balanceGreen = Color(0xFF16A34A);
  static const Color screenBg = AppColors.surface;
  static const Color cardBorder = AppColors.cardBorder;

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
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [headerTop, headerBottom],
    ),
  );

  static BoxDecoration get premiumCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: cardBorder),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class CustomersHeader extends StatelessWidget {
  const CustomersHeader({
    super.key,
    this.title = 'Customers',
    required this.onAdd,
    this.onMenu,
    this.showAddButton = true,
  });

  final String title;
  final VoidCallback onAdd;
  final VoidCallback? onMenu;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        16,
        14,
      ),
      child: Row(
        children: [
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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sri Sai RO Water',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (showAddButton)
            Material(
              color: Colors.white.withValues(alpha: 0.14),
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 46),
        ],
      ),
    );
  }
}

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
        decoration: BoxDecoration(
          color: CustomersColors.screenBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.2,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ColoredBox(color: CustomersColors.screenBg, child: child),
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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: CustomersColors.titleNavy,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 21,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: CustomersColors.searchBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: CustomersColors.addButton,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: onFilter,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF334155),
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum CustomerListFilter { all, pending, paid, overdue }

const String unassignedRouteFilter = '__unassigned_route__';

class CustomerRouteFilter extends StatelessWidget {
  const CustomerRouteFilter({
    super.key,
    required this.routes,
    required this.selected,
    required this.onSelected,
    required this.onManageRoutes,
  });

  final List<DeliveryRoute> routes;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final VoidCallback onManageRoutes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: selected,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Route',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: CustomersColors.labelGrey,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CustomersColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CustomersColors.cardBorder),
                ),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Routes', style: GoogleFonts.poppins()),
                ),
                DropdownMenuItem<String?>(
                  value: unassignedRouteFilter,
                  child: Text('Unassigned', style: GoogleFonts.poppins()),
                ),
                for (final route in routes)
                  DropdownMenuItem<String?>(
                    value: route.id,
                    child: Text(route.name, style: GoogleFonts.poppins()),
                  ),
              ],
              onChanged: onSelected,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onManageRoutes,
            icon: const Icon(Icons.add_road_rounded, size: 18),
            label: const Text('Routes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CustomersColors.addButton,
              side: const BorderSide(color: CustomersColors.addButton),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              textStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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

  static const _visibleFilters = [
    CustomerListFilter.all,
    CustomerListFilter.pending,
    CustomerListFilter.paid,
    CustomerListFilter.overdue,
  ];

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
        children: _visibleFilters.map((f) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel
                          ? CustomersColors.addButton
                          : CustomersColors.cardBorder,
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
  const CustomersScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PremiumResponsiveBody(maxWidth: 1180, child: child),
    );
  }
}
