import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';

/// Écran d'initialisation du premier admin
/// ⚠️ Cet écran ne doit être utilisé QU'UNE SEULE FOIS lors de la première installation!
class InitAdminScreen extends StatefulWidget {
  const InitAdminScreen({super.key});

  @override
  State<InitAdminScreen> createState() => _InitAdminScreenState();
}

class _InitAdminScreenState extends State<InitAdminScreen> {
  final _adminAuthService = AdminAuthService();
  bool _isCreating = false;
  String? _result;

  Future<void> _createFirstAdmin() async {
    setState(() {
      _isCreating = true;
      _result = null;
    });

    try {
      await _adminAuthService.createFirstAdmin();
      setState(() {
        _result = '✅ Premier admin créé avec succès!\n\n'
            'Email: rayague03@gmail.com\n'
            'Mot de passe: Admin@BLink2025!\n\n'
            'Vous pouvez maintenant vous connecter avec ces identifiants.';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Erreur: $e';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Elle créera un compte super_admin avec:\n'
                '• Email: rayague03@gmail.com\n'
                '• Mot de passe: Admin@BLink2025!\n\n'
                'Ces informations seront stockées de façon sécurisée dans Firestore.',
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
