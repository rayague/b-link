import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';

/// Écran d'initialisation du premier admin
/// ⚠️ SÉCURISÉ - Accessible uniquement si aucun admin n'existe encore
class InitAdminScreen extends StatefulWidget {
  const InitAdminScreen({super.key});

  @override
  State<InitAdminScreen> createState() => _InitAdminScreenState();
}

class _InitAdminScreenState extends State<InitAdminScreen> {
  final _adminAuthService = AdminAuthService();
  final _adminService = AdminService();
  bool _isCreating = false;
  bool _isChecking = true;
  bool _adminAlreadyExists = false;
  String? _result;

  @override
  void initState() {
    super.initState();

    AnalyticsService().logScreenView(
      screenName: 'InitAdminScreen',
      screenClass: 'InitAdminScreen',
    );

    _checkIfAdminExists();
  }

  /// Vérifier si un admin existe déjà dans le système
  Future<void> _checkIfAdminExists() async {
    try {
      final admins = await _adminService.getAllAdmins();
      setState(() {
        _adminAlreadyExists = admins.isNotEmpty;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _adminAlreadyExists = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _createFirstAdmin() async {
    setState(() {
      _isCreating = true;
      _result = null;
    });

    try {
      await _adminAuthService.createFirstAdmin();
      setState(() {
        _result = '✅ Premier administrateur créé avec succès!\n\n'
            'Vous pouvez maintenant vous déconnecter et vous reconnecter avec vos identifiants admin.\n\n'
            '⚠️ IMPORTANT: Notez vos identifiants dans un endroit sécurisé.';
        _adminAlreadyExists = true;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Erreur lors de la création: $e';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Affichage pendant la vérification
    if (_isChecking) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Initialisation Admin'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vérification du système...'),
            ],
          ),
        ),
      );
    }

    // Si un admin existe déjà, bloquer l'accès
    if (_adminAlreadyExists && _result == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Initialisation Admin'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Accès Refusé',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ Un administrateur existe déjà dans le système.\n\n'
                  'Cet écran ne peut être utilisé qu\'une seule fois lors de la première installation.\n\n'
                  'Si vous avez perdu vos identifiants admin, contactez le support technique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Interface de création du premier admin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initialisation Admin'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Créer le Premier Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ ATTENTION ⚠️\n\n'
                'Cette action ne doit être effectuée QU\'UNE SEULE FOIS!\n\n'
                'Elle créera un compte super_admin sécurisé dans Firestore.\n\n'
                '🔒 Pour des raisons de sécurité, les identifiants ne seront PAS affichés ici.\n\n'
                'Contactez l\'administrateur système pour obtenir les credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_isCreating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _createFirstAdmin,
                  icon: const Icon(Icons.security),
                  label: const Text('Créer le Premier Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _result!.startsWith('✅')
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _result!.startsWith('✅') ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    _result!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _result!.startsWith('✅')
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                ),
                if (_result!.startsWith('✅')) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Déconnecter l'utilisateur actuel
                      FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
