import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/payment_allocation_preview.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class RecordPaymentColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color summaryBg = Color(0xFFECFDF5);
  static const Color summaryBorder = Color(0xFFA7F3D0);
  static const Color totalGreen = Color(0xFF16A34A);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color selectedBg = Color(0xFFEFF6FF);
  static const Color selectedBorder = Color(0xFF2563EB);
  static const Color saveGreen = Color(0xFF16A34A);
}

class RecordPaymentHeader extends StatelessWidget {
  const RecordPaymentHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 4, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Record Payment',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class RecordPaymentCustomerBar extends StatelessWidget {
  const RecordPaymentCustomerBar({
    super.key,
    required this.customer,
    required this.colorIndex,
  });

  final Customer customer;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final bg = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: bg,
            child: Text(
              customer.initials,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
                    color: RecordPaymentColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: RecordPaymentColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecordPaymentSummaryBox extends StatelessWidget {
  const RecordPaymentSummaryBox({
    super.key,
    required this.month,
    required this.totalAmount,
    required this.previousBalance,
    required this.totalPayable,
    this.advanceCredit = 0,
  });

  final DateTime month;
  final double totalAmount;
  final double previousBalance;
  final double totalPayable;
  final double advanceCredit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: RecordPaymentColors.summaryBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RecordPaymentColors.summaryBorder),
        ),
        child: Column(
          children: [
            Text(
              'Total Amount (${month.monthYear})',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: RecordPaymentColors.labelGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyUtils.format(totalAmount),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: RecordPaymentColors.totalGreen,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _miniColumn('Older due', CurrencyUtils.format(previousBalance)),
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: RecordPaymentColors.summaryBorder),
                  Expanded(
                    child: _miniColumn(
                      'Total due',
                      CurrencyUtils.format(totalPayable.clamp(0, double.infinity)),
                    ),
                  ),
                ],
              ),
            ),
            if (advanceCredit > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined, size: 18, color: Color(0xFF0D9488)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Advance on account: ${CurrencyUtils.format(advanceCredit)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 11, color: RecordPaymentColors.labelGrey),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: RecordPaymentColors.dangerRed,
          ),
        ),
      ],
    );
  }
}

class RecordPaymentMethodRow extends StatelessWidget {
  const RecordPaymentMethodRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: RecordPaymentColors.titleNavy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: PaymentMethod.values.map((m) {
              final isSel = m == selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: m != PaymentMethod.other ? 8 : 0,
                  ),
                  child: InkWell(
                    onTap: () => onSelected(m),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSel ? RecordPaymentColors.selectedBg : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? RecordPaymentColors.selectedBorder : RecordPaymentColors.fieldBorder,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 18,
                            color: isSel ? RecordPaymentColors.selectedBorder : RecordPaymentColors.labelGrey,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              m.label,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: RecordPaymentColors.titleNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class RecordPaymentLabeledField extends StatelessWidget {
  const RecordPaymentLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: RecordPaymentColors.titleNavy,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class RecordPaymentDateField extends StatelessWidget {
  const RecordPaymentDateField({
    super.key,
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RecordPaymentColors.fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  date.fullDate,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RecordPaymentColors.titleNavy,
                  ),
                ),
              ),
              const Icon(Icons.calendar_today_outlined, size: 20, color: RecordPaymentColors.labelGrey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live preview: how this payment splits across FIFO due vs advance.
class RecordPaymentAllocationPreview extends StatelessWidget {
  const RecordPaymentAllocationPreview({super.key, required this.preview});

  final PaymentAllocationPreview preview;

  @override
  Widget build(BuildContext context) {
    final amount = preview.appliedToDue + preview.advanceCredit;
    if (amount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: RecordPaymentColors.selectedBorder.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    size: 18,
                    color: RecordPaymentColors.selectedBorder,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Payment split (oldest month first)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: RecordPaymentColors.titleNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (preview.appliedToDue > 0)
              _splitRow(
                icon: Icons.receipt_long_outlined,
                label: 'Clears pending bills',
                value: CurrencyUtils.format(preview.appliedToDue),
                color: RecordPaymentColors.totalGreen,
              ),
            if (preview.appliedToDue > 0 && preview.hasAdvance) const SizedBox(height: 8),
            if (preview.hasAdvance)
              _splitRow(
                icon: Icons.savings_outlined,
                label: 'Saved as advance credit',
                value: CurrencyUtils.format(preview.advanceCredit),
                color: const Color(0xFF0D9488),
              ),
            if (preview.pendingAfter > 0) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: RecordPaymentColors.fieldBorder),
              const SizedBox(height: 8),
              Text(
                'Remaining due after payment: ${CurrencyUtils.format(preview.pendingAfter)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: RecordPaymentColors.labelGrey,
                ),
              ),
            ],
            if (preview.clearsAllDue && preview.hasAdvance) ...[
              const SizedBox(height: 8),
              Text(
                'All months paid — extra stays on account for next bill',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF0F766E),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _splitRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: RecordPaymentColors.labelGrey),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class RecordPaymentSaveButton extends StatelessWidget {
  const RecordPaymentSaveButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: RecordPaymentColors.saveGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: const Text('Save Payment'),
          ),
        ),
      ),
    );
  }
}

class RecordPaymentScaffold extends StatelessWidget {
  const RecordPaymentScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: child,
    );
  }
}
