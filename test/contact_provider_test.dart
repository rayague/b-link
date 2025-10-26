import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/providers/contact_provider.dart';
import 'package:b_link/models/contact.dart';
import 'dart:async';

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
}

void main() {
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
