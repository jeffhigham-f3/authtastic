import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VaultKeyMetadata {
  const VaultKeyMetadata({
    required this.saltB64,
    required this.iterations,
    required this.wrappedDekNonceB64,
    required this.wrappedDekCipherB64,
    required this.wrappedDekMacB64,
  });

  final String saltB64;
  final int iterations;
  final String wrappedDekNonceB64;
  final String wrappedDekCipherB64;
  final String wrappedDekMacB64;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'saltB64': saltB64,
      'iterations': iterations,
      'wrappedDekNonceB64': wrappedDekNonceB64,
      'wrappedDekCipherB64': wrappedDekCipherB64,
      'wrappedDekMacB64': wrappedDekMacB64,
    };
  }

  factory VaultKeyMetadata.fromJson(Map<String, dynamic> json) {
    final saltB64 = json['saltB64'];
    final iterations = json['iterations'];
    final nonce = json['wrappedDekNonceB64'];
    final cipher = json['wrappedDekCipherB64'];
    final mac = json['wrappedDekMacB64'];
    if (saltB64 is! String ||
        iterations is! num ||
        nonce is! String ||
        cipher is! String ||
        mac is! String) {
      throw const FormatException('Corrupted vault key metadata');
    }
    return VaultKeyMetadata(
      saltB64: saltB64,
      iterations: iterations.toInt(),
      wrappedDekNonceB64: nonce,
      wrappedDekCipherB64: cipher,
      wrappedDekMacB64: mac,
    );
  }
}

class SecureKeyStore {
  SecureKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _vaultKeyMetaKey = 'vault_key_metadata_v1';
  static const String _biometricDekKey = 'vault_biometric_dek_v1';

  static const AndroidOptions _androidOptions = AndroidOptions();

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  Future<void> saveKeyMetadata(VaultKeyMetadata metadata) async {
    await _storage.write(
      key: _vaultKeyMetaKey,
      value: jsonEncode(metadata.toJson()),
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<VaultKeyMetadata?> readKeyMetadata() async {
    final value = await _storage.read(
      key: _vaultKeyMetaKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    if (value == null || value.isEmpty) {
      return null;
    }
    return VaultKeyMetadata.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> saveBiometricDek(String dekB64) async {
    await _storage.write(
      key: _biometricDekKey,
      value: dekB64,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<String?> readBiometricDek() {
    return _storage.read(
      key: _biometricDekKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<void> clearBiometricDek() {
    return _storage.delete(
      key: _biometricDekKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}
