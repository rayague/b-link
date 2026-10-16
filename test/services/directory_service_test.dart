import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/directory_service.dart';

void main() {
  group('weekKeys', () {
    test('7 days centred on the birthday', () {
      expect(DirectoryService.weekKeys(DateTime(1990, 10, 15)), [
        '10-12', '10-13', '10-14', '10-15', '10-16', '10-17', '10-18',
      ]);
    });

    test('wraps around the new year', () {
      expect(DirectoryService.weekKeys(DateTime(1990, 12, 30)), [
        '12-27', '12-28', '12-29', '12-30', '12-31', '01-01', '01-02',
      ]);
    });

    test('Feb 29 is a neighbour of Feb 28 and Mar 1', () {
      expect(DirectoryService.weekKeys(DateTime(1991, 3, 1)),
          contains('02-29'));
      expect(DirectoryService.weekKeys(DateTime(2000, 2, 29)),
          containsAll(['02-28', '03-01']));
    });
  });

  group('query', () {
    late FakeFirebaseFirestore db;
    late DirectoryService service;

    Future<void> add(String uid, String dayKey, [String? country]) =>
        db.collection('public_profiles').doc(uid).set({
          'uid': uid,
          'birthDayKey': dayKey,
          'isPublic': true,
          if (country != null) 'countryCode': country,
        });

    Future<List<String>> uids(DirectoryPeriod period, {String? country}) async {
      final snap = await service
          .query(DateTime(1990, 10, 15), period, countryCode: country)
          .get();
      return snap.docs.map((d) => d.id).toList()..sort();
    }

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = DirectoryService(firestore: db);
      await add('same-day-fr', '10-15', 'FR');
      await add('same-day-ci', '10-15', 'CI');
      await add('two-days-later', '10-17', 'FR');
      await add('same-month', '10-02', 'FR');
      await add('other-month', '11-15', 'FR');
    });

    test('day: exact birthday only', () async {
      expect(await uids(DirectoryPeriod.day), ['same-day-ci', 'same-day-fr']);
    });

    test('week: +/- 3 days', () async {
      expect(await uids(DirectoryPeriod.week),
          ['same-day-ci', 'same-day-fr', 'two-days-later']);
    });

    test('month: whole month, nothing from the next one', () async {
      expect(await uids(DirectoryPeriod.month),
          ['same-day-ci', 'same-day-fr', 'same-month', 'two-days-later']);
    });

    test('country filter combines with the period', () async {
      expect(await uids(DirectoryPeriod.day, country: 'CI'), ['same-day-ci']);
      expect(await uids(DirectoryPeriod.month, country: 'FR'),
          ['same-day-fr', 'same-month', 'two-days-later']);
    });
  });
}
