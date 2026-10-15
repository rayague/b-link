import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b_link/services/safety_service.dart';

void main() {
  late FakeFirebaseFirestore db;

  SafetyService serviceFor(String uid) => SafetyService(
        firestore: db,
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid)),
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  test('a block follows the account to another device', () async {
    await serviceFor('me').block('stalker', name: 'Stalker');

    // Nouvel appareil : cache local vide, même compte.
    SharedPreferences.setMockInitialValues({});
    expect(await serviceFor('me').blockedUids(), {'stalker'});
  });

  test('blocks made offline (local only) are uploaded on next sync', () async {
    SharedPreferences.setMockInitialValues({
      'blocked_uids': ['old-block'],
    });
    await serviceFor('me').blockedUids();

    final remote = await db.collection('users/me/blocks').get();
    expect(remote.docs.map((d) => d.id), ['old-block']);
  });

  test('unblock removes the profile everywhere', () async {
    final service = serviceFor('me');
    await service.block('a', name: 'A');
    await service.block('b');
    await service.unblock('a');

    expect(await service.blockedUids(), {'b'});
    final profiles = await service.blockedProfiles();
    expect(profiles.map((p) => p.uid), ['b']);
    expect(profiles.single.name, isNull);
  });

  test('blocked names are kept for the list', () async {
    final service = serviceFor('me');
    await service.block('a', name: 'Alice');
    expect((await service.blockedProfiles()).single.name, 'Alice');
  });

  test('logout clears the local cache so the next account starts clean',
      () async {
    await serviceFor('me').block('x');
    await serviceFor('me').clearLocalCache();
    expect(await serviceFor('someone-else').blockedUids(), isEmpty);
  });
}
