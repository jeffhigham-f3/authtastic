import 'dart:math';

class PasswordGenerator {
  PasswordGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = r'@#$%^&*()-_=+[]{}!?.';

  String generate({
    int length = 20,
    bool includeLower = true,
    bool includeUpper = true,
    bool includeDigits = true,
    bool includeSymbols = true,
  }) {
    if (length < 8) {
      throw ArgumentError.value(length, 'length', 'Must be at least 8');
    }

    final pools = <String>[];
    if (includeLower) pools.add(_lower);
    if (includeUpper) pools.add(_upper);
    if (includeDigits) pools.add(_digits);
    if (includeSymbols) pools.add(_symbols);

    if (pools.isEmpty) {
      pools.addAll([_lower, _upper, _digits]);
    }

    final alphabet = pools.join();
    final result = List<String>.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    );

    for (var i = 0; i < pools.length && i < length; i++) {
      final pool = pools[i];
      result[i] = pool[_random.nextInt(pool.length)];
    }

    result.shuffle(_random);
    return result.join();
  }
}
