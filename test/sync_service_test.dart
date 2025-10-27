import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/sync_service.dart';
import 'package:b_link/services/db_interface.dart';
import 'package:b_link/services/profile_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:b_link/models/user_profile.dart';

class FakeDB implements DBInterface {
  final List<Map<String, dynamic>> _items = [];
  final List<int> done = [];
  final List<int> permFailed = [];
  final List<int> failed = [];

  FakeDB(List<Map<String, dynamic>> initial) {
    _items.addAll(initial);
  }

  @override
  Future<int> enqueueSync(String action, String? uid, String payload) async {
    final id = _items.length + 1;
    _items.add({'id': id, 'action': action, 'uid': uid, 'payload': payload, 'status': 'pending', 'attempts': 0, 'createdAt': DateTime.now().toIso8601String()});
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 50}) async {
    // return items with status pending (ignore nextRetryAt semantics for test simplicity)
    return _items.where((e) => (e['status'] as String?) == 'pending').take(limit).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> markSyncItemDone(int id) async {
    done.add(id);
    final idx = _items.indexWhere((e) => e['id'] == id);
    if (idx != -1) _items[idx]['status'] = 'done';
  }

  @override
  Future<void> markSyncItemFailed(int id, String error, {int attempts = 1, Duration? backoff}) async {
    failed.add(id);
    final idx = _items.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _items[idx]['attempts'] = attempts;
      _items[idx]['lastError'] = error;
    }
  }

  @override
  Future<void> markSyncItemProcessing(int id) async {
    final idx = _items.indexWhere((e) => e['id'] == id);
    if (idx != -1) _items[idx]['status'] = 'processing';
  }

  @override
  Future<List<Map<String, dynamic>>> claimPendingSyncItems({int limit = 50}) async {
    final pending = _items.where((e) => (e['status'] as String?) == 'pending').take(limit).toList();
    for (final e in pending) {
      e['status'] = 'processing';
    }
    return pending.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> markSyncItemPermanentlyFailed(int id, String error) async {
    permFailed.add(id);
    final idx = _items.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _items[idx]['status'] = 'failed';
      _items[idx]['lastError'] = error;
    }
  }
}

class FlakyProfileService extends ProfileService {
  final int failTimes;
  int _called = 0;
  bool get succeededOnce => _called > failTimes;

  FlakyProfileService({this.failTimes = 0}) : super(firestore: null);

  @override
  Future<void> pushToFirestore(UserProfile profile) async {
    _called++;
    if (_called <= failTimes) {
      throw Exception('simulated transient error');
    }
    // succeed (no-op)
    return;
  }
}

void main() {
  test('processPending - happy path marks done', () async {
    final profile = UserProfile(uid: 'u1', name: 'A', birthDate: DateTime(1990,1,1));
    final payload = json.encode(profile.toJson());
    final fakeDb = FakeDB([{'id': 1, 'action': 'upsert_profile', 'uid': 'u1', 'payload': payload, 'status': 'pending', 'attempts': 0, 'createdAt': DateTime.now().toIso8601String()}]);
    final svc = SyncService(db: fakeDb, profileService: FlakyProfileService(failTimes: 0));
    final processed = await svc.processPending(limit: 10, maxAttempts: 3);
    expect(processed, 1);
    expect(fakeDb.done, contains(1));
  });

  test('processPending retries then succeeds', () async {
    final profile = UserProfile(uid: 'u2', name: 'B', birthDate: DateTime(1992,2,2));
    final payload = json.encode(profile.toJson());
    final fakeDb = FakeDB([{'id': 2, 'action': 'upsert_profile', 'uid': 'u2', 'payload': payload, 'status': 'pending', 'attempts': 0, 'createdAt': DateTime.now().toIso8601String()}]);
    // fail once then succeed
    final flaky = FlakyProfileService(failTimes: 1);
    final svc = SyncService(db: fakeDb, profileService: flaky);

    // first run: should record a failed attempt
    final first = await svc.processPending(limit: 10, maxAttempts: 3);
    expect(first, 0); // not processed yet (not done nor perm failed)
    expect(fakeDb.failed, contains(2));

    // second run: should succeed
    final second = await svc.processPending(limit: 10, maxAttempts: 3);
    expect(second, 1);
    expect(fakeDb.done, contains(2));
  });

  test('processPending marks permanently failed after max attempts', () async {
    final profile = UserProfile(uid: 'u3', name: 'C', birthDate: DateTime(1988,3,3));
    final payload = json.encode(profile.toJson());
    final fakeDb = FakeDB([{'id': 3, 'action': 'upsert_profile', 'uid': 'u3', 'payload': payload, 'status': 'pending', 'attempts': 0, 'createdAt': DateTime.now().toIso8601String()}]);
    // always fail
    final flaky = FlakyProfileService(failTimes: 100);
    final svc = SyncService(db: fakeDb, profileService: flaky);

    // run with maxAttempts = 2: should mark permanently failed after 2 attempts
    final first = await svc.processPending(limit: 10, maxAttempts: 2);
    expect(first, 0);
    expect(fakeDb.failed, contains(3));

    final second = await svc.processPending(limit: 10, maxAttempts: 2);
    // processed should count permanent failed as processed
    expect(second, 1);
    expect(fakeDb.permFailed, contains(3));
  });
}
