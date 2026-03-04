import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_user.dart';

/// Service d'authentification admin avec mot de passe hashé
class AdminAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Hash un mot de passe avec SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Vérifie si un utilisateur est admin et si le mot de passe est correct
  Future<AdminUser?> authenticateAdmin(String email, String password) async {
    try {
      // Récupérer l'admin par email
      final querySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // Aucun admin trouvé avec cet email
      }

      final adminData = querySnapshot.docs.first.data();
      final admin = AdminUser.fromMap(adminData);

      // Vérifier si l'admin est actif
      if (!admin.isActive) {
        return null; // Admin désactivé
      }

      // Vérifier le mot de passe
      final passwordHash = _hashPassword(password);
      if (passwordHash != admin.passwordHash) {
        return null; // Mot de passe incorrect
      }

      // Mettre à jour la date de dernière connexion
      await _firestore.collection('admins').doc(admin.uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });

      return admin;
    } catch (e) {
      debugPrint('Erreur authentification admin: $e');
      return null;
    }
  }

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

  /// Crée le premier admin (super_admin)
  /// ⚠️ CETTE FONCTION NE DOIT ÊTRE APPELÉE QU'UNE SEULE FOIS!
  Future<void> createFirstAdmin() async {
    try {
      const email = 'rayague03@gmail.com';
      const password = 'Admin@BLink2025!'; // Mot de passe permanent
      const role = 'super_admin';

      // Créer le compte Firebase Auth (pour pouvoir se connecter normalement)
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // Si le compte existe déjà, se connecter pour récupérer l'UID
        debugPrint('⚠️ Compte existe déjà, tentative de connexion...');
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final uid = userCredential.user!.uid;
      final passwordHash = _hashPassword(password);

      // Créer le document admin dans Firestore
      final admin = AdminUser(
        uid: uid,
        email: email,
        passwordHash: passwordHash,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('admins').doc(uid).set(admin.toMap());

      debugPrint('✅ Premier admin créé avec succès!');
      debugPrint('Email: $email');
      debugPrint('Password: $password');
      debugPrint('UID: $uid');
      debugPrint('Hash: $passwordHash');
    } catch (e) {
      debugPrint('❌ Erreur création admin: $e');
      rethrow;
    }
  }

  /// Crée un nouvel admin
  Future<void> createAdmin({
    required String email,
    required String password,
    String role = 'admin',
  }) async {
    try {
      // Seul un super_admin peut créer d'autres admins
      final currentAdmin = await getAdminUser(_auth.currentUser!.uid);
      if (currentAdmin?.role != 'super_admin') {
        throw Exception('Seul un super_admin peut créer des admins');
      }

      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final passwordHash = _hashPassword(password);

      // Créer le document admin
      final admin = AdminUser(
        uid: uid,
        email: email,
        passwordHash: passwordHash,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('admins').doc(uid).set(admin.toMap());

      debugPrint('✅ Admin créé: $email');
    } catch (e) {
      debugPrint('❌ Erreur création admin: $e');
      rethrow;
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

  /// Change le mot de passe d'un admin
  Future<void> changeAdminPassword(String uid, String newPassword) async {
    try {
      final passwordHash = _hashPassword(newPassword);

      await _firestore.collection('admins').doc(uid).update({
        'passwordHash': passwordHash,
      });

      debugPrint('✅ Mot de passe admin changé');
    } catch (e) {
      debugPrint('❌ Erreur changement mot de passe: $e');
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
