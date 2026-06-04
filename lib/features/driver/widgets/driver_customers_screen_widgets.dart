import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

enum DriverCustomerListFilter { all, pendingToday, deliveredToday }

/// Compact list row — clean white card, minimal metadata.
class DriverCustomerListCard extends StatelessWidget {
  const DriverCustomerListCard({
    super.key,
    required this.customer,
    required this.lastDeliveryLabel,
    required this.deliveredToday,
    required this.onTap,
  });

  final Customer customer;
  final String lastDeliveryLabel;
  final bool deliveredToday;
  final VoidCallback onTap;

  static const Color _avatar = DriverColors.accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: DriverColors.accent.withValues(alpha: 0.08),
        highlightColor: DriverColors.accent.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DriverColors.cardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _avatar.withValues(alpha: 0.15),
                child: Text(
                  customer.initials,
                  style: GoogleFonts.poppins(
                    color: DriverColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DriverColors.titleNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.place.isNotEmpty
                          ? '${customer.place} · ${customer.phone}'
                          : customer.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: DriverColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastDeliveryLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: DriverColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (deliveredToday)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DriverColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: DriverColors.success,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DriverColors.labelGrey,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title + search in one clean header block (colour only here).
class DriverCustomersToolbar extends StatelessWidget {
  const DriverCustomersToolbar({
    super.key,
    required this.title,
    this.subtitle,
    required this.searchController,
    required this.onSearchChanged,
  });

  final String title;
  final String? subtitle;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DriverColors.headerStart,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 10,
        16,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: GoogleFonts.poppins(fontSize: 14, color: DriverColors.titleNavy),
            decoration: InputDecoration(
              hintText: 'Search name or phone',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DriverColors.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverCustomersFilterChips extends StatelessWidget {
  const DriverCustomersFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DriverCustomerListFilter selected;
  final ValueChanged<DriverCustomerListFilter> onSelected;

  static const _labels = {
    DriverCustomerListFilter.all: 'All',
    DriverCustomerListFilter.pendingToday: 'Pending',
    DriverCustomerListFilter.deliveredToday: 'Done today',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: DriverCustomerListFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: filter != DriverCustomerListFilter.deliveredToday ? 6 : 0,
              ),
              child: Material(
                color: isSelected ? DriverColors.accent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onSelected(filter),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? DriverColors.accent
                            : DriverColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      _labels[filter]!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : DriverColors.titleNavy,
                      ),
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
