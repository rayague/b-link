import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'db_interface.dart';
import 'db_helper.dart';
import 'profile_service.dart';
import '../models/user_profile.dart';

/// SyncService processes items stored in the local `sync_queue` table and
/// reliably pushes them to the cloud. It is dependency-injectable for tests.
class SyncService {
  final DBInterface _db;
  final ProfileService _profileService;

  SyncService({DBInterface? db, ProfileService? profileService})
      : _db = db ?? DBHelper(),
        _profileService = profileService ?? ProfileService(firestore: null);

  /// Compute backoff duration for a given attempt count.
  /// Uses exponential backoff with jitter and caps at 24h.
  Duration _computeBackoff(int attempt) {
    final clamped = attempt.clamp(0, 30);
    // base backoff in seconds: 2^(attempt) with a minimum of 1s
    final base = pow(2, clamped).toInt();
    final capped = base > 86400 ? 86400 : (base < 1 ? 1 : base);
    // jitter in 85%..115% to avoid thundering herd
    final jitter = 0.85 + (Random().nextDouble() * 0.3);
    final seconds = (capped * jitter).round();
    return Duration(seconds: seconds);
  }

  /// Process up to [limit] pending items once. Items are processed in FIFO order.
  /// On transient errors items are retried with exponential backoff. After
  /// [maxAttempts] the item is marked permanently failed.
  /// Process up to [limit] pending items once.
  /// Returns number of items processed (succeeded or permanently failed).
  Future<int> processPending({int limit = 50, int maxAttempts = 8}) async {
    final items = await _db.claimPendingSyncItems(limit: limit);
    if (items.isEmpty) return 0;
    var processed = 0;
    for (final item in items) {
      final id = item['id'] as int;
      final action = item['action'] as String? ?? '';
      final uid = item['uid'] as String?;
      final payload = item['payload'] as String? ?? '';
      final attempts = (item['attempts'] as int?) ?? 0;

      try {
        if (action == 'upsert_profile') {
          final Map<String, dynamic> jsonMap = jsonDecode(payload) as Map<String, dynamic>;
          final profile = UserProfile.fromJson(jsonMap);
          if ((profile.uid == null || profile.uid!.isEmpty) && uid != null && uid.isNotEmpty) {
            profile.uid = uid;
          }
          if (kDebugMode) debugPrint('SyncService: pushing profile uid=${profile.uid}');
          await _profileService.pushToFirestore(profile);
          await _db.markSyncItemDone(id);
          processed++;
        } else {
          // Unknown action: mark done to avoid endless retries.
          if (kDebugMode) debugPrint('SyncService: unknown action [$action] id=$id — marking done');
          await _db.markSyncItemDone(id);
          processed++;
        }
      } catch (e, st) {
        // Transient failure handling
        final nextAttempts = attempts + 1;
        if (kDebugMode) {
          debugPrint('SyncService: item $id action=$action failed attempt=$nextAttempts error=$e');
          debugPrint('$st');
        }
        // classify permanent vs transient
        final errStr = e?.toString() ?? '';
        final isPermanent = _isPermanentError(errStr);
        if (isPermanent || nextAttempts >= maxAttempts) {
          await _db.markSyncItemPermanentlyFailed(id, errStr);
          processed++;
        } else {
          final backoff = _computeBackoff(nextAttempts);
          await _db.markSyncItemFailed(id, errStr, attempts: nextAttempts, backoff: backoff);
        }
        // continue with next item
        continue;
      }
    }
    return processed;
  }

  /// Heuristic to determine if an error should be treated as permanent.
  /// Looks for common permission/configuration issues which retries won't fix.
  bool _isPermanentError(String err) {
    final lower = err.toLowerCase();
    if (lower.contains('permission_denied') || lower.contains('missing or insufficient permissions') || lower.contains('configuration_not_found')) return true;
    if (lower.contains('unauthorized') || lower.contains('forbidden') || lower.contains('not found')) return true;
    // network/timeouts should be retried
    return false;
  }
}

