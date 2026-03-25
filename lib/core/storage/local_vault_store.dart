import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EncryptedVaultBlob {
  const EncryptedVaultBlob({
    required this.version,
    required this.nonceB64,
    required this.cipherB64,
    required this.macB64,
  });

  final int version;
  final String nonceB64;
  final String cipherB64;
  final String macB64;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'nonceB64': nonceB64,
      'cipherB64': cipherB64,
      'macB64': macB64,
    };
  }

  factory EncryptedVaultBlob.fromJson(Map<String, dynamic> json) {
    return EncryptedVaultBlob(
      version: (json['version'] as num?)?.toInt() ?? 1,
      nonceB64: json['nonceB64'] as String,
      cipherB64: json['cipherB64'] as String,
      macB64: json['macB64'] as String,
    );
  }
}

class LocalVaultStore {
  static const String _vaultFileName = 'vault_blob_v1.json';
  static const String _exportExtension = '.authtastic';

  Future<File> _vaultFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = p.join(directory.path, _vaultFileName);
    return File(filePath);
  }

  Future<bool> hasVaultBlob() async {
    final file = await _vaultFile();
    return file.exists();
  }

  Future<void> saveVaultBlob(EncryptedVaultBlob blob) async {
    final file = await _vaultFile();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(blob.toJson()), flush: true);
  }

  Future<EncryptedVaultBlob?> loadVaultBlob() async {
    final file = await _vaultFile();
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      return null;
    }
    return EncryptedVaultBlob.fromJson(
      jsonDecode(content) as Map<String, dynamic>,
    );
  }

  Future<String> writeExportFile({
    required String fileName,
    required String content,
  }) async {
    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, '$fileName$_exportExtension');
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  Future<String> readTextFile(String path) async {
    final file = File(path);
    return file.readAsString();
  }
}
