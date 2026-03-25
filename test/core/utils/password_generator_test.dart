import 'package:authtastic/core/utils/password_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordGenerator', () {
    test('creates passwords with expected length', () {
      final generator = PasswordGenerator();
      final value = generator.generate(length: 24);
      expect(value.length, 24);
    });

    test('throws ArgumentError for length < 8', () {
      final generator = PasswordGenerator();
      expect(
        () => generator.generate(length: 4),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('generated password contains at least one char from each class', () {
      final generator = PasswordGenerator();
      for (var i = 0; i < 20; i++) {
        final value = generator.generate(length: 16);
        expect(value, matches(RegExp(r'[a-z]')));
        expect(value, matches(RegExp(r'[A-Z]')));
        expect(value, matches(RegExp(r'[0-9]')));
      }
    });
  });
}
