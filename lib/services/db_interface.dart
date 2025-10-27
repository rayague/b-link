abstract class DBInterface {
  /// Return pending sync items (not yet processed). Each item is a map matching
  /// the database record shape used by the app.
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 50});

  /// Mark a sync item as being processed to avoid duplicate workers picking it up.
  Future<void> markSyncItemProcessing(int id);

  /// Atomically claim up to [limit] pending sync items for processing and return
  /// them as a list of maps. Implementations should ensure items claimed will
  /// not be claimed by other workers.
  Future<List<Map<String, dynamic>>> claimPendingSyncItems({int limit = 50});

  Future<void> markSyncItemFailed(int id, String error, {int attempts = 1, Duration? backoff});
  Future<void> markSyncItemPermanentlyFailed(int id, String error);
  Future<void> markSyncItemDone(int id);

  /// Enqueue a new sync action and return the inserted row id (or similar).
  Future<int> enqueueSync(String action, String? uid, String payload);
}
