import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/contact.dart';
import '../utils/birthday.dart';
import 'reminder_settings.dart';

/// Type de rappel. L'index sert de "slot" dans l'ID de notification : ne pas
/// réordonner (jour J = 0 et veille = 1 existaient déjà).
enum ReminderKind { birthdayDay, dayBefore, weekBefore }

/// Un rappel planifié (calcul pur, testable sans plugin).
class PlannedReminder {
  final int id;
  final DateTime when; // heure locale
  final ReminderKind kind;
  const PlannedReminder(this.id, this.when, this.kind);

  bool get isBirthdayDay => kind == ReminderKind.birthdayDay;
}

/// Rappels d'anniversaire des contacts.
///
/// Stratégie : jusqu'à 3 notifications par contact (une semaine avant si
/// activé, la veille si activé, et le jour J, à l'heure choisie ; 9h par défaut),
/// uniquement pour les anniversaires des [windowDays] prochains jours. La
/// fenêtre est rafraîchie à chaque ouverture de l'app et chaque jour en
/// arrière-plan (voir background_sync.dart). Le nombre de notifications en
/// attente reste ainsi borné (iOS : 64 max ; Android : ~500 alarmes).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int windowDays = 30;
  static const String _payloadPrefix = 'contact:';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// IDs des contacts dont la notification a été touchée (app ouverte).
  final StreamController<int> _taps = StreamController<int>.broadcast();
  Stream<int> get contactTaps => _taps.stream;

  /// Contact dont la notification a lancé l'app (app fermée), à consommer
  /// une fois l'interface prête.
  int? _launchContactId;
  int? takeLaunchContactId() {
    final id = _launchContactId;
    _launchContactId = null;
    return id;
  }

  /// [requestPermissions] à `false` en arrière-plan (pas d'UI possible).
  Future<void> init({bool requestPermissions = true}) async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Fuseau inconnu de la base `timezone` : on garde UTC plutôt que de
      // bloquer toutes les notifications.
      debugPrint('⚠️ Fuseau horaire non résolu, UTC utilisé: $e');
      tz.setLocalLocation(tz.UTC);
    }

    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchContactId = _contactIdFrom(launch!.notificationResponse?.payload);
      }
    } catch (_) {}

    if (requestPermissions) {
      // iOS + Android 13+. Pas d'alarmes exactes : un rappel d'anniversaire
      // n'a pas besoin d'être à la minute près, et Google Play réserve
      // USE_EXACT_ALARM aux réveils/agendas.
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } catch (_) {}
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (_) {}
    }

    _initialized = true;
  }

  static int? _contactIdFrom(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    return int.tryParse(payload.substring(_payloadPrefix.length));
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == _openSameDayPayload) {
      _sameDayTaps.add(null);
      return;
    }
    final id = _contactIdFrom(response.payload);
    if (id != null) _taps.add(id);
  }

  static const _openSameDayPayload = 'open:same-day';
  final StreamController<void> _sameDayTaps = StreamController<void>.broadcast();

  /// Touchers d'une notification push affichée au premier plan (nouveau
  /// jumeau) : ouvrir "Même jour".
  Stream<void> get sameDayTaps => _sameDayTaps.stream;

  /// Affiche une notification push reçue alors que l'app est ouverte
  /// (Firebase Messaging ne le fait pas lui-même au premier plan).
  Future<void> showPush(
      {required String title,
      required String body,
      bool openSameDay = false}) async {
    if (!_initialized) await init(requestPermissions: false);
    await _plugin.show(
      // ID négatif dérivé du texte : pas de collision avec les rappels.
      -3 - (title.hashCode & 0x0FFFFFFF),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'twins',
          'Jumeaux d\'anniversaire',
          channelDescription: 'Nouvelles personnes nées le même jour que vous',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: openSameDay ? _openSameDayPayload : null,
    );
  }

  /// Envoie une notification de test immédiate
  Future<void> sendTestNotification() async {
    if (!_initialized) await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Notifications de test',
        channelDescription: 'Canal pour tester les notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true),
    );

    // ID négatif : ne peut jamais entrer en collision avec un rappel.
    await _plugin.show(
      -1,
      '🔔 Test de notification',
      'Cette notification est un test. Le système fonctionne correctement ! ✅',
      details,
      payload: 'test_notification',
    );
  }

  /// Envoie une notification de test avec un vrai message (écran admin).
  Future<void> sendTestNotificationWithMessage({
    required Contact contact,
    required String message,
  }) async {
    if (!_initialized) await init();
    final title = '🎂 Anniversaire de ${contact.name}';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'birthday_reminders',
        'Rappels d\'anniversaire',
        channelDescription: 'Notifications pour les anniversaires à venir',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation:
            BigTextStyleInformation(message, contentTitle: title),
      ),
      iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _plugin.show(-2, title, message, details);
  }

  /// IDs de notification : doivent tenir sur 32 bits signés (sinon le plugin
  /// lève une ArgumentError). 200M * 10 < 2^31.
  static int notificationId(int contactId, ReminderKind kind) =>
      (contactId.abs() % 200000000) * 10 + kind.index;

  static const _daysBefore = {
    ReminderKind.weekBefore: 7,
    ReminderKind.dayBefore: 1,
    ReminderKind.birthdayDay: 0,
  };

  /// Calcule les rappels d'un contact à partir de [now] selon les
  /// [settings] (pur, testable).
  static List<PlannedReminder> planFor(Contact contact, DateTime now,
      [ReminderSettings settings = const ReminderSettings()]) {
    final id = contact.id;
    final birthDate = parseBirthDate(contact.date);
    if (id == null || birthDate == null) return const [];
    if (daysUntilBirthday(birthDate, now) > windowDays) return const [];

    final day = nextBirthday(birthDate, now);
    final kinds = [
      if (settings.weekBefore) ReminderKind.weekBefore,
      if (settings.dayBefore) ReminderKind.dayBefore,
      ReminderKind.birthdayDay,
    ];
    return [
      for (final kind in kinds)
        PlannedReminder(
          notificationId(id, kind),
          DateTime(day.year, day.month, day.day - _daysBefore[kind]!,
              settings.hour, settings.minute),
          kind,
        ),
    ].where((r) => r.when.isAfter(now)).toList();
  }

  /// Programme les rappels d'un contact (annule d'abord les anciens).
  /// [settings] est relu depuis l'appareil s'il n'est pas fourni.
  Future<void> scheduleBirthdayReminders(Contact contact, String locale,
      {ReminderSettings? settings}) async {
    if (!_initialized) await init();
    if (contact.id == null) return;
    await cancelBirthdayReminders(contact.id!);
    final s = settings ?? await ReminderSettings.load();

    for (final r in planFor(contact, DateTime.now(), s)) {
      final text = _text(contact.name, r.kind, locale);
      await _plugin.zonedSchedule(
        r.id,
        text.title,
        text.body,
        tz.TZDateTime(tz.local, r.when.year, r.when.month, r.when.day,
            r.when.hour, r.when.minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'birthday_reminders',
            'Rappels d\'anniversaire',
            channelDescription: 'Notifications pour les anniversaires à venir',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$_payloadPrefix${contact.id}',
      );
    }
  }

  static ({String title, String body}) _text(
      String name, ReminderKind kind, String locale) {
    final fr = locale == 'fr';
    if (kind == ReminderKind.weekBefore) {
      return fr
          ? (
              title: '📅 Dans une semaine : anniversaire de $name',
              body: 'Le moment idéal pour penser à une petite attention 🎁'
            )
          : (
              title: '📅 One week to go: $name\'s birthday',
              body: 'The perfect time to think of a little something 🎁'
            );
    }
    if (kind == ReminderKind.birthdayDay) {
      return fr
          ? (
              title: '🎉 Aujourd\'hui, c\'est l\'anniversaire de $name !',
              body: 'Quelques mots de vous peuvent illuminer toute sa journée. '
                  'Touchez pour trouver le message parfait 💛'
            )
          : (
              title: '🎉 Today is $name\'s birthday!',
              body: 'A few words from you can light up their whole day. '
                  'Tap to find the perfect message 💛'
            );
    }
    return fr
        ? (
            title: '🎂 Demain, c\'est l\'anniversaire de $name',
            body: 'Préparez-lui un mot doux : ce genre d\'attention '
                'ne s\'oublie jamais ✨'
          )
        : (
            title: '🎂 Tomorrow is $name\'s birthday',
            body: 'Get a sweet message ready: this kind of attention '
                'is never forgotten ✨'
          );
  }

  Future<void> cancelBirthdayReminders(int contactId) async {
    for (final kind in ReminderKind.values) {
      await _plugin.cancel(notificationId(contactId, kind));
    }
  }

  /// Annule tout puis reprogramme la fenêtre. Le `cancelAll` purge aussi les
  /// rappels de l'ancienne version (11 par contact, autres IDs).
  Future<void> rescheduleAllReminders(
      List<Contact> contacts, String locale) async {
    if (!_initialized) await init(requestPermissions: false);
    await _plugin.cancelAll();
    final settings = await ReminderSettings.load();
    for (final contact in contacts) {
      try {
        await scheduleBirthdayReminders(contact, locale, settings: settings);
      } catch (e) {
        debugPrint('❌ Rappels non programmés pour ${contact.name}: $e');
      }
    }
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();
}
