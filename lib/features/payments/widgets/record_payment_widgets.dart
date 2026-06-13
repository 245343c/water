import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_info_bar.dart'
    show customerContextSubtitle;
import 'package:sri_sai_ro_water/data/models/payment_allocation_preview.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class RecordPaymentColors {
  static const Color titleNavy = CustomersColors.titleNavy;
  static const Color labelGrey = CustomersColors.labelGrey;
  static const Color dangerRed = CustomersColors.balanceRed;
  static const Color fieldBorder = CustomersColors.cardBorder;
  static const Color selectedBg = Color(0xFFEFF6FF);
  static const Color selectedBorder = CustomersColors.addButton;
  static const Color statGreen = CustomersColors.balanceGreen;

  static BoxDecoration get premiumPanel => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: CustomersColors.addButton.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get sectionCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomersColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

class RecordPaymentHeader extends StatelessWidget {
  const RecordPaymentHeader({
    super.key,
    required this.onBack,
    this.customerName,
  });

  final VoidCallback onBack;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Record Payment',
      subtitle: customerName == null
          ? 'Update customer ledger'
          : customerContextSubtitle(customerName!),
      onBack: onBack,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: RecordPaymentColors.premiumPanel,
        child: Column(
          children: [
            Text(
              'Total amount (${month.monthYear})',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CustomersColors.labelGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyUtils.format(totalAmount),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: CustomersColors.titleNavy,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _miniColumn(
                      'Older due',
                      CurrencyUtils.format(previousBalance),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFBFDBFE),
                  ),
                  Expanded(
                    child: _miniColumn(
                      'Total due',
                      CurrencyUtils.format(
                        totalPayable.clamp(0, double.infinity),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (advanceCredit > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      size: 18,
                      color: Color(0xFF0D9488),
                    ),
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
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: CustomersColors.labelGrey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: RecordPaymentColors.dangerRed,
          ),
        ),
      ],
    );
  }
}

class RecordPaymentAmountField extends StatelessWidget {
  const RecordPaymentAmountField({
    super.key,
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return RecordPaymentLabeledField(
      label: 'Payment amount',
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: RecordPaymentColors.titleNavy,
        ),
        decoration: _fieldDecoration(prefixText: '${CurrencyUtils.symbol} '),
        validator: validator,
      ),
    );
  }
}

class RecordPaymentNotesField extends StatelessWidget {
  const RecordPaymentNotesField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return RecordPaymentLabeledField(
      label: 'Notes (optional)',
      child: TextFormField(
        controller: controller,
        maxLines: 2,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: RecordPaymentColors.titleNavy,
        ),
        decoration: _fieldDecoration(hintText: 'Cheque no., UPI ref, remarks…'),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hintText, String? prefixText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.poppins(
      color: RecordPaymentColors.labelGrey,
      fontSize: 14,
    ),
    prefixText: prefixText,
    prefixStyle: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: RecordPaymentColors.titleNavy,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: RecordPaymentColors.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: RecordPaymentColors.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: RecordPaymentColors.selectedBorder,
        width: 1.5,
      ),
    ),
  );
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: RecordPaymentColors.titleNavy,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentMethod.values.map((m) {
              final isSel = m == selected;
              return Material(
                color: isSel
                    ? RecordPaymentColors.selectedBg
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onSelected(m),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? RecordPaymentColors.selectedBorder
                            : RecordPaymentColors.fieldBorder,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSel
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 18,
                          color: isSel
                              ? RecordPaymentColors.selectedBorder
                              : RecordPaymentColors.labelGrey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          m.label,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: RecordPaymentColors.titleNavy,
                          ),
                        ),
                      ],
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
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: RecordPaymentColors.labelGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        decoration: RecordPaymentColors.sectionCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: RecordPaymentColors.selectedBorder.withValues(
                      alpha: 0.12,
                    ),
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
                color: RecordPaymentColors.statGreen,
              ),
            if (preview.appliedToDue > 0 && preview.hasAdvance)
              const SizedBox(height: 8),
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
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: RecordPaymentColors.labelGrey,
            ),
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
  const RecordPaymentSaveButton({
    super.key,
    required this.onPressed,
    this.isSaving = false,
  });

  final VoidCallback? onPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomersColors.screenBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onPressed,
              icon: isSaving
                  ? const SizedBox.shrink()
                  : const Icon(Icons.check_rounded, size: 20),
              label: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save payment',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: CustomersColors.addButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
    return CustomersScaffold(usePageGradient: true, child: child);
  }
}
