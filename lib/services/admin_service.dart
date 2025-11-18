import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';
import 'admin_auth_service.dart';

/// Service admin simplifié - Délègue à AdminAuthService
/// Conservé pour compatibilité avec le code existant
class AdminService {
  final FirebaseFirestore firestore;
  final AdminAuthService _authService = AdminAuthService();

  AdminService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection des admins dans Firestore
  CollectionReference get _adminsCollection => firestore.collection('admins');

  /// Vérifier si un utilisateur est admin
  Future<bool> isUserAdmin(String uid) async {
    return await _authService.isUserAdmin(uid);
  }

  /// Récupérer les infos admin d'un utilisateur
  Future<AdminUser?> getAdminUser(String uid) async {
    return await _authService.getAdminUser(uid);
  }

  /// Vérifier si l'utilisateur connecté est admin
  Future<bool> isCurrentUserAdmin() async {
    return await _authService.isCurrentUserAdmin();
  }

  /// Mettre à jour la dernière connexion admin
  Future<void> updateLastLogin(String uid) async {
    try {
      await _adminsCollection.doc(uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Erreur mise à jour lastLogin: $e');
    }
  }

  /// Lister tous les admins
  Future<List<AdminUser>> getAllAdmins() async {
    return await _authService.getAllAdmins();
  }

  /// Stream pour écouter les changements admin
  Stream<bool> adminStatusStream(String uid) {
    return _authService.adminStatusStream(uid);
  }

  // Méthodes dépréciées - Utilisez AdminAuthService directement
  @Deprecated('Utilisez AdminAuthService.createAdmin() à la place')
  Future<void> createAdmin({
    required String email,
    required String password,
    String role = 'admin',
  }) async {
    await _authService.createAdmin(
      email: email,
      password: password,
      role: role,
    );
  }

  @Deprecated('Utilisez AdminAuthService.deactivateAdmin() à la place')
  Future<void> revokeAdmin(String uid) async {
    await _authService.deactivateAdmin(uid);
  }
}
