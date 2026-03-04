import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:background_fetch/background_fetch.dart';
import 'sync_service.dart';

const String _taskName = "b_link_sync_task";

Future<void> initializeBackgroundSync() async {
  // Workmanager (Android)
  try {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    await Workmanager().registerPeriodicTask(
      'sync-periodic',
      _taskName,
      frequency: const Duration(minutes: 15),
    );
  } catch (e) {
    debugPrint('⚠️ WorkManager initialization failed: $e');
    // ignore if not available
  }

  // background_fetch (iOS/Android alternative)
  try {
    await BackgroundFetch.configure(
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
    debugPrint('⚠️ BackgroundFetch initialization failed: $e');
    // ignore
  }
}

// headless callback required by Android for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final svc = SyncService();
    await svc.processPending(limit: 50);
    return Future.value(true);
  });
}
