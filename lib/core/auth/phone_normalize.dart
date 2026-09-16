/// Phone helpers for signup / Firebase Phone Auth / backend verify-otp.
///
/// Backend and Firebase must agree on E.164. Default country is India (`91`).
class PhoneNormalize {
  PhoneNormalize._();

  /// Common dial codes shown in the signup country selector.
  static const List<({String iso, String dial, String label})> countryOptions = [
    (iso: 'IN', dial: '91', label: 'India'),
    (iso: 'US', dial: '1', label: 'United States'),
    (iso: 'AE', dial: '971', label: 'UAE'),
    (iso: 'GB', dial: '44', label: 'United Kingdom'),
  ];

  /// Expected national subscriber length for a dial code (best-effort).
  static int expectedNationalLength(String dialCode) {
    final cc = dialCode.replaceAll('+', '');
    switch (cc) {
      case '91':
        return 10;
      case '1':
        return 10;
      case '44':
        return 10;
      case '971':
        return 9;
      default:
        return 10;
    }
  }

  /// Digits only from [raw].
  static String digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  /// E.164 with [defaultCountryCallingCode] when input has no usable country code.
  ///
  /// Handles common India mistakes:
  /// - national-only `9876543210` → `+919876543210`
  /// - pasted `919876543210` / `+919876543210` (no double-`91`)
  /// - leading `0` trunk prefix
  ///
  /// Does **not** silently truncate wrong-length numbers — use [validationError].
  static String toE164(
    String raw, {
    String defaultCountryCallingCode = '91',
  }) {
    final cc = defaultCountryCallingCode.replaceAll('+', '');
    var s = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    String digits;
    if (s.startsWith('+')) {
      digits = digitsOnly(s.substring(1));
    } else if (s.startsWith('00')) {
      digits = digitsOnly(s.substring(2));
    } else {
      digits = digitsOnly(s);
    }

    if (digits.isEmpty) return '+$cc';

    final nationalLen = expectedNationalLength(cc);

    // Drop a single leading trunk zero (e.g. 09876543210 → 9876543210).
    if (digits.startsWith('0') && digits.length == nationalLen + 1) {
      digits = digits.substring(1);
    }

    // Already includes country calling code + exact national length.
    if (digits.startsWith(cc) && digits.length == cc.length + nationalLen) {
      return '+$digits';
    }

    // User pasted country code twice: 9191XXXXXXXXXX
    if (digits.startsWith('$cc$cc') &&
        digits.length == cc.length * 2 + nationalLen) {
      return '+${digits.substring(cc.length)}';
    }

    // National-only (correct length).
    if (digits.length == nationalLen) {
      return '+$cc$digits';
    }

    // Input already looks like full international without `+`.
    if (digits.startsWith(cc)) {
      return '+$digits';
    }

    return '+$cc$digits';
  }

  /// Returns a user-facing error if [raw] cannot form a valid number for [dialCode].
  /// When [required] is false, empty input is allowed (returns null).
  static String? validationError(
    String raw, {
    String dialCode = '91',
    bool required = true,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return required ? 'Please enter your phone number' : null;
    }

    final cc = dialCode.replaceAll('+', '');
    final nationalLen = expectedNationalLength(cc);
    final e164 = toE164(trimmed, defaultCountryCallingCode: cc);
    final allDigits = digitsOnly(e164);

    // Must be exactly +CC + nationalLen digits.
    if (!allDigits.startsWith(cc) ||
        allDigits.length != cc.length + nationalLen) {
      if (cc == '91') {
        return 'Enter a valid 10-digit Indian mobile number';
      }
      return 'Enter a valid $nationalLen-digit phone number';
    }

    final national = allDigits.substring(cc.length);

    // India mobiles start with 6–9.
    if (cc == '91' && !RegExp(r'^[6-9]\d{9}$').hasMatch(national)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }

    return null;
  }

  /// Last N national digits (typical IN mobile = 10).
  static String nationalDigits(String phone, {int length = 10}) {
    final d = digitsOnly(phone);
    if (d.length >= length) return d.substring(d.length - length);
    return d;
  }

  /// Digits with country code, no `+` (e.g. `918769626027`).
  static String digitsWithCountry(
    String phone, {
    String defaultCountryCallingCode = '91',
  }) {
    return toE164(phone, defaultCountryCallingCode: defaultCountryCallingCode)
        .replaceAll(RegExp(r'\D'), '');
  }

  /// Distinct formats to try for signup ensure + verify-otp lookup.
  static List<String> lookupVariants(
    String phone, {
    String defaultCountryCallingCode = '91',
  }) {
    final e164 =
        toE164(phone, defaultCountryCallingCode: defaultCountryCallingCode);
    final national = nationalDigits(
      e164,
      length: expectedNationalLength(defaultCountryCallingCode),
    );
    final withCc = digitsWithCountry(
      e164,
      defaultCountryCallingCode: defaultCountryCallingCode,
    );
    final out = <String>[];
    for (final v in [e164, national, withCc]) {
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
    return out;
  }
}
