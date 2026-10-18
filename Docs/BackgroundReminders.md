# Rappels d'anniversaire en arrière-plan

## Fonctionnement

- `NotificationService.planFor` calcule les rappels d'un contact selon les
  réglages (`ReminderSettings`, accueil > Réglages > Rappels) : l'heure
  (9 h par défaut) et n'importe quelle combinaison parmi le jour même, la
  veille, 2 et 3 jours, 1 et 2 semaines, 1 mois avant (par défaut : la veille
  et le jour même). Les anciens réglages (veille / semaine) sont migrés.
- Dès que le premier rappel d'un anniversaire tombe dans les 35 prochains
  jours, **tous** ses rappels sont programmés ensemble : la veille et le jour J
  ne dépendent pas du rafraîchissement quotidien, que certains téléphones
  bloquent.
- `planAll` ne garde que les rappels les plus proches : 60 sur iOS (le
  système n'en conserve que 64), 400 sur Android.
- Reprogrammer annule seulement les rappels en attente
  (`cancelAllPendingNotifications`) : les notifications déjà affichées
  restent dans le tiroir.
- Identifiants : `contactId × 10 + position` dans `kReminderOffsets` (jour J
  = 0, veille = 1, semaine = 2, comme avant). Ne jamais réordonner cette liste.
- Les réglages signalent si les notifications sont bloquées pour l'app et
  proposent une notification d'essai.
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
