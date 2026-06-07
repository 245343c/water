import 'package:flutter/material.dart';

/// Empty jars still with customer above this count show a red warning (admin + driver).
const int emptyCanWarningThreshold = 4;

bool emptyCanCountIsWarning(int withCustomer) =>
    withCustomer > emptyCanWarningThreshold;

Color emptyCanCountColor(int withCustomer, {required Color normalColor}) {
  if (withCustomer <= 0) return normalColor;
  return emptyCanCountIsWarning(withCustomer)
      ? const Color(0xFFDC2626)
      : normalColor;
}

String emptyJarsDueLabel(int totalWithCustomer) {
  if (totalWithCustomer <= 0) return '';
  final unit = totalWithCustomer == 1 ? 'jar' : 'jars';
  return '$totalWithCustomer $unit due';
}
