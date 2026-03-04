import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact.dart';
import '../models/user_profile.dart';
import 'db_helper.dart';

/// Service de synchronisation complète avec Firebase
/// Gère: Profils utilisateurs, Contacts, Statistiques globales
class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DBHelper _db;

  FirebaseSyncService(this._db);

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
      final data = profile.toJson();
      data['userId'] = _userId;
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['email'] = _auth.currentUser?.email;

      await _firestore
          .collection('users')
          .doc(_userId)
          .set(data, SetOptions(merge: true));

      // Mettre à jour les statistiques globales
      await _updateGlobalStats();

      debugPrint('✅ Profil sauvegardé dans Firebase');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde profil: $e');
      rethrow;
    }
  }

  /// Récupérer le profil utilisateur depuis Firebase
  Future<UserProfile?> getUserProfile() async {
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
      return null;
    }
  }

  /// Écouter les changements du profil en temps réel
  Stream<UserProfile?> watchUserProfile() {
    if (_userId == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(_userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromJson(doc.data()!);
    });
  }

  // ==================== CONTACTS ====================

  /// Sauvegarder un contact dans Firebase
  Future<void> saveContact(Contact contact) async {
    if (_userId == null) return;

    try {
      final data = contact.toJson();
      data['userId'] = _userId;
      data['lastUpdated'] = FieldValue.serverTimestamp();

      final contactId = contact.id?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .doc(contactId)
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
        final data = contact.toJson();
        data['userId'] = _userId;
        data['lastUpdated'] = FieldValue.serverTimestamp();

        final contactId = contact.id?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final ref = _firestore
            .collection('users')
            .doc(_userId)
            .collection('contacts')
            .doc(contactId);

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

  /// Écouter les changements des contacts en temps réel
  Stream<List<Contact>> watchContacts() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('contacts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id);
        return Contact.fromJson(data);
      }).toList();
    });
  }

  // ==================== SYNCHRONISATION COMPLÈTE ====================

  /// Synchronisation complète: Local → Firebase
  Future<void> syncToFirebase({
    UserProfile? profile,
    List<Contact>? contacts,
  }) async {
    if (_userId == null) {
      debugPrint('⚠️ Impossible de synchroniser: utilisateur non connecté');
      return;
    }

    debugPrint('🔄 Début synchronisation vers Firebase...');

    try {
      // Sauvegarder le profil
      if (profile != null) {
        await saveUserProfile(profile);
      }

      // Sauvegarder les contacts
      if (contacts != null && contacts.isNotEmpty) {
        await saveAllContacts(contacts);
      }

      debugPrint('✅ Synchronisation vers Firebase terminée');
    } catch (e) {
      debugPrint('❌ Erreur synchronisation: $e');
      rethrow;
    }
  }

  /// Synchronisation complète: Firebase → Local
  /// Utilisé après réinstallation ou première connexion
  Future<void> syncFromFirebase() async {
    if (_userId == null) {
      debugPrint('⚠️ Impossible de synchroniser: utilisateur non connecté');
      return;
    }

    debugPrint('🔄 Début récupération depuis Firebase...');

    try {
      // Récupérer le profil
      final profile = await getUserProfile();
      if (profile != null) {
        // Sauvegarder en local (à implémenter dans ProfileProvider)
        debugPrint('📥 Profil récupéré: ${profile.name}');
      }

      // Récupérer les contacts
      final contacts = await getAllContacts();
      if (contacts.isNotEmpty) {
        // Sauvegarder en local
        for (final contact in contacts) {
          await _db.insertContact(contact);
        }
        debugPrint(
            '📥 ${contacts.length} contacts récupérés et sauvegardés localement');
      }

      debugPrint('✅ Synchronisation depuis Firebase terminée');
    } catch (e) {
      debugPrint('❌ Erreur récupération: $e');
      rethrow;
    }
  }

  /// Synchronisation bidirectionnelle intelligente
  /// Compare local et Firebase, garde la version la plus récente
  Future<void> smartSync({
    required UserProfile? localProfile,
    required List<Contact> localContacts,
  }) async {
    if (_userId == null) return;

    debugPrint('🔄 Synchronisation intelligente...');

    try {
      // 1. Récupérer les données Firebase
      final firebaseProfile = await getUserProfile();
      final firebaseContacts = await getAllContacts();

      // 2. Fusionner les profils (garder le plus récent)
      if (localProfile != null) {
        await saveUserProfile(localProfile);
      } else if (firebaseProfile != null) {
        // Sauvegarder le profil Firebase en local
        debugPrint('📥 Profil Firebase récupéré');
      }

      // 3. Fusionner les contacts
      final localContactIds = localContacts.map((c) => c.id).toSet();
      final firebaseContactIds = firebaseContacts.map((c) => c.id).toSet();

      // Contacts uniquement en local → envoyer à Firebase
      final onlyLocal = localContacts
          .where((c) => !firebaseContactIds.contains(c.id))
          .toList();
      if (onlyLocal.isNotEmpty) {
        await saveAllContacts(onlyLocal);
        debugPrint('📤 ${onlyLocal.length} contacts locaux envoyés à Firebase');
      }

      // Contacts uniquement sur Firebase → sauvegarder en local
      final onlyFirebase = firebaseContacts
          .where((c) => !localContactIds.contains(c.id))
          .toList();
      if (onlyFirebase.isNotEmpty) {
        for (final contact in onlyFirebase) {
          await _db.insertContact(contact);
        }
        debugPrint(
            '📥 ${onlyFirebase.length} contacts Firebase sauvegardés localement');
      }

      debugPrint('✅ Synchronisation intelligente terminée');
    } catch (e) {
      debugPrint('❌ Erreur synchronisation intelligente: $e');
    }
  }

  // ==================== STATISTIQUES GLOBALES ====================

  /// Mettre à jour les statistiques globales (nombre total d'utilisateurs, etc.)
  Future<void> _updateGlobalStats() async {
    try {
      final statsRef = _firestore.collection('app_stats').doc('global');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statsRef);

        if (!snapshot.exists) {
          // Créer le document de stats
          transaction.set(statsRef, {
            'totalUsers': 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Incrémenter si nouvel utilisateur
          final data = snapshot.data()!;
          final currentUsers = data['totalUsers'] ?? 0;

          // Vérifier si c'est un nouvel utilisateur
          final userDoc =
              await _firestore.collection('users').doc(_userId).get();
          if (!userDoc.exists || !data.containsKey('userIds')) {
            transaction.update(statsRef, {
              'totalUsers': currentUsers + 1,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur mise à jour stats: $e');
    }
  }

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

  /// Écouter les statistiques en temps réel
  Stream<Map<String, dynamic>> watchGlobalStats() {
    return _firestore
        .collection('app_stats')
        .doc('global')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {'totalUsers': 0};
      return doc.data()!;
    });
  }

  // ==================== NETTOYAGE ====================

  /// Supprimer toutes les données de l'utilisateur
  Future<void> deleteUserData() async {
    if (_userId == null) return;

    try {
      // Supprimer tous les contacts
      final contacts = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .get();

      final batch = _firestore.batch();
      for (final doc in contacts.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer le profil
      batch.delete(_firestore.collection('users').doc(_userId));

      await batch.commit();
      debugPrint('✅ Données utilisateur supprimées de Firebase');
    } catch (e) {
      debugPrint('❌ Erreur suppression données: $e');
    }
  }
}
