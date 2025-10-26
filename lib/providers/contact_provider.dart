import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/db_helper.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class ContactProvider extends ChangeNotifier {
  final dynamic _db;
  List<Contact> _contacts = [];
  bool _loading = false;

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;

  final dynamic _notif;

  // Normal constructor
  ContactProvider({DBHelper? db, NotificationService? notif}) : _db = db ?? DBHelper(), _notif = notif ?? NotificationService();

  // Test-friendly constructor that accepts dynamic (fake) dependencies to avoid type issues in tests
  ContactProvider.test({dynamic db, dynamic notif}) : _db = db ?? DBHelper(), _notif = notif ?? NotificationService();

  Future<void> loadContacts() async {
    _loading = true;
    notifyListeners();
    await _db.ensurePhoneColumn();
    try {
      final imported = await _db.importMessagesIfEmpty();
      if (imported > 0) {
        // ignore: avoid_print
        print('Imported $imported messages into local database');
      }
    } catch (_) {
      // some test fakes may not implement importMessagesIfEmpty; ignore
    }
  await _notif.init();
    _contacts = await _db.getContacts();
    // schedule daily reminders (static ids 1001,1002,1003)
  await _notif.scheduleDaily(1001, 'Birthgram', 'Morning reminders for birthdays', 9, 0);
  await _notif.scheduleDaily(1002, 'Birthgram', 'Midday reminders for birthdays', 13, 0);
  await _notif.scheduleDaily(1003, 'Birthgram', 'Evening reminders for birthdays', 18, 0);
    // schedule specific birthday notifications for existing contacts (id offset by 10000)
    for (final c in _contacts) {
      _scheduleBirthdayForContact(c);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addContact(Contact c) async {
    await _db.insertContact(c);
    await loadContacts();
    _scheduleBirthdayForContact(c);
  }

  Future<void> updateContact(Contact c) async {
    await _db.updateContact(c);
    await loadContacts();
    await _notif.cancel(10000 + (c.id ?? 0));
    _scheduleBirthdayForContact(c);
  }

  Future<void> deleteContact(int id) async {
    await _db.deleteContact(id);
    await loadContacts();
    await _notif.cancel(10000 + id);
  }

  void _scheduleBirthdayForContact(Contact c) {
    try {
      final d = DateTime.parse(c.date);
      final now = DateTime.now();
      var next = DateTime(now.year, d.month, d.day, 9);
      if (next.isBefore(now)) next = DateTime(now.year + 1, d.month, d.day, 9);
      final tzDate = tz.TZDateTime.from(next, tz.local);
  _notif.scheduleSpecificDate(10000 + (c.id ?? 0), 'Birthday: ${c.name}', 'Today is ${c.name} birthday', tzDate);
    } catch (_) {}
  }

  List<Contact> upcoming(int days) {
    final now = DateTime.now();
    return _contacts.where((c) {
      try {
        final d = DateTime.parse(c.date);
        final next = DateTime(now.year, d.month, d.day);
        final diff = next.difference(now).inDays;
        return diff >= 0 && diff <= days;
      } catch (_) {
        return false;
      }
    }).toList();
  }
}
