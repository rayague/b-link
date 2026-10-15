import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/moderation_service.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ModerationService service;

  Future<void> report(String reporter, String reported, String reason) =>
      db.collection('reports').add({
        'reporterUid': reporter,
        'reportedUid': reported,
        'reason': reason,
        'createdAt': Timestamp.now(),
      });

  setUp(() async {
    db = FakeFirebaseFirestore();
    service = ModerationService(
      firestore: db,
      auth: MockFirebaseAuth(
          signedIn: true, mockUser: MockUser(uid: 'admin-1')),
    );
    await db.collection('users').doc('spammer').set({'name': 'Spam Bot'});
    await db
        .collection('public_profiles')
        .doc('spammer')
        .set({'uid': 'spammer', 'birthDayKey': '10-15', 'isPublic': true});
    await report('a', 'spammer', 'spam');
    await report('b', 'spammer', 'spam');
    await report('b', 'spammer', 'fake'); // même auteur : compté une fois
    await report('c', 'other', 'inappropriate');
  });

  test('groups reports by profile, most reported first', () async {
    final groups = await service.reportGroups();
    expect(groups.map((g) => g.reportedUid), ['spammer', 'other']);
    final spammer = groups.first;
    expect(spammer.displayName, 'Spam Bot');
    expect(spammer.reporterCount, 2);
    expect(spammer.reasons, {'spam': 2, 'fake': 1});
    expect(spammer.hidden, isNull);
  });

  test('hide removes the profile from the directory and records the decision',
      () async {
    await service.hide('spammer');

    final pub = await db.collection('public_profiles').doc('spammer').get();
    expect(pub.exists, isFalse);
    final mod = await db.collection('moderation').doc('spammer').get();
    expect(mod.data()?['hidden'], isTrue);
    expect(mod.data()?['decidedBy'], 'admin-1');
  });

  test('restore keeps a decision (no automatic re-hiding) and clears reports',
      () async {
    await service.hide('spammer');
    await service.restore('spammer');

    final mod = await db.collection('moderation').doc('spammer').get();
    expect(mod.data()?['hidden'], isFalse);
    final groups = await service.reportGroups();
    expect(groups.map((g) => g.reportedUid), ['other']);
  });

  test('dismissing reports does not change visibility', () async {
    await service.dismissReports('spammer');

    final pub = await db.collection('public_profiles').doc('spammer').get();
    expect(pub.exists, isTrue);
    final mod = await db.collection('moderation').doc('spammer').get();
    expect(mod.exists, isFalse);
  });
}
