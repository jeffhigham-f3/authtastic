import 'dart:math';

class PasswordGenerator {
  PasswordGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '@#\$%^&*()-_=+[]{}!?.';

  String generate({
    int length = 20,
    bool includeLower = true,
    bool includeUpper = true,
    bool includeDigits = true,
    bool includeSymbols = true,
  }) {
    final buffer = StringBuffer();
    var alphabet = '';
    if (includeLower) alphabet += _lower;
    if (includeUpper) alphabet += _upper;
    if (includeDigits) alphabet += _digits;
    if (includeSymbols) alphabet += _symbols;

    if (alphabet.isEmpty) {
      alphabet = _lower + _upper + _digits;
    }

    for (var i = 0; i < length; i++) {
      final index = _random.nextInt(alphabet.length);
      buffer.write(alphabet[index]);
    }

    return buffer.toString();
  }
}
