import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:background_fetch/background_fetch.dart';
import 'sync_service.dart';

const String _taskName = "b_link_sync_task";

Future<void> initializeBackgroundSync() async {
  // Workmanager (Android)
  try {
    Workmanager().initialize(
      (task, inputData) async {
        // This function runs in a background isolate
        final svc = SyncService();
        await svc.processPending(limit: 50);
        // Workmanager plugin handles completion; return true
        return Future.value(true);
      },
      isInDebugMode: false,
    );
    Workmanager().registerPeriodicTask('sync-periodic', _taskName, frequency: const Duration(minutes: 15));
  } catch (e) {
    // ignore if not available
  }

  // background_fetch (iOS/Android alternative)
  try {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
      ),
      (String taskId) async {
        final svc = SyncService();
        await svc.processPending(limit: 50);
        BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        BackgroundFetch.finish(taskId);
      },
    );
  } catch (e) {
    // ignore
  }
}

// headless callback required by Android for Workmanager
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final svc = SyncService();
    await svc.processPending(limit: 50);
    return Future.value(true);
  });
}
