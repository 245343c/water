import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

/// Header subtitle for nested admin screens — name only, optional detail suffix.
String customerContextSubtitle(String customerName, [String? detail]) {
  final name = customerName.trim();
  final extra = detail?.trim();
  if (extra == null || extra.isEmpty) return name;
  return '$name · $extra';
}

/// Compact delivery address — shown on field screens instead of full [CustomerInfoBar].
class CustomerAddressStrip extends StatelessWidget {
  const CustomerAddressStrip({
    super.key,
    required this.customer,
    this.margin = const EdgeInsets.fromLTRB(16, 10, 16, 0),
  });

  final Customer customer;
  final EdgeInsetsGeometry margin;

  static const Color _labelGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final address = customer.address.trim();
    final place = customer.place.trim();
    final line = address.isNotEmpty
        ? (place.isNotEmpty ? '$address · $place' : address)
        : place;
    if (line.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: margin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CustomersColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place_outlined, size: 16, color: _labelGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.35,
                  color: _labelGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Customer identity card — compact on admin detail, full on customer portal.
class CustomerInfoBar extends StatelessWidget {
  const CustomerInfoBar({
    super.key,
    required this.customer,
    required this.colorIndex,
    this.compact = false,
    this.onCallTap,
    this.onWhatsAppTap,
    this.margin,
  });

  final Customer customer;
  final int colorIndex;
  /// Admin profile: name + call only, white card matching other sections.
  final bool compact;
  final VoidCallback? onCallTap;
  final VoidCallback? onWhatsAppTap;
  final EdgeInsetsGeometry? margin;

  static const Color _titleNavy = AppColors.textPrimary;
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _callBlue = Color(0xFF2563EB);
  static const Color _whatsapp = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final bg = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: compact ? _compactDecoration : _fullDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: bg.withValues(alpha: compact ? 0.35 : 0.45),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: compact ? 22 : 24,
              backgroundColor: bg,
              child: Text(
                customer.initials,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: compact
                ? Text(
                    customer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _titleNavy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _titleNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: _callBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            customer.phone,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _labelGrey,
                            ),
                          ),
                        ],
                      ),
                      if (customer.place.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: _labelGrey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer.place,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _labelGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
          if (compact && onCallTap != null)
            Material(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onCallTap,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.phone_rounded, color: _callBlue, size: 22),
                ),
              ),
            )
          else if (!compact)
            Material(
              color: _whatsapp.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onWhatsAppTap,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.chat, color: _whatsapp, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration get _compactDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: CustomersColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );

  BoxDecoration get _fullDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFBFDBFE)),
    boxShadow: [
      BoxShadow(
        color: _callBlue.withValues(alpha: 0.08),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
