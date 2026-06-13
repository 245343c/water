abstract final class InputValidators {
  static final RegExp _emailPattern = RegExp(
    r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
    caseSensitive: false,
  );

  static const Set<String> _blockedEmailDomains = {
    'example.com',
    'example.org',
    'example.net',
    'test.com',
    'test.local',
    'waterapp.local',
    'mailinator.com',
    'tempmail.com',
    'temp-mail.org',
    '10minutemail.com',
    'guerrillamail.com',
    'yopmail.com',
  };

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static bool isValidEmail(String value, {bool allowInternal = false}) {
    final email = normalizeEmail(value);
    if (!_emailPattern.hasMatch(email)) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    final local = parts.first;
    final domain = parts.last;
    if (local.startsWith('.') || local.endsWith('.') || local.contains('..')) {
      return false;
    }
    if (domain.startsWith('-') ||
        domain.endsWith('-') ||
        domain.contains('..') ||
        !domain.contains('.')) {
      return false;
    }
    if (!allowInternal && _blockedEmailDomains.contains(domain)) return false;
    return true;
  }

  static String? requiredEmail(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return 'Email is required';
    if (!isValidEmail(email)) return 'Enter a valid real email address';
    return null;
  }

  static String? optionalEmail(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return null;
    if (!isValidEmail(email)) return 'Enter a valid real email address';
    return null;
  }

  static String phoneDigits(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static bool isValidIndianMobile(String value) {
    final digits = phoneDigits(value);
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }

  static String? requiredIndianMobile(String? value) {
    final digits = phoneDigits(value ?? '');
    if (digits.isEmpty) return 'Phone number is required';
    if (!isValidIndianMobile(digits)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? requiredStaffLoginId(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Mobile number or email is required';
    if (trimmed.contains('@')) {
      return isValidEmail(normalizeEmail(trimmed))
          ? null
          : 'Enter a valid email address';
    }
    return requiredIndianMobile(trimmed);
  }
}
