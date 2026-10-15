import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/db_helper.dart';
import '../services/notification_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/analytics_service.dart';
import '../utils/birthday.dart';

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
        _firebaseSync = firebaseSync ?? FirebaseSyncService();

  // Test-friendly constructor that accepts dynamic (fake) dependencies to avoid type issues in tests
  ContactProvider.test({dynamic db, dynamic notif})
      : _db = db ?? DBHelper(),
        _notif = notif ?? NotificationService(),
        _firebaseSync = null;

  Future<void> loadContacts(
      {String locale = 'fr', bool syncWithFirebase = true}) async {
    _loading = true;
    notifyListeners();
    // try/finally : une erreur ne doit jamais laisser l'overlay de chargement
    // affiché indéfiniment au-dessus de l'accueil.
    try {
      await _db.ensurePhoneColumn();
      try {
        final imported = await _db.importMessagesIfEmpty();
        if (imported > 0) {
          debugPrint('Imported $imported messages into local database');
        }
      } catch (_) {}

      _contacts = await _db.getContacts();

      // Synchroniser avec Firebase si connecté
      if (syncWithFirebase &&
          _firebaseSync != null &&
          _firebaseSync!.isUserAuthenticated) {
        await _syncWithFirebase();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement contacts: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }

    // Les rappels sont programmés après l'affichage : ils ne bloquent pas l'UI.
    await _scheduleAll(locale);
  }

  Future<void> _scheduleAll(String locale) async {
    try {
      await _notif.init();
      await _notif.rescheduleAllReminders(List<Contact>.of(_contacts), locale);
    } catch (e) {
      debugPrint('❌ Programmation des rappels impossible: $e');
    }
  }

  /// Programme les rappels d'un contact sans jamais faire échouer l'appelant.
  Future<void> _scheduleFor(Contact c, String locale) async {
    try {
      await _notif.scheduleBirthdayReminders(c, locale);
    } catch (e) {
      debugPrint('❌ Rappels non programmés pour ${c.name}: $e');
    }
  }

  static String _dedupKey(Contact c) =>
      '${c.name.trim().toLowerCase()}|${c.date.split('T').first}';

  /// Synchronisation intelligente avec Firebase
  Future<void> _syncWithFirebase() async {
    if (_firebaseSync == null || !_firebaseSync!.isUserAuthenticated) return;

    _syncing = true;
    notifyListeners();

    try {
      debugPrint('🔄 Synchronisation avec Firebase...');

      // Récupérer les contacts depuis Firebase
      final firebaseContacts = await _firebaseSync!.getAllContacts();

      // Fusionner avec les contacts locaux
      final localIds = _contacts.map((c) => c.id).toSet();
      final localKeys = _contacts.map(_dedupKey).toSet();
      final firebaseIds = firebaseContacts.map((c) => c.id).toSet();

      // Contacts uniquement sur Firebase → ajouter en local
      for (final contact in firebaseContacts) {
        if (contact.id == null || localIds.contains(contact.id)) continue;
        if (localKeys.contains(_dedupKey(contact))) {
          // Doublon créé par l'ancien bug (ID = timestamp) : on le retire
          // de Firebase au lieu de le réimporter.
          await _firebaseSync!.deleteContact(contact.id!);
          continue;
        }
        await _db.insertContact(contact);
        _contacts.add(contact);
        localKeys.add(_dedupKey(contact));
      }

      // Contacts uniquement en local → envoyer à Firebase
      for (final contact in _contacts) {
        if (!firebaseIds.contains(contact.id)) {
          await _firebaseSync!.saveContact(contact);
        }
      }

      debugPrint('✅ Synchronisation Firebase terminée');
    } catch (e) {
      debugPrint('❌ Erreur synchronisation Firebase: $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> addContact(Contact contact, {String locale = 'fr'}) async {
    // Récupérer l'ID attribué par SQLite : il sert d'ID de rappel et d'ID
    // Firestore. Sans lui, les rappels étaient ignorés et Firebase créait un
    // doublon avec un ID timestamp.
    final id = await _db.insertContact(contact) as int;
    final c = contact.copyWith(id: id);
    await _scheduleFor(c, locale);

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
    await _scheduleFor(c, locale); // annule puis reprogramme

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

  /// Efface les contacts locaux et annule tous les rappels (déconnexion), pour
  /// que le compte suivant sur cet appareil ne récupère rien du précédent.
  Future<void> reset() async {
    try {
      await _notif.cancelAll();
    } catch (e) {
      debugPrint('❌ Annulation des rappels impossible: $e');
    }
    await _db.clearUserData();
    _contacts = [];
    notifyListeners();
  }

  /// Forcer une synchronisation manuelle
  Future<void> forceSyncWithFirebase() async {
    await _syncWithFirebase();
  }

  /// Reschedule all birthday reminders when language changes
  Future<void> rescheduleAllReminders(String locale) async {
    await _notif.rescheduleAllReminders(_contacts, locale);
  }

  /// Contacts dont l'anniversaire tombe dans les [days] prochains jours
  /// (aujourd'hui inclus), du plus proche au plus lointain. Gère le passage
  /// d'année et le 29 février.
  List<Contact> upcoming(int days, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final withDays = <(Contact, int)>[];
    for (final c in _contacts) {
      final birth = parseBirthDate(c.date);
      if (birth == null) continue;
      final d = daysUntilBirthday(birth, today);
      if (d <= days) withDays.add((c, d));
    }
    withDays.sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (c, _) in withDays) c];
  }

  /// Contact par ID (ouverture depuis une notification).
  Contact? byId(int id) {
    for (final c in _contacts) {
      if (c.id == id) return c;
    }
    return null;
  }
}
