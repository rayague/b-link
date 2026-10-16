import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/meetup_service.dart';

void main() {
  late FakeFirebaseFirestore db;
  MeetupService serviceFor(String uid) => MeetupService(
        firestore: db,
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid)),
      );
  final now = DateTime(2026, 10, 16, 12);

  setUp(() => db = FakeFirebaseFirestore());

  Future<String> create(String uid,
          {String city = 'FR:lyon',
          String day = '10-14',
          DateTime? at,
          int max = 3}) =>
      serviceFor(uid).create(
        title: 'Apéro des jumeaux',
        description: '',
        placeHint: 'Café de la Gare',
        birthDayKey: day,
        cityKey: city,
        startsAt: at ?? now.add(const Duration(days: 3)),
        maxAttendees: max,
      );

  test('upcoming: same day and city, future only, soonest first', () async {
    final later = await create('a', at: now.add(const Duration(days: 9)));
    final sooner = await create('b', at: now.add(const Duration(days: 2)));
    await create('c', at: now.subtract(const Duration(days: 1))); // passée
    await create('d', city: 'FR:paris');
    await create('e', day: '03-02');

    final list = await serviceFor('x')
        .upcoming(birthDayKey: '10-14', cityKey: 'FR:lyon', now: now);
    expect(list.map((m) => m.id), [sooner, later]);
  });

  test('cancelled meetups are hidden', () async {
    final id = await create('a');
    await serviceFor('a').cancel(id);
    final list = await serviceFor('x')
        .upcoming(birthDayKey: '10-14', cityKey: 'FR:lyon', now: now);
    expect(list, isEmpty);
  });

  test('join and leave keep the counter consistent', () async {
    final id = await create('a', max: 2);
    await serviceFor('b').join(id, publicName: 'Bob');
    await serviceFor('c').join(id);

    var m = (await serviceFor('x').get(id))!;
    expect(m.attendeeCount, 2);
    expect(m.isFull, isTrue);
    expect(await serviceFor('b').isAttending(id), isTrue);
    final names = (await serviceFor('x').attendees(id)).map((a) => a.name);
    expect(names, containsAll(['Bob', null]));

    await serviceFor('b').leave(id);
    m = (await serviceFor('x').get(id))!;
    expect(m.attendeeCount, 1);
    expect(await serviceFor('b').isAttending(id), isFalse);
  });

  test('a meetup stores exactly the fields allowed by the rules', () async {
    final id = await create('a');
    final data = (await db.collection('events').doc(id).get()).data()!;
    expect(data.keys.toSet(), {
      'creatorUid', 'creatorName', 'title', 'description', 'placeHint',
      'birthDayKey', 'cityKey', 'startsAt', 'maxAttendees', 'attendeeCount',
      'cancelled', 'createdAt',
    });
    expect(data['startsAt'], isA<Timestamp>());
  });
}
