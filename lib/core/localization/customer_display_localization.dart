import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';

extension DriverCustomerDisplay on Customer {
  String driverDisplayName(AppStrings strings) {
    final localized = switch (strings.appLanguage) {
      AppLanguage.telugu => driverNameTe,
      AppLanguage.hindi => driverNameHi,
      AppLanguage.english => '',
    }
        .trim();
    return localized.isNotEmpty ? localized : name;
  }

  String driverAddressNote(AppStrings strings) {
    return switch (strings.appLanguage) {
      AppLanguage.telugu => driverAddressNoteTe,
      AppLanguage.hindi => driverAddressNoteHi,
      AppLanguage.english => '',
    }
        .trim();
  }

  String driverInitials(AppStrings strings) {
    final displayName = driverDisplayName(strings);
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
