import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class VaultCrypto {
  VaultCrypto({this.defaultIterations = 210000});

  final int defaultIterations;
  final Random _random = Random.secure();

  Future<Uint8List> randomBytes(int length) async {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  Future<SecretKey> derivePasswordKey({
    required String password,
    required Uint8List salt,
    int? iterations,
  }) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations ?? defaultIterations,
      bits: 256,
    );
    return algorithm.deriveKeyFromPassword(password: password, nonce: salt);
  }

  Future<SecretBox> encrypt({
    required Uint8List plaintext,
    required SecretKey key,
    Uint8List? nonce,
  }) async {
    final algorithm = AesGcm.with256bits();
    return algorithm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce ?? await randomBytes(12),
    );
  }

  Future<Uint8List> decrypt({
    required SecretBox box,
    required SecretKey key,
  }) async {
    final algorithm = AesGcm.with256bits();
    final bytes = await algorithm.decrypt(box, secretKey: key);
    return Uint8List.fromList(bytes);
  }

  String b64Encode(List<int> bytes) => base64Encode(bytes);

  Uint8List b64Decode(String value) => Uint8List.fromList(base64Decode(value));
}
