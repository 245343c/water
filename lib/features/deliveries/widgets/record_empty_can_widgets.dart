import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_can_balance.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/add_delivery_widgets.dart';

abstract final class RecordEmptyCanColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color accent = Color(0xFF0D9488);
  static const Color accentBg = Color(0xFFF0FDFA);
  static const Color accentBorder = Color(0xFF99F6E4);
  static const Color saveBtn = Color(0xFF0D9488);
}

class RecordEmptyCanHeader extends StatelessWidget {
  const RecordEmptyCanHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Record Empty Return',
      subtitle: 'Update can balance without delivery',
      onBack: onBack,
    );
  }
}

class RecordEmptyCanCustomerBar extends StatelessWidget {
  const RecordEmptyCanCustomerBar({
    super.key,
    required this.customer,
    required this.colorIndex,
  });

  final Customer customer;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    return AddDeliveryCustomerBar(
      customer: customer,
      colorIndex: colorIndex,
    );
  }
}

class RecordEmptyCanBalanceHint extends StatelessWidget {
  const RecordEmptyCanBalanceHint({super.key, required this.balance});

  final CustomerCanBalance balance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: RecordEmptyCanColors.accentBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RecordEmptyCanColors.accentBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: RecordEmptyCanColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Current balance: ${balance.normalWithCustomer} normal · '
                '${balance.coolWithCustomer} cool empty cans with customer',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.4,
                  color: RecordEmptyCanColors.titleNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordEmptyCanDateRow extends StatelessWidget {
  const RecordEmptyCanDateRow({
    super.key,
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AddDeliveryDateRow(date: date, onTap: onTap);
  }
}

class RecordEmptyCanSaveButton extends StatelessWidget {
  const RecordEmptyCanSaveButton({
    super.key,
    required this.enabled,
    required this.isSaving,
    required this.onPressed,
  });

  final bool enabled;
  final bool isSaving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: enabled && !isSaving ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: RecordEmptyCanColors.saveBtn,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save empty return'),
        ),
      ),
    );
  }
}

class RecordEmptyCanScaffold extends StatelessWidget {
  const RecordEmptyCanScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumResponsiveBody(maxWidth: 1180, child: child);
  }
}
