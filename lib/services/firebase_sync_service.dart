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
      _writePublicProfile(batch, profile);
      await batch.commit();

      // Les statistiques globales sont maintenues côté serveur (Cloud Function
      // `onUserCreated`) ; le client n'écrit plus dans `app_stats`.

      debugPrint('✅ Profil sauvegardé dans Firebase');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde profil: $e');
      rethrow;
    }
  }

  /// Seule la collection `public_profiles` est lisible par les autres
  /// utilisateurs. `set` sans merge : un champ décoché disparaît vraiment.
  void _writePublicProfile(WriteBatch batch, UserProfile profile) {
    final ref = _firestore.collection('public_profiles').doc(_userId);
    if (profile.shouldBePublished) {
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
    final batch = _firestore.batch();
    _writePublicProfile(batch, profile);
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

  /// Sauvegarder un contact dans Firebase
  Future<void> saveContact(Contact contact) async {
    if (_userId == null) return;
    // L'ID local est l'ID du document : sans lui, on créerait un doublon au
    // prochain chargement (ancien comportement : ID = timestamp).
    if (contact.id == null) {
      debugPrint('⚠️ Contact "${contact.name}" sans ID, non synchronisé');
      return;
    }

    try {
      final data = contact.toJson();
      data['userId'] = _userId;
      data['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .doc(contact.id.toString())
          .set(data, SetOptions(merge: true));

      debugPrint('✅ Contact "${contact.name}" sauvegardé dans Firebase');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde contact: $e');
    }
  }

  /// Sauvegarder tous les contacts dans Firebase
  Future<void> saveAllContacts(List<Contact> contacts) async {
    if (_userId == null) return;

    try {
      final batch = _firestore.batch();

      for (final contact in contacts) {
        if (contact.id == null) continue;
        final data = contact.toJson();
        data['userId'] = _userId;
        data['lastUpdated'] = FieldValue.serverTimestamp();

        final ref = _firestore
            .collection('users')
            .doc(_userId)
            .collection('contacts')
            .doc(contact.id.toString());

        batch.set(ref, data, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('✅ ${contacts.length} contacts sauvegardés dans Firebase');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde batch contacts: $e');
    }
  }

  /// Récupérer tous les contacts depuis Firebase
  Future<List<Contact>> getAllContacts() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .get();

      final contacts = snapshot.docs.map((doc) {
        final data = doc.data();
        // Utiliser l'ID du document comme ID du contact
        data['id'] = int.tryParse(doc.id);
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
  Future<void> deleteContact(int contactId) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .doc(contactId.toString())
          .delete();

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

    // Un batch Firestore est limité à 500 opérations : on découpe.
    final contacts = await userRef.collection('contacts').get();
    const chunkSize = 400;
    for (var i = 0; i < contacts.docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      for (final doc in contacts.docs.skip(i).take(chunkSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _firestore.collection('public_profiles').doc(_userId).delete();
    await userRef.delete();
    debugPrint('✅ Données utilisateur supprimées de Firebase');
  }
}
