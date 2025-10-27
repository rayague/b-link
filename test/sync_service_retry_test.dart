import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/sync_service.dart';
import 'package:b_link/services/db_interface.dart';
import 'package:b_link/services/profile_service.dart';

class FakeDB implements DBInterface {
  final List<Map<String, dynamic>> items = [];

  @override
  Future<int> enqueueSync(String action, String? uid, String payload) async {
    final id = items.length + 1;
    items.add({'id': id, 'action': action, 'uid': uid, 'payload': payload, 'status': 'pending', 'attempts': 0});
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 50}) async {
    return items.where((i) => i['status'] == 'pending').toList();
  }

  @override
  Future<void> markSyncItemDone(int id) async {
    final idx = items.indexWhere((i) => i['id'] == id);
    if (idx >= 0) items[idx]['status'] = 'done';
  }

  @override
  Future<void> markSyncItemFailed(int id, String error, {int attempts = 1, Duration? backoff}) async {
    final idx = items.indexWhere((i) => i['id'] == id);
    if (idx >= 0) {
      items[idx]['attempts'] = attempts;
      items[idx]['lastError'] = error;
    }
  }

  @override
  Future<void> markSyncItemPermanentlyFailed(int id, String error) async {
    final idx = items.indexWhere((i) => i['id'] == id);
    if (idx >= 0) items[idx]['status'] = 'failed';
  }

  @override
  Future<void> markSyncItemProcessing(int id) async {
    final idx = items.indexWhere((i) => i['id'] == id);
    if (idx >= 0) items[idx]['status'] = 'processing';
  }

  @override
  Future<List<Map<String, dynamic>>> claimPendingSyncItems({int limit = 50}) async {
    final pending = items.where((i) => i['status'] == 'pending').take(limit).toList();
    for (final e in pending) {
      e['status'] = 'processing';
    }
    return pending.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class FakeProfileService extends ProfileService {
  bool shouldFail = true;
  int called = 0;
  FakeProfileService() : super(firestore: null);

  @override
  Future<void> pushToFirestore(dynamic profile) async {
    called++;
    if (shouldFail) throw Exception('push failed');
  }
}

void main() {
  // Ensure Flutter bindings are initialized for plugins (SharedPreferences, etc.)
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SyncService retries and marks done on success', () async {
    final db = FakeDB();
  final payload = '{"name":"Test","birthDate":"2000-01-01T00:00:00.000"}';
  db.items.add({'id': 1, 'action': 'upsert_profile', 'uid': 'u1', 'payload': payload, 'status': 'pending', 'attempts': 0});
    final fakeProfile = FakeProfileService();
    final svc = SyncService(db: db, profileService: fakeProfile);

    // First run: should attempt and fail
    await svc.processPending(limit: 10);
    expect(db.items.first['attempts'] >= 1, true);

    // Make it succeed and run again
    fakeProfile.shouldFail = false;
    await svc.processPending(limit: 10);
    expect(db.items.first['status'], 'done');
  });
}
