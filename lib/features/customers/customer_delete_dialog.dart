import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

/// Returns `true` if the user confirmed deletion.
Future<bool> confirmDeleteCustomer(
  BuildContext context, {
  required String customerName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete customer?',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: Text(
        'Delete $customerName and all their deliveries and payments? This cannot be undone.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.45,
          color: AddEditCustomerColors.labelGrey,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: AddEditCustomerColors.labelGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Delete',
            style: GoogleFonts.poppins(
              color: CustomersColors.balanceRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
