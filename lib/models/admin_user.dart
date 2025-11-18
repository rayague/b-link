/// Modèle pour un utilisateur administrateur
class AdminUser {
  final String uid;
  final String email;
  final String passwordHash; // Mot de passe hashé (SHA-256)
  final String role; // 'super_admin' ou 'admin'
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive; // Pour désactiver un admin sans le supprimer

  AdminUser({
    required this.uid,
    required this.email,
    required this.passwordHash,
    this.role = 'admin',
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'passwordHash': passwordHash,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      role: map['role'] ?? 'admin',
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin:
          map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
      isActive: map['isActive'] ?? true,
    );
  }
}
