import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

import '../crypto/vault_crypto.dart';
import '../models/otp_item.dart';
import '../models/password_item.dart';
import '../models/vault_data.dart';
import '../models/vault_settings.dart';
import '../storage/local_vault_store.dart';
import '../storage/secure_key_store.dart';
import '../utils/password_generator.dart';
import 'vault_session_state.dart';

enum ImportMode { merge, replace }

final vaultControllerProvider =
    StateNotifierProvider<VaultController, VaultSessionState>((ref) {
      return VaultController(
        crypto: VaultCrypto(),
        keyStore: SecureKeyStore(),
        localStore: LocalVaultStore(),
        localAuth: LocalAuthentication(),
        idGenerator: const Uuid(),
        passwordGenerator: PasswordGenerator(),
      );
    });

class VaultController extends StateNotifier<VaultSessionState> {
  VaultController({
    required VaultCrypto crypto,
    required SecureKeyStore keyStore,
    required LocalVaultStore localStore,
    required LocalAuthentication localAuth,
    required Uuid idGenerator,
    required PasswordGenerator passwordGenerator,
  }) : _crypto = crypto,
       _keyStore = keyStore,
       _localStore = localStore,
       _localAuth = localAuth,
       _idGenerator = idGenerator,
       _passwordGenerator = passwordGenerator,
       super(VaultSessionState.loading()) {
    unawaited(initialize());
  }

  final VaultCrypto _crypto;
  final SecureKeyStore _keyStore;
  final LocalVaultStore _localStore;
  final LocalAuthentication _localAuth;
  final Uuid _idGenerator;
  final PasswordGenerator _passwordGenerator;

  SecretKey? _sessionDek;
  String? _sessionPassword;

  Future<void> initialize() async {
    state = VaultSessionState.loading();
    final metadata = await _keyStore.readKeyMetadata();
    if (metadata == null) {
      state = VaultSessionState.needsSetup();
      return;
    }
    state = VaultSessionState.locked();
  }

  Future<bool> createVault({
    required String masterPassword,
    required bool biometricEnabled,
  }) async {
    final password = masterPassword.trim();
    if (password.length < 8) {
      state = VaultSessionState.error(
        'Master password must be at least 8 characters.',
      );
      return false;
    }

    try {
      final salt = await _crypto.randomBytes(16);
      final kek = await _crypto.derivePasswordKey(
        password: password,
        salt: salt,
      );
      final dekBytes = await _crypto.randomBytes(32);
      final wrappedDek = await _crypto.encrypt(plaintext: dekBytes, key: kek);

      final metadata = VaultKeyMetadata(
        saltB64: _crypto.b64Encode(salt),
        iterations: _crypto.defaultIterations,
        wrappedDekNonceB64: _crypto.b64Encode(wrappedDek.nonce),
        wrappedDekCipherB64: _crypto.b64Encode(wrappedDek.cipherText),
        wrappedDekMacB64: _crypto.b64Encode(wrappedDek.mac.bytes),
      );
      await _keyStore.saveKeyMetadata(metadata);

      final settings = VaultSettings(biometricEnabled: biometricEnabled);
      final vault = VaultData.empty().copyWith(
        settings: settings,
        updatedAt: DateTime.now().toUtc(),
      );

      _sessionDek = SecretKey(dekBytes);
      _sessionPassword = password;
      await _persistVault(vault);

      if (biometricEnabled) {
        await _keyStore.saveBiometricPassword(password);
      } else {
        await _keyStore.clearBiometricPassword();
      }

      state = VaultSessionState.unlocked(vault);
      return true;
    } catch (_) {
      state = VaultSessionState.error('Failed to create vault.');
      return false;
    }
  }

  Future<bool> unlockWithPassword(
    String masterPassword, {
    bool cacheForBiometric = true,
  }) async {
    final metadata = await _keyStore.readKeyMetadata();
    if (metadata == null) {
      state = VaultSessionState.needsSetup();
      return false;
    }

    try {
      final key = await _crypto.derivePasswordKey(
        password: masterPassword,
        salt: _crypto.b64Decode(metadata.saltB64),
        iterations: metadata.iterations,
      );
      final wrappedBox = SecretBox(
        _crypto.b64Decode(metadata.wrappedDekCipherB64),
        nonce: _crypto.b64Decode(metadata.wrappedDekNonceB64),
        mac: Mac(_crypto.b64Decode(metadata.wrappedDekMacB64)),
      );
      final dek = await _crypto.decrypt(box: wrappedBox, key: key);
      _sessionDek = SecretKey(dek);
      _sessionPassword = masterPassword;

      final data = await _loadVault();
      if (cacheForBiometric && data.settings.biometricEnabled) {
        await _keyStore.saveBiometricPassword(masterPassword);
      }
      state = VaultSessionState.unlocked(data);
      return true;
    } catch (_) {
      state = VaultSessionState.locked(
        errorMessage: 'Invalid master password.',
      );
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        state = VaultSessionState.locked(
          errorMessage:
              'Biometric authentication is not available on this device.',
        );
        return false;
      }
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock your AuthTastic vault',
      );
      if (!didAuthenticate) {
        return false;
      }

      final cachedPassword = await _keyStore.readBiometricPassword();
      if (cachedPassword == null || cachedPassword.isEmpty) {
        state = VaultSessionState.locked(
          errorMessage:
              'No biometric unlock secret is available. Use your master password.',
        );
        return false;
      }
      return unlockWithPassword(cachedPassword, cacheForBiometric: false);
    } catch (_) {
      state = VaultSessionState.locked(
        errorMessage: 'Biometric unlock failed. Try master password.',
      );
      return false;
    }
  }

  Future<void> lock() async {
    _sessionDek = null;
    _sessionPassword = null;
    state = VaultSessionState.locked();
  }

  Future<bool> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final metadata = await _keyStore.readKeyMetadata();
    if (metadata == null || _sessionDek == null) {
      state = VaultSessionState.locked();
      return false;
    }

    try {
      final currentKey = await _crypto.derivePasswordKey(
        password: currentPassword,
        salt: _crypto.b64Decode(metadata.saltB64),
        iterations: metadata.iterations,
      );
      final wrappedBox = SecretBox(
        _crypto.b64Decode(metadata.wrappedDekCipherB64),
        nonce: _crypto.b64Decode(metadata.wrappedDekNonceB64),
        mac: Mac(_crypto.b64Decode(metadata.wrappedDekMacB64)),
      );
      final currentDek = await _crypto.decrypt(
        box: wrappedBox,
        key: currentKey,
      );

      final newSalt = await _crypto.randomBytes(16);
      final newKek = await _crypto.derivePasswordKey(
        password: newPassword,
        salt: newSalt,
      );
      final rewrappedDek = await _crypto.encrypt(
        plaintext: currentDek,
        key: newKek,
      );
      final newMetadata = VaultKeyMetadata(
        saltB64: _crypto.b64Encode(newSalt),
        iterations: _crypto.defaultIterations,
        wrappedDekNonceB64: _crypto.b64Encode(rewrappedDek.nonce),
        wrappedDekCipherB64: _crypto.b64Encode(rewrappedDek.cipherText),
        wrappedDekMacB64: _crypto.b64Encode(rewrappedDek.mac.bytes),
      );
      await _keyStore.saveKeyMetadata(newMetadata);

      _sessionPassword = newPassword;
      final currentState = state.data;
      if (currentState?.settings.biometricEnabled ?? false) {
        await _keyStore.saveBiometricPassword(newPassword);
      }
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Unable to change master password.');
      return false;
    }
  }

  String generatePassword() => _passwordGenerator.generate();

  Future<void> addPassword(PasswordItem item) async {
    final data = state.data;
    if (data == null) return;
    final now = DateTime.now().toUtc();
    final updated = data.copyWith(
      passwords: <PasswordItem>[...data.passwords, item],
      updatedAt: now,
    );
    await _persistAndEmit(updated);
  }

  Future<void> updatePassword(PasswordItem item) async {
    final data = state.data;
    if (data == null) return;
    final updatedPasswords = data.passwords.map((PasswordItem current) {
      if (current.id != item.id) return current;
      return item.copyWith(
        updatedAt: DateTime.now().toUtc(),
        revision: current.revision + 1,
      );
    }).toList();
    final updated = data.copyWith(
      passwords: updatedPasswords,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistAndEmit(updated);
  }

  Future<void> deletePassword(String id) async {
    final data = state.data;
    if (data == null) return;
    final updated = data.copyWith(
      passwords: data.passwords.where((item) => item.id != id).toList(),
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistAndEmit(updated);
  }

  Future<void> markPasswordUsed(String id) async {
    final data = state.data;
    if (data == null) return;
    final now = DateTime.now().toUtc();
    final updated = data.copyWith(
      passwords: data.passwords.map((PasswordItem item) {
        if (item.id != id) return item;
        return item.copyWith(lastUsedAt: now, updatedAt: now);
      }).toList(),
      updatedAt: now,
    );
    await _persistAndEmit(updated);
  }

  Future<void> addOtp(OtpItem item) async {
    final data = state.data;
    if (data == null) return;
    final updated = data.copyWith(
      otps: <OtpItem>[...data.otps, item],
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistAndEmit(updated);
  }

  Future<void> deleteOtp(String id) async {
    final data = state.data;
    if (data == null) return;
    final updated = data.copyWith(
      otps: data.otps.where((item) => item.id != id).toList(),
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistAndEmit(updated);
  }

  Future<void> updateSettings(VaultSettings settings) async {
    final data = state.data;
    if (data == null) return;
    final updated = data.copyWith(
      settings: settings,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistAndEmit(updated);

    if (!settings.biometricEnabled) {
      await _keyStore.clearBiometricPassword();
      return;
    }
    if (_sessionPassword != null && _sessionPassword!.isNotEmpty) {
      await _keyStore.saveBiometricPassword(_sessionPassword!);
    }
  }

  PasswordItem buildPassword({
    required String title,
    required String username,
    required String password,
    String? website,
    String? notes,
    String? category,
    String? id,
    DateTime? createdAt,
  }) {
    final now = DateTime.now().toUtc();
    return PasswordItem(
      id: id ?? _idGenerator.v4(),
      title: title.trim(),
      username: username.trim(),
      password: password,
      website: _normalizeWebsite(website),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      category: category,
      createdAt: createdAt ?? now,
      updatedAt: now,
      lastUsedAt: null,
    );
  }

  OtpItem buildOtp({
    required String issuer,
    required String accountName,
    required String secret,
    required String algorithm,
    required int digits,
    required int period,
  }) {
    final now = DateTime.now().toUtc();
    return OtpItem(
      id: _idGenerator.v4(),
      issuer: issuer.trim(),
      accountName: accountName.trim(),
      secret: secret.replaceAll(' ', ''),
      algorithm: algorithm.toUpperCase(),
      digits: digits,
      period: period,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<String?> exportVault(String passphrase) async {
    final data = state.data;
    if (data == null) return null;

    try {
      final salt = await _crypto.randomBytes(16);
      const iterations = 150000;
      final exportKey = await _crypto.derivePasswordKey(
        password: passphrase,
        salt: salt,
        iterations: iterations,
      );
      final payload = utf8.encode(jsonEncode(data.toJson()));
      final box = await _crypto.encrypt(
        plaintext: Uint8List.fromList(payload),
        key: exportKey,
      );

      final exportJson = <String, dynamic>{
        'version': 1,
        'saltB64': _crypto.b64Encode(salt),
        'iterations': iterations,
        'nonceB64': _crypto.b64Encode(box.nonce),
        'cipherB64': _crypto.b64Encode(box.cipherText),
        'macB64': _crypto.b64Encode(box.mac.bytes),
      };

      return _localStore.writeExportFile(
        fileName: 'authtastic_backup_${DateTime.now().millisecondsSinceEpoch}',
        content: jsonEncode(exportJson),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> importVault({
    required String path,
    required String passphrase,
    required ImportMode mode,
  }) async {
    final currentData = state.data;
    if (currentData == null) return false;

    try {
      final raw = await _localStore.readTextFile(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final salt = _crypto.b64Decode(json['saltB64'] as String);
      final iterations = (json['iterations'] as num).toInt();
      final key = await _crypto.derivePasswordKey(
        password: passphrase,
        salt: salt,
        iterations: iterations,
      );
      final box = SecretBox(
        _crypto.b64Decode(json['cipherB64'] as String),
        nonce: _crypto.b64Decode(json['nonceB64'] as String),
        mac: Mac(_crypto.b64Decode(json['macB64'] as String)),
      );
      final decrypted = await _crypto.decrypt(box: box, key: key);
      final imported = VaultData.fromJson(
        jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>,
      );

      final resolved = mode == ImportMode.replace
          ? imported.copyWith(
              settings: currentData.settings,
              updatedAt: DateTime.now().toUtc(),
            )
          : _mergeVaultData(currentData, imported);

      await _persistAndEmit(resolved);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<VaultData> _loadVault() async {
    final blob = await _localStore.loadVaultBlob();
    if (blob == null) {
      final empty = VaultData.empty();
      await _persistVault(empty);
      return empty;
    }

    final key = _sessionDek;
    if (key == null) {
      throw StateError('No session key');
    }
    final decrypted = await _crypto.decrypt(
      box: SecretBox(
        _crypto.b64Decode(blob.cipherB64),
        nonce: _crypto.b64Decode(blob.nonceB64),
        mac: Mac(_crypto.b64Decode(blob.macB64)),
      ),
      key: key,
    );
    final json = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
    return VaultData.fromJson(json);
  }

  Future<void> _persistAndEmit(VaultData data) async {
    try {
      await _persistVault(data);
      state = VaultSessionState.unlocked(data);
    } catch (_) {
      state = VaultSessionState.error('Failed to persist vault data.');
    }
  }

  Future<void> _persistVault(VaultData data) async {
    final key = _sessionDek;
    if (key == null) {
      throw StateError('No active session key.');
    }
    final plaintext = Uint8List.fromList(
      utf8.encode(jsonEncode(data.toJson())),
    );
    final box = await _crypto.encrypt(plaintext: plaintext, key: key);
    final blob = EncryptedVaultBlob(
      version: 1,
      nonceB64: _crypto.b64Encode(box.nonce),
      cipherB64: _crypto.b64Encode(box.cipherText),
      macB64: _crypto.b64Encode(box.mac.bytes),
    );
    await _localStore.saveVaultBlob(blob);
  }

  VaultData _mergeVaultData(VaultData current, VaultData imported) {
    final passwordMap = <String, PasswordItem>{
      for (final item in current.passwords) item.id: item,
    };
    for (final incoming in imported.passwords) {
      final existing = passwordMap[incoming.id];
      if (existing == null || incoming.updatedAt.isAfter(existing.updatedAt)) {
        passwordMap[incoming.id] = incoming;
      }
    }

    final otpMap = <String, OtpItem>{
      for (final item in current.otps) item.id: item,
    };
    for (final incoming in imported.otps) {
      final existing = otpMap[incoming.id];
      if (existing == null || incoming.updatedAt.isAfter(existing.updatedAt)) {
        otpMap[incoming.id] = incoming;
      }
    }

    return current.copyWith(
      passwords: passwordMap.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      otps: otpMap.values.toList()
        ..sort((a, b) => a.issuer.compareTo(b.issuer)),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  String? _normalizeWebsite(String? website) {
    if (website == null) return null;
    final value = website.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://$value';
  }
}
