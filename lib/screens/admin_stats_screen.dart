import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_sync_service.dart';
import '../services/db_helper.dart';
import '../l10n/app_localizations.dart';

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
    _checkAuthorization();
  }

  /// Vérifier si l'utilisateur est autorisé (admin uniquement)
  Future<void> _checkAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.email?.toLowerCase() != 'rayague03@gmail.com') {
      setState(() {
        _isAuthorized = false;
        _loading = false;
      });
      return;
    }
    
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
    // Écran d'accès refusé si non autorisé
    if (!_loading && !_isAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          title: const Text(
            '🔒 Accès Refusé',
            style: TextStyle(
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
              const Text(
                'Accès Réservé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette section est réservée\nà l\'administrateur uniquement.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                  label: 'Total Utilisateurs',
                  value: totalUsers.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dernière mise à jour: $formattedDate',
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
    final name = user['name'] ?? 'Utilisateur sans nom';
    final email = user['email'] ?? 'Email non renseigné';
    final birthDate = user['birthDate'] ?? '';
    final uid = user['uid'] ?? '';
    final birthplace = user['birthplace'] ?? '';
    final birthCountry = user['birthCountry'] ?? '';

    String formattedDate = '';
    if (birthDate.isNotEmpty) {
      try {
        final date = DateTime.parse(birthDate);
        formattedDate = DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {}
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEB1555),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '#$position',
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (formattedDate.isNotEmpty || birthplace.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF3A3E5B), height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (formattedDate.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.cake,
                    label: formattedDate,
                  ),
                if (birthplace.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.location_on,
                    label:
                        '$birthplace${birthCountry.isNotEmpty ? ", $birthCountry" : ""}',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'UID: $uid',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3A3E5B),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFEB1555)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
