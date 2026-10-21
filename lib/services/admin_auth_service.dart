import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_user.dart';

/// Service d'administration (lecture seule + gestion de statut).
///
/// La création de comptes administrateurs est réalisée côté serveur
/// (compte Firebase Auth + document `admins/{uid}` créé via Cloud Function).
/// Aucun identifiant ni mot de passe n'est stocké/hashé côté client.
class AdminAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Vérifie si l'utilisateur Firebase Auth actuel est admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    return await isUserAdmin(user.uid);
  }

  /// Vérifie si un UID est admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (!doc.exists) return false;

      final admin = AdminUser.fromMap(doc.data()!);
      return admin.isActive;
    } catch (e) {
      debugPrint('Erreur vérification admin: $e');
      return false;
    }
  }

  /// Récupère les informations d'un admin
  Future<AdminUser?> getAdminUser(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (!doc.exists) return null;

      return AdminUser.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Erreur récupération admin: $e');
      return null;
    }
  }

  /// Désactive un admin (ne supprime pas les données)
  Future<void> deactivateAdmin(String uid) async {
    try {
      await _firestore.collection('admins').doc(uid).update({
        'isActive': false,
      });
      debugPrint('✅ Admin désactivé');
    } catch (e) {
      debugPrint('❌ Erreur désactivation admin: $e');
      rethrow;
    }
  }

  /// Réactive un admin
  Future<void> reactivateAdmin(String uid) async {
    try {
      await _firestore.collection('admins').doc(uid).update({
        'isActive': true,
      });
      debugPrint('✅ Admin réactivé');
    } catch (e) {
      debugPrint('❌ Erreur réactivation admin: $e');
      rethrow;
    }
  }

  /// Liste tous les admins
  Future<List<AdminUser>> getAllAdmins() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      return snapshot.docs.map((doc) => AdminUser.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération admins: $e');
      return [];
    }
  }

  /// Stream des changements de statut admin
  Stream<bool> adminStatusStream(String uid) {
    return _firestore.collection('admins').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return false;
      final admin = AdminUser.fromMap(snapshot.data()!);
      return admin.isActive;
    });
  }
}
