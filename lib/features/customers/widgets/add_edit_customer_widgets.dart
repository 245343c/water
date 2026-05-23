import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class AddEditCustomerColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color fieldFill = Color(0xFFF9FAFB);
  static const Color primaryBtn = Color(0xFF1A73E8);
}

class AddEditCustomerHeader extends StatelessWidget {
  const AddEditCustomerHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onDelete,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.paddingOf(context).top + 4,
        4,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
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
          if (onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 22,
              ),
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class AddEditCustomerFormCard extends StatelessWidget {
  const AddEditCustomerFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddEditCustomerColors.fieldBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class AddEditCustomerField extends StatelessWidget {
  const AddEditCustomerField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.validator,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AddEditCustomerColors.titleNavy,
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CustomersColors.balanceRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            validator: validator,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AddEditCustomerColors.titleNavy,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AddEditCustomerColors.labelGrey,
              ),
              filled: true,
              fillColor: AddEditCustomerColors.fieldFill,
              prefixIcon: icon != null
                  ? Icon(icon, size: 20, color: AddEditCustomerColors.labelGrey)
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: icon != null ? 12 : 14,
                vertical: maxLines > 1 ? 14 : 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AddEditCustomerColors.fieldBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AddEditCustomerColors.fieldBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AddEditCustomerColors.primaryBtn,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CustomersColors.balanceRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: CustomersColors.balanceRed,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerAppAccessInfoCard extends StatelessWidget {
  const CustomerAppAccessInfoCard({
    super.key,
    required this.phone,
    required this.shopName,
    this.isEditing = false,
  });

  final String phone;
  final String shopName;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final hasValidPhone = digits.length >= 10;
    final color = hasValidPhone
        ? AddEditCustomerColors.primaryBtn
        : const Color(0xFFEA580C);
    final bg = hasValidPhone
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFFFF7ED);
    final border = hasValidPhone
        ? const Color(0xFFBFDBFE)
        : const Color(0xFFFED7AA);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasValidPhone
                  ? Icons.phone_iphone_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer app access',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AddEditCustomerColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasValidPhone
                      ? 'This phone can sign in and see only $shopName in the customer app.'
                      : 'Enter a valid phone number to link this customer to your shop app.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.35,
                    color: AddEditCustomerColors.labelGrey,
                  ),
                ),
                if (isEditing && hasValidPhone) ...[
                  const SizedBox(height: 6),
                  Text(
                    'If you change the phone, the customer must sign in with the new number.',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      height: 1.35,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider between sections inside one form card.
class AddEditCustomerFormDivider extends StatelessWidget {
  const AddEditCustomerFormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AddEditCustomerColors.fieldBorder,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.more_horiz,
              size: 18,
              color: AddEditCustomerColors.labelGrey.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AddEditCustomerColors.fieldBorder,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subsection title inside the unified customer form card.
class AddEditCustomerSubsectionHeader extends StatelessWidget {
  const AddEditCustomerSubsectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AddEditCustomerColors.primaryBtn.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sell_outlined,
              color: AddEditCustomerColors.primaryBtn,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AddEditCustomerColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AddEditCustomerColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class AddEditCustomerSaveButton extends StatelessWidget {
  const AddEditCustomerSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
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
              backgroundColor: AddEditCustomerColors.primaryBtn,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class AddEditCustomerScaffold extends StatelessWidget {
  const AddEditCustomerScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: ColoredBox(color: CustomersColors.screenBg, child: child),
    );
  }
}

String? validateEmailOptional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final email = value.trim();
  final valid = RegExp(r'^[\w\.\-+%]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  return valid ? null : 'Enter a valid email address';
}
