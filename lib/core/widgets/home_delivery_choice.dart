import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium yes/no choice for shop home delivery (admin register + settings).
class HomeDeliveryChoice extends StatelessWidget {
  const HomeDeliveryChoice({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.hideDescriptions = false,
    this.titleOnly = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;
  /// Hides subtitle text under each option tile.
  final bool hideDescriptions;
  /// Shows only the question line (no paragraph below it).
  final bool titleOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            'Do you offer home delivery?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          if (!titleOnly) ...[
            const SizedBox(height: 6),
            Text(
              'Only shops with home delivery appear in the customer app. '
              'Pickup-only shops stay hidden from customers.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: _OptionTile(
                selected: value,
                icon: Icons.delivery_dining_rounded,
                title: 'Yes, home delivery',
                subtitle: hideDescriptions ? null : 'Customers can order to their address',
                accent: const Color(0xFF16A34A),
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OptionTile(
                selected: !value,
                icon: Icons.storefront_rounded,
                title: 'Shop pickup only',
                subtitle: hideDescriptions ? null : 'Not shown in customer app',
                accent: const Color(0xFF6B7280),
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? accent : const Color(0xFFE5E7EB),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: selected ? accent : const Color(0xFF9CA3AF)),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 20, color: accent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
