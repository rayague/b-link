abstract class DBInterface {
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 50});
  /// Mark a sync item as being processed to avoid duplicate workers picking it up.
  Future<void> markSyncItemProcessing(int id);
  /// Atomically claim up to [limit] pending sync items for processing.
  /// Returns list of claimed items as maps.
  Future<List<Map<String, dynamic>>> claimPendingSyncItems({int limit = 50});
  Future<void> markSyncItemFailed(int id, String error, {int attempts = 1, Duration? backoff});
  Future<void> markSyncItemPermanentlyFailed(int id, String error);
  Future<void> markSyncItemDone(int id);
  Future<int> enqueueSync(String action, String? uid, String payload);
}
