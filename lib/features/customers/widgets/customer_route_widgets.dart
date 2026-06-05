import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/constants/delivery_route_constants.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

/// Dropdown on add/edit customer — assign delivery route.
class CustomerRoutePickerField extends StatelessWidget {
  const CustomerRoutePickerField({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.onChanged,
  });

  final List<DeliveryRoute> routes;
  final String? selectedRouteId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery route',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AddEditCustomerColors.titleNavy,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: selectedRouteId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AddEditCustomerColors.fieldFill,
            prefixIcon: const Icon(Icons.route_rounded, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AddEditCustomerColors.fieldBorder),
            ),
          ),
          hint: Text(
            'No route yet',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('No route yet', style: GoogleFonts.poppins()),
            ),
            ...routes.map(
              (r) => DropdownMenuItem<String?>(
                value: r.id,
                child: Text(r.name, style: GoogleFonts.poppins()),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(
          'Driver sees this customer when they select this route.',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AddEditCustomerColors.labelGrey,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// Horizontal chips — filter customers list by route.
class CustomersRouteFilterRow extends StatelessWidget {
  const CustomersRouteFilterRow({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.unassignedCount,
    required this.onSelected,
  });

  /// `null` = all routes; [DeliveryRouteFilters.unassigned] = no route.
  final String? selectedRouteId;
  final List<DeliveryRoute> routes;
  final int unassignedCount;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          _RouteChip(
            label: 'All routes',
            selected: selectedRouteId == null,
            onTap: () => onSelected(null),
          ),
          if (unassignedCount > 0) ...[
            const SizedBox(width: 8),
            _RouteChip(
              label: 'No route ($unassignedCount)',
              selected: selectedRouteId == DeliveryRouteFilters.unassigned,
              onTap: () => onSelected(DeliveryRouteFilters.unassigned),
              warn: true,
            ),
          ],
          ...routes.map(
            (r) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _RouteChip(
                label: r.name,
                selected: selectedRouteId == r.id,
                onTap: () => onSelected(r.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.warn = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (warn ? const Color(0xFFEA580C) : CustomersColors.addButton)
        : Colors.white;
    final fg = selected
        ? Colors.white
        : (warn ? const Color(0xFFEA580C) : CustomersColors.titleNavy);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (warn
                      ? const Color(0xFFFDBA74)
                      : CustomersColors.cardBorder),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerRouteBadge extends StatelessWidget {
  const CustomerRouteBadge({
    super.key,
    required this.routeName,
    this.unassigned = false,
  });

  final String routeName;
  final bool unassigned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: unassigned
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unassigned
              ? const Color(0xFFFDBA74)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        routeName,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: unassigned
              ? const Color(0xFFEA580C)
              : const Color(0xFF2563EB),
        ),
      ),
    );
  }
}
