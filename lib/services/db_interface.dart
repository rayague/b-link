abstract class DBInterface {
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 50});
  Future<void> markSyncItemFailed(int id, String error, {int attempts = 1, Duration? backoff});
  Future<void> markSyncItemPermanentlyFailed(int id, String error);
  Future<void> markSyncItemDone(int id);
  Future<int> enqueueSync(String action, String? uid, String payload);
}
