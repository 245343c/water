import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class DeliveryRoutesColors {
  static const Color titleNavy = CustomersColors.titleNavy;
  static const Color labelGrey = CustomersColors.labelGrey;
  static const Color accent = Color(0xFF2563EB);
  static const Color accentBg = Color(0xFFEFF6FF);
  static const Color warnBg = Color(0xFFFFF7ED);
  static const Color warnBorder = Color(0xFFFDBA74);
  static const Color warnText = Color(0xFFEA580C);
}

class DeliveryRoutesHeader extends StatelessWidget {
  const DeliveryRoutesHeader({
    super.key,
    required this.onBack,
    this.title = 'Delivery routes',
    this.subtitle,
  });

  final VoidCallback onBack;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: title,
      subtitle: subtitle ?? 'Group customers for drivers',
      onBack: onBack,
    );
  }
}

class DeliveryRouteListCard extends StatelessWidget {
  const DeliveryRouteListCard({
    super.key,
    required this.route,
    required this.customerCount,
    required this.onTap,
  });

  final DeliveryRoute route;
  final int customerCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CustomersColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DeliveryRoutesColors.accentBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DeliveryRoutesColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: DeliveryRoutesColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DeliveryRoutesColors.titleNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$customerCount customer${customerCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: DeliveryRoutesColors.labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DeliveryRoutesColors.labelGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryRoutesUnassignedCard extends StatelessWidget {
  const DeliveryRoutesUnassignedCard({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DeliveryRoutesColors.warnBorder),
              color: DeliveryRoutesColors.warnBg.withValues(alpha: 0.35),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  color: DeliveryRoutesColors.warnText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No route yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DeliveryRoutesColors.titleNavy,
                        ),
                      ),
                      Text(
                        '$count customer${count == 1 ? '' : 's'} need a route',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: DeliveryRoutesColors.warnText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DeliveryRoutesColors.labelGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryRoutesAddFab extends StatelessWidget {
  const DeliveryRoutesAddFab({
    super.key,
    required this.onPressed,
    this.label = 'Add route',
    this.icon = Icons.add_rounded,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 8),
      child: Material(
        elevation: 8,
        shadowColor: DeliveryRoutesColors.accent.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        color: DeliveryRoutesColors.accent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text(
                  label,
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
      ),
    );
  }
}

Future<bool?> showRemoveDeliveryRouteDialog(
  BuildContext context, {
  required String routeName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Remove route?',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: Text(
        '"$routeName" will be hidden from drivers and filters. '
        'Move all customers off this route first.',
        style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Remove', style: GoogleFonts.poppins()),
        ),
      ],
    ),
  );
}

Future<String?> showDeliveryRouteNameDialog(
  BuildContext context, {
  String title = 'New route',
  String? initialName,
  String confirmLabel = 'Create',
}) {
  final controller = TextEditingController(text: initialName ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Route name',
          hintText: 'e.g. Main Road, Evening round',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(confirmLabel, style: GoogleFonts.poppins()),
        ),
      ],
    ),
  );
}
