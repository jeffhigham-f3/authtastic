/// Future contract for passkey-first identity when personal sync is added.
abstract interface class SyncIdentityProvider {
  Future<String?> getCurrentIdentityId();
}
