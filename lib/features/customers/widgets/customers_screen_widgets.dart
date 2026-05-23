import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';

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
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 4, 12, 18),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 26),
            onPressed: onMenu ?? () {},
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showAddButton)
            Material(
              color: CustomersColors.addButton,
              elevation: 4,
              shadowColor: CustomersColors.addButton.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onAdd,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.poppins(fontSize: 14, color: CustomersColors.titleNavy),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
                filled: true,
                fillColor: CustomersColors.searchFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CustomersColors.searchBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CustomersColors.searchBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CustomersColors.addButton, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onFilter,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CustomersColors.searchBorder),
                ),
                child: const Icon(Icons.filter_list, color: Color(0xFF6B7280), size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum CustomerListFilter { all, pending, paid, overdue }

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
  const CustomersScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PremiumResponsiveBody(
        maxWidth: 1040,
        child: child,
      ),
    );
  }
}
