import 'package:authtastic/core/utils/password_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordGenerator', () {
    test('creates passwords with expected length', () {
      final generator = PasswordGenerator();
      final value = generator.generate(length: 24);
      expect(value.length, 24);
    });

    test('falls back to alphanumeric if no flags enabled', () {
      final generator = PasswordGenerator();
      final value = generator.generate(
        length: 16,
        includeLower: false,
        includeUpper: false,
        includeDigits: false,
        includeSymbols: false,
      );
      expect(value.length, 16);
    });
  });
}
