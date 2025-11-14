import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionHelper {
  static Future<bool> checkAndRequestPermission(BuildContext context) async {
    // Vérifier si les permissions sont accordées
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      print('✅ Permissions notifications: ACCORDÉES');
      return true;
    }
    
    if (status.isDenied) {
      print('⚠️ Permissions notifications: REFUSÉES - Demande...');
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      print('❌ Permissions notifications: BLOQUÉES DÉFINITIVEMENT');
      // Afficher dialogue pour aller dans les paramètres
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔔 Notifications désactivées'),
            content: const Text(
              'Les notifications sont bloquées dans les paramètres.\n\n'
              'Pour recevoir les rappels d\'anniversaire:\n'
              '1. Allez dans Paramètres\n'
              '2. Applications → B-Link\n'
              '3. Notifications → Activer',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Plus tard'),
              ),
              ElevatedButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Ouvrir Paramètres'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    
    return false;
  }
  
  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.blue),
            SizedBox(width: 12),
            Text('Activer les notifications?'),
          ],
        ),
        content: const Text(
          '🎂 Recevez des rappels pour ne jamais oublier un anniversaire!\n\n'
          '• 5 jours avant\n'
          '• Le jour J à 9h\n'
          '• Messages personnalisés',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Pas maintenant'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await checkAndRequestPermission(context);
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }
}
