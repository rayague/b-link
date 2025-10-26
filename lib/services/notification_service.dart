import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));

    tzdata.initializeTimeZones();
    final String locationName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));

    // Request permissions (iOS and Android 13+)
    try {
      // iOS
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}

    try {
      // Android 13+
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
    } catch (_) {}

    _initialized = true;
  }

  Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    await _plugin.zonedSchedule(id, title, body, scheduled, const NotificationDetails(android: AndroidNotificationDetails('default','Default',importance: Importance.high)), androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> scheduleSpecificDate(int id, String title, String body, tz.TZDateTime dateTime) async {
    await _plugin.zonedSchedule(id, title, body, dateTime, const NotificationDetails(android: AndroidNotificationDetails('default','Default',importance: Importance.high)), androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
}
