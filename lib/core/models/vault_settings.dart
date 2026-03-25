class VaultSettings {
  const VaultSettings({
    this.biometricEnabled = false,
    this.autoLockEnabled = true,
    this.notificationsEnabled = false,
    this.darkModeEnabled = false,
  });

  final bool biometricEnabled;
  final bool autoLockEnabled;
  final bool notificationsEnabled;
  final bool darkModeEnabled;

  VaultSettings copyWith({
    bool? biometricEnabled,
    bool? autoLockEnabled,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
  }) {
    return VaultSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'biometricEnabled': biometricEnabled,
      'autoLockEnabled': autoLockEnabled,
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
    };
  }

  factory VaultSettings.fromJson(Map<String, dynamic> json) {
    return VaultSettings(
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      autoLockEnabled: json['autoLockEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
    );
  }
}
