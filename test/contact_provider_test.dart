import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/providers/contact_provider.dart';
import 'package:b_link/models/contact.dart';

class FakeDB {
  final List<Map<String,dynamic>> _rows = [];
  Future<void> ensurePhoneColumn() async {}
  Future<List<Contact>> getContacts() async => _rows.map((r) => Contact.fromMap(r)).toList();
  Future<int> insertContact(Contact c) async {
    final id = _rows.length + 1;
    _rows.add({...c.toMap(), 'id': id});
    return id;
  }
  Future<int> updateContact(Contact c) async {
    final idx = _rows.indexWhere((r) => r['id'] == c.id);
    if (idx >= 0) _rows[idx] = c.toMap();
    return 1;
  }
  Future<int> deleteContact(int id) async {
    _rows.removeWhere((r) => r['id'] == id);
    return 1;
  }
}

class FakeNotif {
  final List<int> scheduled = [];
  Future<void> init() async {}
  Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async { scheduled.add(id); }
  Future<void> scheduleSpecificDate(int id, String title, String body, dynamic dateTime) async { scheduled.add(id); }
  Future<void> cancel(int id) async { scheduled.remove(id); }
  Future<void> scheduleBirthdayReminders(dynamic contact, String locale) async {
    if (contact.id != null) {
      scheduled.add(contact.id);
    }
  }
  Future<void> cancelBirthdayReminders(int contactId) async {
    scheduled.remove(contactId);
  }
  Future<void> cancelAll() async => scheduled.clear();
  Future<void> rescheduleAllReminders(List<Contact> contacts, String locale) async {
    await cancelAll();
    for (final c in contacts) {
      await scheduleBirthdayReminders(c, locale);
    }
  }
}

/// Simule le plugin qui rejette un ID de notification hors 32 bits.
class ThrowingNotif extends FakeNotif {
  @override
  Future<void> scheduleBirthdayReminders(dynamic contact, String locale) async {
    throw ArgumentError('id must fit within the size of a 32-bit integer');
  }
}

/// Enregistre les contacts tels qu'ils sont passés à la programmation.
class RecordingNotif extends FakeNotif {
  final List<int?> ids = [];
  @override
  Future<void> scheduleBirthdayReminders(dynamic contact, String locale) async {
    ids.add(contact.id);
  }
}

void main() {
  test('a reminder failure never leaves the loading overlay stuck', () async {
    final fakeDb = FakeDB();
    await fakeDb.insertContact(
        Contact(name: 'Bob', date: '1990-05-01', relation: 'friend'));
    final provider = ContactProvider.test(db: fakeDb, notif: ThrowingNotif());

    await provider.loadContacts();

    expect(provider.loading, isFalse);
    expect(provider.contacts.length, 1);
  });

  test('loading contacts reschedules reminders for every contact', () async {
    final fakeDb = FakeDB();
    await fakeDb.insertContact(
        Contact(name: 'Bob', date: '1990-05-01', relation: 'friend'));
    await fakeDb.insertContact(
        Contact(name: 'Eve', date: '1991-06-02', relation: 'friend'));
    final notif = FakeNotif()..scheduled.add(42); // rappel obsolète
    final provider = ContactProvider.test(db: fakeDb, notif: notif);

    await provider.loadContacts();

    expect(notif.scheduled, unorderedEquals([1, 2]));
  });

  test('addContact schedules reminders with the id assigned by the DB',
      () async {
    final notif = RecordingNotif();
    final provider = ContactProvider.test(db: FakeDB(), notif: notif);

    await provider.addContact(
        Contact(name: 'Alice', date: '2000-10-22', relation: 'friend'));

    // Le premier appel est celui d'addContact : il doit déjà avoir l'ID.
    expect(notif.ids.first, 1);
  });

  test('ContactProvider add/update/delete schedules notifications', () async {
    final fakeDb = FakeDB();
    final fakeNotif = FakeNotif();
  final provider = ContactProvider.test(db: fakeDb, notif: fakeNotif);

    await provider.loadContacts();
    expect(provider.contacts.length, 0);

    final c = Contact(name: 'Alice', date: '2000-10-22', relation: 'FRIEND', phone: '123');
    await provider.addContact(c);
    expect(provider.contacts.length, 1);

    final added = provider.contacts.first;
    final updated = Contact(id: added.id, name: 'Alice2', date: added.date, relation: added.relation, phone: added.phone);
    await provider.updateContact(updated);
    expect(provider.contacts.first.name, 'Alice2');

    await provider.deleteContact(added.id!);
    expect(provider.contacts.length, 0);
  });
}
