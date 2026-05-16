import 'package:intl/intl.dart';

/// Indian Rupee formatting using the official symbol ₹ (U+20B9), not "Rs." or "INR".
abstract final class CurrencyUtils {
  /// Official Indian Rupee sign per Unicode / RBI usage.
  static const String symbol = '₹';

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: 0,
  );

  static String format(double amount) => _inr.format(amount.round());
}
