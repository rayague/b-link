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

  /// Synchronisation avec Firebase : fusion par UUID (voir [planMerge]).
  Future<void> _syncWithFirebase() async {
    if (_firebaseSync == null || !_firebaseSync!.isUserAuthenticated) return;

    _syncing = true;
    notifyListeners();

    try {
      final remote = await _firebaseSync!.getAllContacts();
      final plan = planMerge(_contacts, remote);

      for (final entry in plan.adoptUuid.entries) {
        await _db.setContactUuid(entry.key, entry.value);
      }
      for (final uuid in plan.deleteRemote) {
        await _firebaseSync!.deleteContact(uuid);
      }
      for (final contact in plan.insertLocally) {
        await _db.insertContact(contact);
      }
      for (final contact in plan.upload) {
        await _firebaseSync!.saveContact(contact);
      }
      if (plan.adoptUuid.isNotEmpty || plan.insertLocally.isNotEmpty) {
        _contacts = await _db.getContacts();
      }
      debugPrint('✅ Synchronisation Firebase terminée');
    } catch (e) {
      debugPrint('❌ Erreur synchronisation Firebase: $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Décide comment fusionner les contacts locaux et ceux de Firebase.
  ///
  /// - Même UUID : rien à faire.
  /// - Contact distant inconnu localement mais identique (nom + date) à un
  ///   contact local dont l'UUID n'est pas encore sur Firebase : le contact
  ///   local adopte l'UUID distant. (Supprimer le distant ferait boucler deux
  ///   appareils qui ont chacun créé le même contact.)
  /// - Identique à un contact local déjà associé : vrai doublon, supprimé.
  /// - Sinon : nouveau contact, inséré localement.
  /// - Les contacts locaux absents de Firebase y sont envoyés.
  static ContactMergePlan planMerge(List<Contact> local, List<Contact> remote) {
    final remoteUuids = {for (final r in remote) r.uuid};
    final localUuids = {for (final l in local) l.uuid};
    final plan = ContactMergePlan();
    // Contacts locaux déjà associés à un document distant (par UUID ou
    // adoption) : clé de dédoublonnage -> contact.
    final claimed = <int?>{
      for (final l in local)
        if (remoteUuids.contains(l.uuid)) l.id,
    };
    final byKey = <String, Contact>{};
    for (final l in local) {
      byKey.putIfAbsent(_dedupKey(l), () => l);
    }

    for (final r in remote) {
      if (r.uuid == null || localUuids.contains(r.uuid)) continue;
      final twin = byKey[_dedupKey(r)];
      if (twin == null) {
        plan.insertLocally.add(r);
      } else if (claimed.contains(twin.id)) {
        plan.deleteRemote.add(r.uuid!);
      } else {
        plan.adoptUuid[twin.id!] = r.uuid!;
        claimed.add(twin.id);
      }
    }

    for (final l in local) {
      if (!claimed.contains(l.id) && l.uuid != null) plan.upload.add(l);
    }
    return plan;
  }

  Future<void> addContact(Contact contact, {String locale = 'fr'}) async {
    // L'UUID (ID Firestore, stable entre appareils) est attribué avant
    // l'insertion ; l'ID local (rappels) est attribué par SQLite.
    final withUuid =
        contact.uuid == null ? contact.copyWith(uuid: Contact.newUuid()) : contact;
    final id = await _db.insertContact(withUuid) as int;
    final c = withUuid.copyWith(id: id);
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

  Future<void> updateContact(Contact contact, {String locale = 'fr'}) async {
    // Les écrans d'édition reconstruisent le contact sans son UUID.
    final c = contact.uuid != null || contact.id == null
        ? contact
        : contact.copyWith(uuid: byId(contact.id!)?.uuid);
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
    final contact = byId(id);
    await _db.deleteContact(id);
    await _notif.cancelBirthdayReminders(id);
    AnalyticsService().logContactDeleted(relation: contact?.relation ?? '');

    // Supprimer de Firebase
    final uuid = contact?.uuid;
    if (uuid != null &&
        _firebaseSync != null &&
        _firebaseSync!.isUserAuthenticated) {
      await _firebaseSync!.deleteContact(uuid);
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

/// Résultat de [ContactProvider.planMerge].
class ContactMergePlan {
  /// ID local -> UUID distant à adopter.
  final Map<int, String> adoptUuid = {};
  /// UUID de doublons distants à supprimer.
  final List<String> deleteRemote = [];
  /// Contacts distants à insérer localement.
  final List<Contact> insertLocally = [];
  /// Contacts locaux à envoyer à Firebase.
  final List<Contact> upload = [];
}
