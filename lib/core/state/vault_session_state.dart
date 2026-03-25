import '../models/vault_data.dart';

enum VaultStatus { loading, needsSetup, locked, unlocked, error }

class VaultSessionState {
  const VaultSessionState({required this.status, this.data, this.errorMessage});

  final VaultStatus status;
  final VaultData? data;
  final String? errorMessage;

  bool get isUnlocked => status == VaultStatus.unlocked && data != null;

  VaultSessionState copyWith({
    VaultStatus? status,
    VaultData? data,
    String? errorMessage,
  }) {
    return VaultSessionState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  factory VaultSessionState.loading() {
    return const VaultSessionState(status: VaultStatus.loading);
  }

  factory VaultSessionState.needsSetup() {
    return const VaultSessionState(status: VaultStatus.needsSetup);
  }

  factory VaultSessionState.locked({String? errorMessage}) {
    return VaultSessionState(
      status: VaultStatus.locked,
      errorMessage: errorMessage,
    );
  }

  factory VaultSessionState.unlocked(VaultData data) {
    return VaultSessionState(status: VaultStatus.unlocked, data: data);
  }

  factory VaultSessionState.error(String message) {
    return VaultSessionState(status: VaultStatus.error, errorMessage: message);
  }
}
