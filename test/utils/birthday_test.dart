import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/models/contact.dart';
import 'package:b_link/providers/contact_provider.dart';
import 'package:b_link/services/notification_service.dart';
import 'package:b_link/utils/birthday.dart';

void main() {
  group('daysUntilBirthday', () {
    test('today is 0, even late in the day', () {
      expect(daysUntilBirthday(DateTime(1990, 10, 15), DateTime(2026, 10, 15, 23, 59)), 0);
    });

    test('wraps around the new year (old bug: early January was missed)', () {
      expect(daysUntilBirthday(DateTime(1990, 1, 2), DateTime(2026, 12, 30)), 3);
    });

    test('a past birthday this year counts until next year', () {
      expect(daysUntilBirthday(DateTime(1990, 10, 14), DateTime(2026, 10, 15)), 364);
    });

    test('Feb 29 is celebrated on Feb 28 in non-leap years', () {
      expect(nextBirthday(DateTime(2000, 2, 29), DateTime(2026, 2, 1)), DateTime(2026, 2, 28));
      expect(nextBirthday(DateTime(2000, 2, 29), DateTime(2028, 2, 1)), DateTime(2028, 2, 29));
    });

    test('is not shifted by a daylight-saving change', () {
      // Passage à l'heure d'hiver fin octobre en Europe.
      expect(daysUntilBirthday(DateTime(1990, 11, 1), DateTime(2026, 10, 20)), 12);
    });
  });

  group('NotificationService.planFor', () {
    Contact contact(String date, {int? id = 7}) =>
        Contact(id: id, name: 'Alice', date: date, relation: 'friend');

    test('plans the day before and the day itself at 9:00', () {
      final plan = NotificationService.planFor(
          contact('1990-10-20'), DateTime(2026, 10, 15, 12));
      expect(plan.map((r) => r.when), [
        DateTime(2026, 10, 19, 9),
        DateTime(2026, 10, 20, 9),
      ]);
      expect(plan.map((r) => r.isBirthdayDay), [false, true]);
    });

    test('skips reminders already in the past', () {
      final plan = NotificationService.planFor(
          contact('1990-10-15'), DateTime(2026, 10, 15, 8));
      expect(plan.length, 1);
      expect(plan.single.when, DateTime(2026, 10, 15, 9));
    });

    test('day-before reminder crosses month and year boundaries', () {
      final plan = NotificationService.planFor(
          contact('1990-01-01'), DateTime(2026, 12, 20));
      expect(plan.first.when, DateTime(2026, 12, 31, 9));
    });

    test('nothing outside the 30-day window', () {
      expect(
          NotificationService.planFor(contact('1990-12-25'), DateTime(2026, 10, 15)),
          isEmpty);
    });

    test('nothing for a contact without id or with an invalid date', () {
      final now = DateTime(2026, 10, 15);
      expect(NotificationService.planFor(contact('1990-10-20', id: null), now), isEmpty);
      expect(NotificationService.planFor(contact('pas-une-date'), now), isEmpty);
    });

    test('notification ids fit in 32 bits, even for timestamp-like ids', () {
      for (final id in [1, 99999, 1728912345678]) {
        for (final day in [true, false]) {
          final n = NotificationService.notificationId(id, isBirthdayDay: day);
          expect(n, inInclusiveRange(0, 0x7FFFFFFF));
        }
      }
      expect(NotificationService.notificationId(5, isBirthdayDay: true),
          isNot(NotificationService.notificationId(5, isBirthdayDay: false)));
    });
  });

  test('ContactProvider.upcoming sorts by closeness and wraps the year', () async {
    final provider = ContactProvider.test(db: _MemoryDb([
      Contact(id: 1, name: 'Late', date: '1990-01-03', relation: 'friend'),
      Contact(id: 2, name: 'Soon', date: '1990-12-31', relation: 'friend'),
      Contact(id: 3, name: 'Far', date: '1990-06-01', relation: 'friend'),
    ]), notif: _NoopNotif());
    await provider.loadContacts(syncWithFirebase: false);

    final names = provider.upcoming(7, now: DateTime(2026, 12, 30)).map((c) => c.name);
    expect(names, ['Soon', 'Late']);
  });
}

class _MemoryDb {
  final List<Contact> rows;
  _MemoryDb(this.rows);
  Future<void> ensurePhoneColumn() async {}
  Future<int> importMessagesIfEmpty() async => 0;
  Future<List<Contact>> getContacts() async => rows;
}

class _NoopNotif {
  Future<void> init() async {}
  Future<void> rescheduleAllReminders(List<Contact> c, String l) async {}
}
