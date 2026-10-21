import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../providers/locale_provider.dart';
import 'db_helper.dart';
import 'notification_service.dart';

// Sur iOS, c'est l'identifiant BGTaskScheduler (voir ios/Runner/AppDelegate.swift
// et Info.plist) : les trois doivent rester identiques.
const String _uniqueName = 'com.rayague.b-link.reminders-refresh';
const String _taskName = 'b_link_refresh_reminders';

/// Rafraîchit chaque jour la fenêtre des rappels d'anniversaire, même si
/// l'app n'est pas ouverte (les rappels ne sont programmés que pour les
/// [NotificationService.windowDays] prochains jours).
Future<void> initializeBackgroundReminders() async {
  try {
    await Workmanager().initialize(callbackDispatcher);
    // Tâches des versions précédentes (synchro toutes les 15 min, ancien nom).
    for (final legacy in ['sync-periodic', 'reminders-daily-refresh']) {
      await Workmanager().cancelByUniqueName(legacy);
    }
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: const Duration(hours: 24),
      // Ne pas relancer le compteur à chaque ouverture de l'app.
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint('⚠️ WorkManager initialization failed: $e');
  }
}

/// Reprogramme les rappels à partir de la base locale.
Future<void> refreshReminders() async {
  final contacts = await DBHelper().getContacts();
  final locale = await LocaleProvider.savedLanguageCode();
  final notifications = NotificationService();
  await notifications.init(requestPermissions: false);
  await notifications.rescheduleAllReminders(contacts, locale);
}

// headless callback required by Android for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await refreshReminders();
      return true;
    } catch (e) {
      debugPrint('❌ Rafraîchissement des rappels: $e');
      return false; // WorkManager réessaiera
    }
  });
}
