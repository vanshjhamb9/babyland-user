import 'package:babyland/core/auth/phone_normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneNormalize', () {
    test('toE164 adds +91 for 10-digit IN mobiles', () {
      expect(PhoneNormalize.toE164('8769626027'), '+918769626027');
      expect(PhoneNormalize.toE164('+918769626027'), '+918769626027');
      expect(PhoneNormalize.toE164('918769626027'), '+918769626027');
      expect(PhoneNormalize.toE164('08769626027'), '+918769626027');
    });

    test('toE164 does not double-prefix when 91 already present', () {
      expect(PhoneNormalize.toE164('917902177376'), '+917902177376');
      expect(
        PhoneNormalize.toE164('91917902177376'),
        '+917902177376',
      );
    });

    test('validationError rejects TOO_LONG India numbers', () {
      // Log case: +9162830751312 (11 national digits) → invalid
      expect(
        PhoneNormalize.validationError('62830751312'),
        isNotNull,
      );
      expect(
        PhoneNormalize.validationError('9162830751312'),
        isNotNull,
      );
      expect(
        PhoneNormalize.validationError('7902177376'),
        isNull,
      );
      expect(
        PhoneNormalize.validationError('917902177376'),
        isNull,
      );
    });

    test('lookupVariants covers e164, national, and cc-digits', () {
      expect(
        PhoneNormalize.lookupVariants('8769626027'),
        ['+918769626027', '8769626027', '918769626027'],
      );
    });

    test('countryOptions defaults include India 91', () {
      expect(PhoneNormalize.countryOptions.first.dial, '91');
      expect(PhoneNormalize.countryOptions.first.iso, 'IN');
    });
  });
}
