import 'package:authtastic/core/utils/otpauth_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtpAuthParser', () {
    test('parses standard TOTP URI', () {
      const uri =
          'otpauth://totp/GitHub:john@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA1&digits=6&period=30';
      final result = OtpAuthParser.parse(uri);
      expect(result, isNotNull);
      expect(result!.issuer, 'GitHub');
      expect(result.accountName, 'john@example.com');
      expect(result.secret, 'JBSWY3DPEHPK3PXP');
      expect(result.algorithm, 'SHA1');
      expect(result.digits, 6);
      expect(result.period, 30);
    });

    test('rejects non-otpauth scheme', () {
      expect(OtpAuthParser.parse('https://example.com'), isNull);
    });

    test('rejects HOTP', () {
      expect(
        OtpAuthParser.parse(
          'otpauth://hotp/Test?secret=JBSWY3DPEHPK3PXP&counter=0',
        ),
        isNull,
      );
    });

    test('rejects empty secret', () {
      expect(OtpAuthParser.parse('otpauth://totp/Test?secret='), isNull);
    });

    test('rejects invalid base32 secret', () {
      expect(
        OtpAuthParser.parse('otpauth://totp/Test?secret=INVALID!!'),
        isNull,
      );
    });

    test('rejects out-of-range digits', () {
      expect(
        OtpAuthParser.parse(
          'otpauth://totp/Test?secret=JBSWY3DPEHPK3PXP&digits=4',
        ),
        isNull,
      );
    });

    test('rejects out-of-range period', () {
      expect(
        OtpAuthParser.parse(
          'otpauth://totp/Test?secret=JBSWY3DPEHPK3PXP&period=5',
        ),
        isNull,
      );
    });

    test('defaults to SHA1, 6 digits, 30s when params missing', () {
      final result = OtpAuthParser.parse(
        'otpauth://totp/MyService:user?secret=JBSWY3DPEHPK3PXP',
      );
      expect(result, isNotNull);
      expect(result!.algorithm, 'SHA1');
      expect(result.digits, 6);
      expect(result.period, 30);
    });
  });
}
