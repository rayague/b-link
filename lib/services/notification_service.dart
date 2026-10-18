import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/contact.dart';
import '../utils/birthday.dart';
import 'reminder_settings.dart';

/// Un rappel planifié (calcul pur, testable sans plugin).
class PlannedReminder {
  final int id;
  final int contactId;
  final DateTime when; // heure locale

  /// Jours avant l'anniversaire (0 = le jour même).
  final int daysBefore;

  const PlannedReminder(this.id, this.contactId, this.when, this.daysBefore);

  bool get isBirthdayDay => daysBefore == 0;
}

/// Rappels d'anniversaire des contacts.
///
/// Stratégie : les rappels choisis dans les réglages (du jour même à un mois
/// avant, à l'heure choisie ; 9 h par défaut) qui tombent dans les
/// [windowDays] prochains jours. La fenêtre est rafraîchie à chaque
/// ouverture de l'app et chaque jour en arrière-plan (voir
/// background_sync.dart). Seuls les [maxPending] plus proches sont
/// programmés : iOS n'en garde que 64, Android limite les alarmes.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int windowDays = 35;
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
    final payload = response.payload;
    if (payload != null && payload.startsWith(_routePrefix)) {
      _routeTaps.add(payload.substring(_routePrefix.length));
      return;
    }
    final id = _contactIdFrom(response.payload);
    if (id != null) _taps.add(id);
  }

  static const _routePrefix = 'route:';
  final StreamController<String> _routeTaps =
      StreamController<String>.broadcast();

  /// Touchers d'une notification push affichée au premier plan : l'écran à
  /// ouvrir (« /same-day » pour un nouveau jumeau, « /wishes » pour un vœu).
  Stream<String> get routeTaps => _routeTaps.stream;

  /// Affiche une notification push reçue alors que l'app est ouverte
  /// (Firebase Messaging ne le fait pas lui-même au premier plan).
  Future<void> showPush(
      {required String title, required String body, String? route}) async {
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
      payload: route == null ? null : '$_routePrefix$route',
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
  /// lève une ArgumentError). 200M * 10 < 2^31. Le dernier chiffre est la
  /// position du rappel dans [kReminderOffsets] (jour J = 0, veille = 1,
  /// semaine = 2, comme avant le choix libre).
  static int notificationId(int contactId, int daysBefore) {
    final slot = kReminderOffsets.indexOf(daysBefore);
    if (slot < 0) throw ArgumentError.value(daysBefore, 'daysBefore');
    return (contactId.abs() % 200000000) * 10 + slot;
  }

  /// Nombre maximal de rappels programmés à la fois.
  static int get maxPending =>
      defaultTargetPlatform == TargetPlatform.iOS ? 60 : 400;

  /// Rappels d'un contact à programmer à partir de [now] (pur, testable) :
  /// ceux des [ReminderSettings.offsets] qui tombent dans la fenêtre.
  static List<PlannedReminder> planFor(Contact contact, DateTime now,
      [ReminderSettings settings = const ReminderSettings()]) {
    final id = contact.id;
    final birthDate = parseBirthDate(contact.date);
    if (id == null || birthDate == null) return const [];
    final horizon = now.add(const Duration(days: windowDays));
    final day = nextBirthday(birthDate, now);
    final plan = <PlannedReminder>[];
    for (final offset in settings.sortedOffsets) {
      final at = DateTime(
          day.year, day.month, day.day - offset, settings.hour, settings.minute);
      if (at.isAfter(now)) {
        plan.add(PlannedReminder(notificationId(id, offset), id, at, offset));
      }
    }
    // Dès que le premier rappel d'un anniversaire entre dans la fenêtre,
    // tous ses rappels sont programmés ensemble : la veille et le jour J ne
    // dépendent pas du rafraîchissement quotidien (que certains téléphones
    // bloquent).
    if (plan.isEmpty || plan.first.when.isAfter(horizon)) return const [];
    return plan;
  }

  /// Tous les rappels, du plus proche au plus lointain, limités à [limit].
  static List<PlannedReminder> planAll(
      List<Contact> contacts, DateTime now, ReminderSettings settings,
      {int? limit}) {
    final all = [
      for (final c in contacts) ...planFor(c, now, settings),
    ]..sort((a, b) => a.when.compareTo(b.when));
    return limit == null || all.length <= limit ? all : all.sublist(0, limit);
  }

  static const _channel = AndroidNotificationDetails(
    'birthday_reminders',
    'Rappels d\'anniversaire',
    channelDescription: 'Notifications pour les anniversaires à venir',
    importance: Importance.high,
    priority: Priority.high,
  );

  NotificationDetails _details(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.channelId,
          _channel.channelName,
          channelDescription: _channel.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      );

  Future<void> _schedule(PlannedReminder r, String name, String locale) async {
    final text = reminderText(name, r.daysBefore, locale);
    await _plugin.zonedSchedule(
      r.id,
      text.title,
      text.body,
      tz.TZDateTime(tz.local, r.when.year, r.when.month, r.when.day,
          r.when.hour, r.when.minute),
      _details(text.body),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$_payloadPrefix${r.contactId}',
    );
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
      await _schedule(r, contact.name, locale);
    }
  }

  /// Texte d'un rappel [daysBefore] jours avant l'anniversaire de [name].
  static ({String title, String body}) reminderText(
      String name, int daysBefore, String locale) {
    final fr = locale == 'fr';
    switch (daysBefore) {
      case 0:
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
      case 1:
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
      case 7:
        return fr
            ? (
                title: '📅 Dans une semaine : anniversaire de $name',
                body: 'Le moment idéal pour penser à une petite attention 🎁'
              )
            : (
                title: '📅 One week to go: $name\'s birthday',
                body: 'The perfect time to think of a little something 🎁'
              );
      case 14:
        return fr
            ? (
                title: '🗓️ Dans deux semaines : anniversaire de $name',
                body: 'Assez de temps pour organiser une fête ou commander '
                    'un cadeau qui fera mouche 🎈'
              )
            : (
                title: '🗓️ Two weeks to go: $name\'s birthday',
                body: 'Plenty of time to plan a party or order a gift '
                    'they\'ll love 🎈'
              );
      case 30:
        return fr
            ? (
                title: '✨ Dans un mois : anniversaire de $name',
                body: 'Notez-le : un mois pour imaginer quelque chose '
                    'd\'inoubliable 💫'
              )
            : (
                title: '✨ One month to go: $name\'s birthday',
                body: 'Mark it down: a month to dream up something '
                    'unforgettable 💫'
              );
      default:
        return fr
            ? (
                title: '⏳ Dans $daysBefore jours : anniversaire de $name',
                body: 'Encore un peu de temps pour préparer une jolie '
                    'surprise 🎁'
              )
            : (
                title: '⏳ $daysBefore days to go: $name\'s birthday',
                body: 'Still a little time to prepare a lovely surprise 🎁'
              );
    }
  }

  Future<void> cancelBirthdayReminders(int contactId) async {
    for (final offset in kReminderOffsets) {
      await _plugin.cancel(notificationId(contactId, offset));
    }
  }

  /// Annule les rappels en attente puis reprogramme la fenêtre (les
  /// [maxPending] plus proches). Les notifications déjà affichées restent
  /// dans le tiroir.
  Future<void> rescheduleAllReminders(
      List<Contact> contacts, String locale) async {
    if (!_initialized) await init(requestPermissions: false);
    await _plugin.cancelAllPendingNotifications();
    final settings = await ReminderSettings.load();
    final names = {
      for (final c in contacts)
        if (c.id != null) c.id!: c.name,
    };
    for (final r in planAll(contacts, DateTime.now(), settings,
        limit: maxPending)) {
      try {
        await _schedule(r, names[r.contactId] ?? '', locale);
      } catch (e) {
        debugPrint('❌ Rappel non programmé (contact ${r.contactId}): $e');
      }
    }
  }

  /// Les notifications sont-elles autorisées pour l'app ? (null : inconnu)
  Future<bool?> notificationsEnabled() async {
    if (!_initialized) await init(requestPermissions: false);
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.areNotificationsEnabled();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return (await ios.checkPermissions())?.isEnabled;
    } catch (_) {}
    return null;
  }

  /// Redemande l'autorisation (Android 13+, iOS). Renvoie l'état obtenu.
  Future<bool?> requestPermission() async {
    if (!_initialized) await init(requestPermissions: false);
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {}
    return null;
  }

  /// Affiche tout de suite un rappel d'exemple (réglages : « Tester »).
  Future<void> showTestReminder(String name, String locale) async {
    if (!_initialized) await init(requestPermissions: false);
    final text = reminderText(name, 0, locale);
    await _plugin.show(-4, text.title, text.body, _details(text.body));
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();
}
