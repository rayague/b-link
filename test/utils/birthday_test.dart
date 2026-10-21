import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/models/contact.dart';
import 'package:b_link/providers/contact_provider.dart';
import 'package:b_link/services/notification_service.dart';
import 'package:b_link/utils/birthday.dart';
import 'package:b_link/services/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    ReminderSettings only(Set<int> offsets, {int hour = 9, int minute = 0}) =>
        ReminderSettings(hour: hour, minute: minute, offsets: offsets);

    test('by default: the day before and the day itself at 9:00', () {
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

    test('every offset can be chosen, earliest first', () {
      final plan = NotificationService.planFor(contact('1990-11-20'),
          DateTime(2026, 10, 15), only({0, 1, 2, 3, 7, 14, 30}));
      expect(plan.map((r) => r.daysBefore), [30, 14, 7, 3, 2, 1, 0]);
      expect(plan.first.when, DateTime(2026, 10, 21, 9));
    });

    test('a month-before reminder is planned even 40 days ahead', () {
      // L'anniversaire est hors de l'ancienne fenêtre de 30 jours, mais son
      // rappel « un mois avant » tombe dans 10 jours : ses rappels sont
      // programmés ensemble, jour J compris.
      final plan = NotificationService.planFor(
          contact('1990-11-24'), DateTime(2026, 10, 15), only({30, 0}));
      expect(plan.map((r) => r.when),
          [DateTime(2026, 10, 25, 9), DateTime(2026, 11, 24, 9)]);
    });

    test('nothing when the reminder is still far away', () {
      expect(
          NotificationService.planFor(contact('1990-12-25'), DateTime(2026, 10, 15)),
          isEmpty);
    });

    test('nothing when no reminder is selected', () {
      expect(
          NotificationService.planFor(
              contact('1990-10-20'), DateTime(2026, 10, 15), only({})),
          isEmpty);
    });

    test('nothing for a contact without id or with an invalid date', () {
      final now = DateTime(2026, 10, 15);
      expect(NotificationService.planFor(contact('1990-10-20', id: null), now), isEmpty);
      expect(NotificationService.planFor(contact('pas-une-date'), now), isEmpty);
    });

    test('notification ids fit in 32 bits and never collide', () {
      for (final id in [1, 99999, 1728912345678]) {
        for (final o in kReminderOffsets) {
          expect(NotificationService.notificationId(id, o),
              inInclusiveRange(0, 0x7FFFFFFF));
        }
      }
      final ids = kReminderOffsets
          .map((o) => NotificationService.notificationId(5, o))
          .toSet();
      expect(ids.length, kReminderOffsets.length);
      expect(() => NotificationService.notificationId(5, 4), throwsArgumentError);
    });

    test('ids of existing reminders are unchanged (day 0, eve 1, week 2)', () {
      expect(NotificationService.notificationId(5, 0), 50);
      expect(NotificationService.notificationId(5, 1), 51);
      expect(NotificationService.notificationId(5, 7), 52);
    });

    test('reminders use the chosen time', () {
      final plan = NotificationService.planFor(contact('1990-10-20'),
          DateTime(2026, 10, 15), only({0, 1}, hour: 20, minute: 30));
      expect(plan.last.when, DateTime(2026, 10, 20, 20, 30));
    });

    test('planAll keeps the nearest reminders within the limit', () {
      final contacts = [
        for (var i = 0; i < 40; i++)
          Contact(
              id: i + 1,
              name: 'C$i',
              date: '1990-11-${(i % 28 + 1).toString().padLeft(2, '0')}',
              relation: 'friend'),
      ];
      final all = NotificationService.planAll(
          contacts, DateTime(2026, 10, 15), only({0, 1, 7}));
      final capped = NotificationService.planAll(
          contacts, DateTime(2026, 10, 15), only({0, 1, 7}), limit: 60);
      expect(all.length, greaterThan(60));
      expect(capped.length, 60);
      expect(capped.last.when.isAfter(all.first.when), isTrue);
      for (var i = 1; i < capped.length; i++) {
        expect(capped[i].when.isBefore(capped[i - 1].when), isFalse);
      }
    });

    test('every offset has its own notification text, in both languages', () {
      for (final o in kReminderOffsets) {
        for (final lang in ['fr', 'en']) {
          final text = NotificationService.reminderText('Léa', o, lang);
          expect(text.title, contains('Léa'));
          expect(text.body, isNotEmpty);
        }
      }
      expect(NotificationService.reminderText('Léa', 3, 'fr').title,
          contains('Dans 3 jours'));
    });

    test('settings are remembered', () async {
      SharedPreferences.setMockInitialValues({});
      await const ReminderSettings(hour: 7, minute: 15, offsets: {0, 14})
          .save();
      final loaded = await ReminderSettings.load();
      expect(loaded.hour, 7);
      expect(loaded.minute, 15);
      expect(loaded.offsets, {0, 14});
    });

    test('old settings are migrated (day before off, week before on)', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_day_before': false,
        'reminder_week_before': true,
      });
      final loaded = await ReminderSettings.load();
      expect(loaded.offsets, {0, 7});
    });

    test('unknown saved values are ignored', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_offsets': ['1', '5', 'x', '30'],
      });
      expect((await ReminderSettings.load()).offsets, {1, 30});
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
