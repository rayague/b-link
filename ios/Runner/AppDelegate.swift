import Flutter
import UIKit
import flutter_local_notifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Doit correspondre à `_uniqueName` dans lib/services/background_sync.dart
  /// et à BGTaskSchedulerPermittedIdentifiers dans Info.plist.
  static let remindersRefreshTask = "com.rayague.b-link.reminders-refresh"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Les tâches d'arrière-plan tournent dans un moteur Flutter séparé : il
    // faut y enregistrer les plugins (base SQLite, notifications...).
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Rafraîchissement quotidien de la fenêtre des rappels (BGTaskScheduler).
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: AppDelegate.remindersRefreshTask,
      earliestBeginInSeconds: NSNumber(value: 12 * 60 * 60))

    // Afficher les rappels même quand l'app est au premier plan.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
