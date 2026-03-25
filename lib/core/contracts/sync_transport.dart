/// Future contract for encrypted delta push/pull.
abstract interface class SyncTransport {
  Future<void> pushChanges({
    required String identityId,
    required List<Map<String, dynamic>> changes,
  });

  Future<List<Map<String, dynamic>>> pullChanges({
    required String identityId,
    required String cursor,
  });
}
