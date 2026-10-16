# Rappels d'anniversaire en arrière-plan

## Fonctionnement

- `NotificationService.planFor` calcule, pour chaque contact, jusqu'à trois
  rappels selon les réglages (`ReminderSettings`, accueil > Réglages > Rappels) :
  une semaine avant (désactivé par défaut), la veille (activé par défaut) et
  le jour J, à l'heure choisie (9h par défaut). Seuls les anniversaires des
  30 prochains jours sont programmés : le nombre de notifications en attente
  reste borné (iOS : 64 maximum ; Android : environ 500 alarmes).
- La fenêtre est reprogrammée à chaque ouverture de l'app
  (`ContactProvider.loadContacts`), à chaque changement de langue ou de
  réglage des rappels, et une fois
  par jour en arrière-plan par WorkManager (`lib/services/background_sync.dart`,
  tâche `com.rayague.b-link.reminders-refresh`).
- Les rappels utilisent `AndroidScheduleMode.inexactAllowWhileIdle` : pas de
  permission d'alarme exacte, réservée par Google Play aux réveils et agendas.
- Toucher un rappel ouvre la fiche du contact (payload `contact:<id>`).

## Configuration Android requise

Dans `android/app/src/main/AndroidManifest.xml` :

- permissions `POST_NOTIFICATIONS` et `RECEIVE_BOOT_COMPLETED` ;
- récepteurs `ScheduledNotificationReceiver` et
  `ScheduledNotificationBootReceiver` de `flutter_local_notifications`.
  **Sans eux, aucune notification programmée ne s'affiche** et les rappels ne
  survivent pas à un redémarrage.

## iOS

WorkManager sur iOS s'appuie sur `BGTaskScheduler` : déclarer l'identifiant
de tâche dans `Info.plist` (`BGTaskSchedulerPermittedIdentifiers`) et activer
le mode « Background fetch ». Sans cela, la fenêtre est tout de même
rafraîchie à chaque ouverture de l'app.
