import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

/// Shared customer identity card — used on Monthly Summary and Customer Details.
class CustomerInfoBar extends StatelessWidget {
  const CustomerInfoBar({
    super.key,
    required this.customer,
    required this.colorIndex,
    this.onWhatsAppTap,
    this.margin,
  });

  final Customer customer;
  final int colorIndex;
  final VoidCallback? onWhatsAppTap;
  final EdgeInsetsGeometry? margin;

  static const Color _titleNavy = AppColors.textPrimary;
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _statBlue = Color(0xFF2563EB);
  static const Color _whatsapp = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final bg = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: _statBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: bg.withValues(alpha: 0.45), width: 2),
            ),
            child: CircleAvatar(
              radius: 24,
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
            child: Column(
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
                    const Icon(Icons.phone_outlined, size: 14, color: _statBlue),
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
                      const Icon(Icons.place_outlined, size: 13, color: _labelGrey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          customer.place,
                          style: GoogleFonts.poppins(fontSize: 12, color: _labelGrey),
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
}
