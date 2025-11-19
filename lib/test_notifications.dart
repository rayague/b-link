import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'models/contact.dart';
import 'utils/notification_permission_helper.dart';

/// Widget de test pour tester les notifications
///
/// Pour tester:
/// 1. Créer un contact avec anniversaire DEMAIN
/// 2. Attendre 9h ou 18h le lendemain
/// OU
/// 1. Modifier manuellement la date système de votre téléphone
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _status = '';

  Future<void> _scheduleTestNotification() async {
    setState(() => _status = '⏳ Programmation en cours...');

    final service = NotificationService();
    await service.init();

    // Créer un contact de test avec anniversaire DEMAIN
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final testContact = Contact(
      id: 99999, // ID de test unique
      name: 'Test Birthday',
      relation: 'ami',
      date:
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}',
    );

    await service.scheduleBirthdayReminders(testContact, 'fr');

    setState(() => _status = '✅ Notification programmée pour demain 9h!\n\n'
        'Contact: ${testContact.name}\n'
        'Date: ${testContact.date}\n\n'
        'Vous recevrez une notification demain à 9h et 18h.');
  }

  Future<void> _cancelTest() async {
    final service = NotificationService();
    await service.cancelBirthdayReminders(99999);
    setState(() => _status = '�️ Notifications test annulées');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.notifications_active,
                size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Test des notifications d\'anniversaire',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationPermissionHelper.checkAndRequestPermission(
                    context);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Vérifier les permissions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scheduleTestNotification,
              icon: const Icon(Icons.alarm_add),
              label: const Text('Programmer test pour DEMAIN'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cancelTest,
              icon: const Icon(Icons.cancel),
              label: const Text('Annuler les tests'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 30),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Note: Les notifications apparaîtront à 9h et 18h demain',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
