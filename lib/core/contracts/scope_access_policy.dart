/// Future contract for personal/shared scope permission checks.
abstract interface class ScopeAccessPolicy {
  bool canRead({
    required String identityId,
    required String scopeType,
    String? scopeId,
  });

  bool canWrite({
    required String identityId,
    required String scopeType,
    String? scopeId,
  });
}
