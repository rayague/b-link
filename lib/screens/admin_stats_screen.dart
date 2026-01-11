import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_sync_service.dart';
import '../services/db_helper.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../services/message_repository.dart';
import '../models/contact.dart';
import '../services/analytics_service.dart';

/// Écran d'administration pour voir les statistiques globales
/// et la liste de tous les utilisateurs inscrits
/// ACCESSIBLE UNIQUEMENT PAR: rayague03@gmail.com
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final FirebaseSyncService _firebaseSync = FirebaseSyncService(DBHelper());
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>>? _allUsers;
  bool _loading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();

    AnalyticsService().logScreenView(
      screenName: 'AdminStatsScreen',
      screenClass: 'AdminStatsScreen',
    );
    AnalyticsService().logAdminLogin(adminRole: 'admin');

    _checkAuthorization();
  }

  /// Tester les notifications avec un vrai message depuis la base de données
  Future<void> _testNotification() async {
    // Afficher un dialogue pour choisir la catégorie
    final category = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text(
          '🔔 Test de notification',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Choisissez une catégorie de contact pour voir un exemple de message d\'anniversaire :',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'son'),
            icon: const Icon(Icons.child_care, color: Colors.blue),
            label: const Text('Fils', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'daughter'),
            icon: const Icon(Icons.girl, color: Colors.pink),
            label: const Text('Fille', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'friend'),
            icon: const Icon(Icons.people, color: Colors.green),
            label: const Text('Ami(e)', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'mother'),
            icon: const Icon(Icons.favorite, color: Colors.red),
            label: const Text('Mère', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'father'),
            icon: const Icon(Icons.handshake, color: Colors.orange),
            label: const Text('Père', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (category == null) return;

    try {
      // Récupérer un message aléatoire depuis la base de données
      final messageRepo = MessageRepository();
      final message =
          await messageRepo.getRandomForRelation(category, 'Contact Test');

      if (message.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ Aucun message trouvé pour la catégorie "$category"',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Créer un contact de test
      final testContact = Contact(
        name: 'Contact Test ($category)',
        date: DateTime.now().toIso8601String(),
        relation: category,
      );

      // Envoyer la notification avec le vrai message
      final notificationService = NotificationService();
      await notificationService.sendTestNotificationWithMessage(
        contact: testContact,
        message: message,
      );

      if (mounted) {
        // Afficher un dialogue avec le message complet et option de copie
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✅ Notification envoyée !',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📱 Vérifiez votre barre de notifications',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF3A3E5B)),
                  const SizedBox(height: 16),
                  const Text(
                    '📝 Message envoyé :',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3E5B)),
                    ),
                    child: SelectableText(
                      message,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  // Copier dans le presse-papiers
                  await Clipboard.setData(ClipboardData(text: message));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.copy_all, color: Colors.white),
                            SizedBox(width: 12),
                            Text('📋 Message copié dans le presse-papiers !'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, color: Colors.amber),
                label:
                    const Text('Copier', style: TextStyle(color: Colors.amber)),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70),
                label: const Text('Fermer',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '❌ Erreur: $e',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Vérifier si l'utilisateur est autorisé (admin uniquement)
  Future<void> _checkAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isAuthorized = false;
        _loading = false;
      });
      return;
    }

    // Vérifier dans Firestore si l'utilisateur est admin
    final adminService = AdminService();
    final isAdmin = await adminService.isUserAdmin(user.uid);

    if (!isAdmin) {
      setState(() {
        _isAuthorized = false;
        _loading = false;
      });
      return;
    }

    // Mettre à jour la dernière connexion
    await adminService.updateLastLogin(user.uid);

    setState(() => _isAuthorized = true);
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!_isAuthorized) return;

    setState(() => _loading = true);

    try {
      final stats = await _firebaseSync.getGlobalStats();
      final users = await _firebaseSync.getAllUsers();

      setState(() {
        _stats = stats;
        _allUsers = users;
        _loading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement données admin: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Écran d'accès refusé si non autorisé
    if (!_loading && !_isAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          title: Text(
            loc.translate('accessDenied'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1D1E33),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 100,
                color: Color(0xFFEB1555),
              ),
              const SizedBox(height: 24),
              Text(
                loc.translate('restrictedAccess'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.translate('adminOnly'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(AppLocalizations.of(context).translate('back')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB1555),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          '📊 Administration',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.amber),
            onPressed: _testNotification,
            tooltip: 'Test notification',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1555)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFEB1555),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(),
                    const SizedBox(height: 24),
                    _buildUsersListCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    final totalUsers = _stats?['totalUsers'] ?? 0;
    final lastUpdated = _stats?['lastUpdated'];

    String formattedDate = 'Jamais';
    if (lastUpdated != null) {
      try {
        final date = (lastUpdated as dynamic).toDate();
        formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(date);
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEB1555), Color(0xFFFF4081)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB1555).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Statistiques Globales',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  label: AppLocalizations.of(context).translate('totalUsers'),
                  value: totalUsers.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)
                .translate('lastUpdate')
                .replaceAll('{date}', formattedDate),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersListCard() {
    if (_allUsers == null || _allUsers!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Aucun utilisateur inscrit',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group, color: Color(0xFFEB1555), size: 24),
              SizedBox(width: 12),
              Text(
                'Liste des Utilisateurs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allUsers!.length,
            separatorBuilder: (context, index) => const Divider(
              color: Color(0xFF3A3E5B),
              height: 24,
            ),
            itemBuilder: (context, index) {
              final user = _allUsers![index];
              return _buildUserTile(user, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, int position) {
    final loc = AppLocalizations.of(context);
    final name = user['name'] ?? 'Utilisateur sans nom';
    final email = user['email'] ?? loc.translate('emailNotProvided');
    final birthDate = user['birthDate'] ?? '';
    final uid = user['uid'] ?? '';
    final birthplace = user['birthplace'] ?? '';
    final birthCountry = user['birthCountry'] ?? '';
    final createdAt = user['createdAt'];
    final lastLogin = user['lastLogin'];
    final contactsCount = user['contactsCount'] ?? 0;

    String formattedBirthDate = '';
    if (birthDate.isNotEmpty) {
      try {
        final date = DateTime.parse(birthDate);
        formattedBirthDate = DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {}
    }

    String formattedCreatedAt = '';
    if (createdAt != null) {
      try {
        final date = (createdAt as dynamic).toDate();
        formattedCreatedAt = DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        if (createdAt is String) {
          try {
            final date = DateTime.parse(createdAt);
            formattedCreatedAt = DateFormat('dd/MM/yyyy').format(date);
          } catch (_) {}
        }
      }
    }

    String formattedLastLogin = 'Jamais';
    if (lastLogin != null) {
      try {
        final date = (lastLogin as dynamic).toDate();
        formattedLastLogin = DateFormat('dd/MM à HH:mm').format(date);
      } catch (_) {
        if (lastLogin is String) {
          try {
            final date = DateTime.parse(lastLogin);
            formattedLastLogin = DateFormat('dd/MM à HH:mm').format(date);
          } catch (_) {}
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3E5B),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1: Position + Nom
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEB1555),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: Color(0xFF8D8E98),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              color: Color(0xFF8D8E98),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF3A3E5B), height: 1),
          const SizedBox(height: 12),
          // Ligne 2: Informations minimales
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (formattedBirthDate.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.cake,
                  label: formattedBirthDate,
                  color: Colors.blue,
                ),
              if (birthplace.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.location_on,
                  label: birthplace,
                  color: Colors.orange,
                ),
              if (birthCountry.isNotEmpty && birthCountry != birthplace)
                _buildInfoChip(
                  icon: Icons.flag,
                  label: birthCountry,
                  color: Colors.green,
                ),
              _buildInfoChip(
                icon: Icons.contacts,
                label: '$contactsCount contact${contactsCount > 1 ? 's' : ''}',
                color: const Color(0xFFEB1555),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ligne 3: Dates d'inscription et dernière connexion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (formattedCreatedAt.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.person_add,
                      color: Color(0xFF8D8E98),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Inscrit: $formattedCreatedAt',
                      style: const TextStyle(
                        color: Color(0xFF8D8E98),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              Row(
                children: [
                  const Icon(
                    Icons.login,
                    color: Color(0xFF8D8E98),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Connexion: $formattedLastLogin',
                    style: const TextStyle(
                      color: Color(0xFF8D8E98),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne 4: UID (cliquable pour copier)
          InkWell(
            onTap: () {
              // Copier l'UID dans le presse-papiers
              if (uid.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('UID copié: $uid'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFFEB1555),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fingerprint,
                    color: Color(0xFF8D8E98),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'UID: ${uid.length > 20 ? '${uid.substring(0, 20)}...' : uid}',
                      style: const TextStyle(
                        color: Color(0xFF8D8E98),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.copy,
                    color: Color(0xFF8D8E98),
                    size: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
