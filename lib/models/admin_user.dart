import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un utilisateur administrateur.
///
/// Les admins sont créés côté serveur (Cloud Function `grantAdmin`), qui écrit
/// les dates sous forme de `Timestamp` Firestore. Aucun mot de passe n'est
/// stocké : l'authentification passe par Firebase Auth.
class AdminUser {
  final String uid;
  final String email;
  final String role; // 'super_admin' ou 'admin'
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool isActive; // Pour désactiver un admin sans le supprimer

  AdminUser({
    required this.uid,
    required this.email,
    this.role = 'admin',
    this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'admin',
      createdAt: _parseDate(map['createdAt']),
      lastLogin: _parseDate(map['lastLogin']),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Accepte un `Timestamp` (écrit par le serveur), une chaîne ISO 8601
  /// (écrite par le client) ou `null`.
  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
