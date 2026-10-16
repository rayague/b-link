import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact.dart';
import '../models/user_profile.dart';

/// Accès Firestore : profil (privé + projection publique), contacts,
/// statistiques. Le SDK Firestore gère lui-même le cache hors ligne et la
/// file d'écriture : aucune file de synchronisation maison n'est nécessaire.
class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtenir l'ID utilisateur actuel
  String? get _userId => _auth.currentUser?.uid;

  /// Vérifier si l'utilisateur est connecté
  bool get isUserAuthenticated => _userId != null;

  // ==================== PROFIL UTILISATEUR ====================

  /// Sauvegarder le profil utilisateur dans Firebase
  Future<void> saveUserProfile(UserProfile profile) async {
    if (_userId == null) {
      debugPrint('⚠️ Impossible de sauvegarder: utilisateur non connecté');
      return;
    }

    try {
      profile.uid ??= _userId;
      profile.birthDayKey = UserProfile.dayKeyOf(profile.birthDate);
      final data = profile.toJson();
      data['userId'] = _userId;
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['email'] = _auth.currentUser?.email;

      // Profil privé + projection publique écrits ensemble (atomique).
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(_userId), data,
          SetOptions(merge: true));
      _writePublicProfile(batch, profile,
          hiddenByModeration: await isHiddenByModeration());
      await batch.commit();

      // Les statistiques globales sont maintenues côté serveur (Cloud Function
      // `onUserCreated`) ; le client n'écrit plus dans `app_stats`.

      debugPrint('✅ Profil sauvegardé dans Firebase');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde profil: $e');
      rethrow;
    }
  }

  /// Le profil a-t-il été masqué de l'annuaire par la modération
  /// (moderation/{uid}, écrit par le serveur ou un admin) ? En cas d'erreur
  /// de lecture, on considère que non : les règles refuseront de toute façon
  /// une republication interdite.
  Future<bool> isHiddenByModeration() async {
    if (_userId == null) return false;
    try {
      final doc =
          await _firestore.collection('moderation').doc(_userId).get();
      return doc.exists && doc.data()?['hidden'] == true;
    } catch (e) {
      debugPrint('⚠️ Lecture modération: $e');
      return false;
    }
  }

  /// Seule la collection `public_profiles` est lisible par les autres
  /// utilisateurs. `set` sans merge : un champ décoché disparaît vraiment.
  /// Un profil masqué par la modération n'est jamais republié (les règles
  /// refuseraient tout le batch, y compris le profil privé).
  void _writePublicProfile(WriteBatch batch, UserProfile profile,
      {required bool hiddenByModeration}) {
    final ref = _firestore.collection('public_profiles').doc(_userId);
    if (profile.shouldBePublished && !hiddenByModeration) {
      batch.set(ref, {
        ...profile.toPublicJson(),
        'uid': _userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.delete(ref);
    }
  }

  /// (Re)publie la projection publique, par ex. pour les profils créés avant
  /// l'introduction de `public_profiles`.
  Future<void> publishPublicProfile(UserProfile profile) async {
    if (_userId == null) return;
    final hidden = await isHiddenByModeration();
    if (hidden) return; // rien à republier
    final batch = _firestore.batch();
    _writePublicProfile(batch, profile, hiddenByModeration: false);
    await batch.commit();
  }

  /// Récupérer le profil utilisateur depuis Firebase.
  /// Avec [rethrowErrors], une erreur réseau/permission est propagée au lieu
  /// d'être confondue avec "aucun profil".
  Future<UserProfile?> getUserProfile({bool rethrowErrors = false}) async {
    if (_userId == null) {
      debugPrint('⚠️ Impossible de récupérer: utilisateur non connecté');
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();

      if (!doc.exists) {
        debugPrint('ℹ️ Aucun profil trouvé dans Firebase');
        return null;
      }

      final data = doc.data()!;
      debugPrint('✅ Profil récupéré depuis Firebase');
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('❌ Erreur récupération profil: $e');
      if (rethrowErrors) rethrow;
      return null;
    }
  }

  // ==================== CONTACTS ====================

  CollectionReference<Map<String, dynamic>> get _contacts => _firestore
      .collection('users')
      .doc(_userId)
      .collection('contacts');

  /// Sauvegarder un contact dans Firebase. L'ID du document est l'UUID du
  /// contact, stable entre appareils (l'ID SQLite local ne l'est pas).
  Future<void> saveContact(Contact contact) async {
    if (_userId == null) return;
    if (contact.uuid == null) {
      debugPrint('⚠️ Contact "${contact.name}" sans UUID, non synchronisé');
      return;
    }

    try {
      final data = contact.toJson()..remove('id'); // l'ID local reste local
      data['userId'] = _userId;
      data['lastUpdated'] = FieldValue.serverTimestamp();
      await _contacts.doc(contact.uuid).set(data, SetOptions(merge: true));
      debugPrint('✅ Contact "${contact.name}" sauvegardé dans Firebase');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde contact: $e');
    }
  }

  /// Récupérer tous les contacts depuis Firebase (sans ID local : chaque
  /// appareil attribue le sien). L'UUID est l'ID du document.
  Future<List<Contact>> getAllContacts() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _contacts.get();
      final contacts = snapshot.docs.map((doc) {
        final data = doc.data()
          ..remove('id')
          ..['uuid'] = doc.id;
        return Contact.fromJson(data);
      }).toList();

      debugPrint('✅ ${contacts.length} contacts récupérés depuis Firebase');
      return contacts;
    } catch (e) {
      debugPrint('❌ Erreur récupération contacts: $e');
      return [];
    }
  }

  /// Supprimer un contact de Firebase
  Future<void> deleteContact(String uuid) async {
    if (_userId == null) return;

    try {
      await _contacts.doc(uuid).delete();
      debugPrint('✅ Contact supprimé de Firebase');
    } catch (e) {
      debugPrint('❌ Erreur suppression contact: $e');
    }
  }

  // ==================== STATISTIQUES GLOBALES ====================
  // L'écriture de `app_stats` est réservée au serveur (Cloud Function
  // `onUserCreated`). Le client ne fait que lire les statistiques.

  /// Récupérer les statistiques globales
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final doc = await _firestore.collection('app_stats').doc('global').get();

      if (!doc.exists) {
        return {'totalUsers': 0};
      }

      return doc.data()!;
    } catch (e) {
      debugPrint('❌ Erreur récupération stats: $e');
      return {'totalUsers': 0};
    }
  }

  /// Récupérer la liste de tous les utilisateurs (ADMIN ONLY)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération utilisateurs: $e');
      return [];
    }
  }

  // ==================== NETTOYAGE ====================

  /// Supprimer toutes les données de l'utilisateur.
  /// Propage les erreurs : la suppression de compte ne doit pas continuer si
  /// les données n'ont pas été effacées.
  Future<void> deleteUserData() async {
    if (_userId == null) return;
    final userRef = _firestore.collection('users').doc(_userId);

    // Sous-collections privées. Un batch Firestore est limité à 500
    // opérations : on découpe.
    for (final sub in ['contacts', 'blocks', 'devices']) {
      final docs = (await userRef.collection(sub).get()).docs;
      const chunkSize = 400;
      for (var i = 0; i < docs.length; i += chunkSize) {
        final batch = _firestore.batch();
        for (final doc in docs.skip(i).take(chunkSize)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    await _firestore.collection('public_profiles').doc(_userId).delete();
    await userRef.delete();
    debugPrint('✅ Données utilisateur supprimées de Firebase');
  }
}
