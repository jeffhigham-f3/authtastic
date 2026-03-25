import 'package:authtastic/core/models/otp_item.dart';
import 'package:authtastic/core/models/password_item.dart';
import 'package:authtastic/core/models/vault_settings.dart';

class VaultData {
  const VaultData({
    required this.passwords,
    required this.otps,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 1,
  });

  final List<PasswordItem> passwords;
  final List<OtpItem> otps;
  final VaultSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  factory VaultData.empty() {
    final now = DateTime.now().toUtc();
    return VaultData(
      passwords: const <PasswordItem>[],
      otps: const <OtpItem>[],
      settings: const VaultSettings(),
      createdAt: now,
      updatedAt: now,
    );
  }

  VaultData copyWith({
    List<PasswordItem>? passwords,
    List<OtpItem>? otps,
    VaultSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? schemaVersion,
  }) {
    return VaultData(
      passwords: passwords ?? this.passwords,
      otps: otps ?? this.otps,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'passwords': passwords.map((PasswordItem item) => item.toJson()).toList(),
      'otps': otps.map((OtpItem item) => item.toJson()).toList(),
      'settings': settings.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }

  factory VaultData.fromJson(Map<String, dynamic> json) {
    return VaultData(
      passwords: (json['passwords'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic item) =>
                PasswordItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      otps: (json['otps'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => OtpItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      settings: VaultSettings.fromJson(
        (json['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }
}
