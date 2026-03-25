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
    return VaultKeyMetadata(
      saltB64: json['saltB64'] as String,
      iterations: (json['iterations'] as num).toInt(),
      wrappedDekNonceB64: json['wrappedDekNonceB64'] as String,
      wrappedDekCipherB64: json['wrappedDekCipherB64'] as String,
      wrappedDekMacB64: json['wrappedDekMacB64'] as String,
    );
  }
}

class SecureKeyStore {
  SecureKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _vaultKeyMetaKey = 'vault_key_metadata_v1';
  static const String _biometricPasswordKey = 'vault_biometric_password_v1';

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

  Future<void> saveBiometricPassword(String password) async {
    await _storage.write(
      key: _biometricPasswordKey,
      value: password,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<String?> readBiometricPassword() {
    return _storage.read(
      key: _biometricPasswordKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<void> clearBiometricPassword() {
    return _storage.delete(
      key: _biometricPasswordKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}
