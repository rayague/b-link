import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/db_helper.dart';
import '../services/notification_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/analytics_service.dart';

class ContactProvider extends ChangeNotifier {
  final dynamic _db;
  final FirebaseSyncService? _firebaseSync;
  List<Contact> _contacts = [];
  bool _loading = false;
  bool _syncing = false;

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;
  bool get syncing => _syncing;

  final dynamic _notif;

  // Normal constructor
  ContactProvider(
      {DBHelper? db,
      NotificationService? notif,
      FirebaseSyncService? firebaseSync})
      : _db = db ?? DBHelper(),
        _notif = notif ?? NotificationService(),
        _firebaseSync = firebaseSync ?? FirebaseSyncService(db ?? DBHelper());

  // Test-friendly constructor that accepts dynamic (fake) dependencies to avoid type issues in tests
  ContactProvider.test({dynamic db, dynamic notif})
      : _db = db ?? DBHelper(),
        _notif = notif ?? NotificationService(),
        _firebaseSync = null;

  Future<void> loadContacts(
      {String locale = 'fr', bool syncWithFirebase = true}) async {
    _loading = true;
    notifyListeners();
    await _db.ensurePhoneColumn();
    try {
      final imported = await _db.importMessagesIfEmpty();
      if (imported > 0) {
        print('Imported $imported messages into local database');
      }
    } catch (_) {}

    await _notif.init();
    _contacts = await _db.getContacts();

    // Synchroniser avec Firebase si connecté
    if (syncWithFirebase &&
        _firebaseSync != null &&
        _firebaseSync!.isUserAuthenticated) {
      await _syncWithFirebase();
    }

    // Schedule birthday reminders for all contacts
    for (final c in _contacts) {
      await _notif.scheduleBirthdayReminders(c, locale);
    }

    _loading = false;
    notifyListeners();
  }

  /// Synchronisation intelligente avec Firebase
  Future<void> _syncWithFirebase() async {
    if (_firebaseSync == null || !_firebaseSync!.isUserAuthenticated) return;

    _syncing = true;
    notifyListeners();

    try {
      print('🔄 Synchronisation avec Firebase...');

      // Récupérer les contacts depuis Firebase
      final firebaseContacts = await _firebaseSync!.getAllContacts();

      // Fusionner avec les contacts locaux
      final localIds = _contacts.map((c) => c.id).toSet();
      final firebaseIds = firebaseContacts.map((c) => c.id).toSet();

      // Contacts uniquement sur Firebase → ajouter en local
      for (final contact in firebaseContacts) {
        if (!localIds.contains(contact.id)) {
          await _db.insertContact(contact);
          _contacts.add(contact);
        }
      }

      // Contacts uniquement en local → envoyer à Firebase
      for (final contact in _contacts) {
        if (!firebaseIds.contains(contact.id)) {
          await _firebaseSync!.saveContact(contact);
        }
      }

      print('✅ Synchronisation Firebase terminée');
    } catch (e) {
      print('❌ Erreur synchronisation Firebase: $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> addContact(Contact c, {String locale = 'fr'}) async {
    await _db.insertContact(c);
    await _notif.scheduleBirthdayReminders(c, locale);

    // Sauvegarder dans Firebase
    if (_firebaseSync != null && _firebaseSync!.isUserAuthenticated) {
      await _firebaseSync!.saveContact(c);
    }

    // Analytics: Track contact added
    AnalyticsService().logContactAdded(
      relation: c.relation,
      hasPhone: c.phone != null && c.phone!.isNotEmpty,
    );

    await loadContacts(locale: locale, syncWithFirebase: false);
  }

  Future<void> updateContact(Contact c, {String locale = 'fr'}) async {
    await _db.updateContact(c);
    await _notif.cancelBirthdayReminders(c.id ?? 0);
    await _notif.scheduleBirthdayReminders(c, locale);

    // Mettre à jour dans Firebase
    if (_firebaseSync != null && _firebaseSync!.isUserAuthenticated) {
      await _firebaseSync!.saveContact(c);
    }

    // Analytics: Track contact updated
    AnalyticsService().logContactUpdated(
      relation: c.relation,
    );

    await loadContacts(locale: locale, syncWithFirebase: false);
  }

  Future<void> deleteContact(int id) async {
    await _db.deleteContact(id);
    await _notif.cancelBirthdayReminders(id);
    // Analytics: Track contact deleted
    // Pour suppression, il faut passer le paramètre relation
    final contact = _contacts.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: '', date: '', relation: '', phone: null));
    AnalyticsService().logContactDeleted(
      relation: contact.relation,
    );

    // Supprimer de Firebase
    if (_firebaseSync != null && _firebaseSync!.isUserAuthenticated) {
      await _firebaseSync!.deleteContact(id);
    }

    await loadContacts(syncWithFirebase: false);
  }

  /// Forcer une synchronisation manuelle
  Future<void> forceSyncWithFirebase() async {
    await _syncWithFirebase();
  }

  /// Reschedule all birthday reminders when language changes
  Future<void> rescheduleAllReminders(String locale) async {
    await _notif.rescheduleAllReminders(_contacts, locale);
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
