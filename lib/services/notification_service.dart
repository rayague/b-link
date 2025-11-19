import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import '../models/contact.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    tzdata.initializeTimeZones();
    final String locationName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));

    // Request permissions (iOS and Android 13+)
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

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    // Si le payload contient un message, on le stocke pour que l'app puisse l'afficher
    if (response.payload != null && response.payload!.startsWith('message::')) {
      final message = response.payload!.substring(9); // Enlever "message::"
      _lastTappedMessage = message;
      print(
          '📋 Message disponible pour copie: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
    }
  }

  // Message de la dernière notification cliquée
  String? _lastTappedMessage;

  /// Récupère le dernier message de notification cliquée
  String? getLastTappedMessage() {
    final msg = _lastTappedMessage;
    _lastTappedMessage = null; // Réinitialiser après lecture
    return msg;
  }

  /// Envoie une notification de test immédiate
  Future<void> sendTestNotification() async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Notifications de test',
      channelDescription: 'Canal pour tester les notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      999999, // ID unique pour les tests
      '🔔 Test de notification',
      'Cette notification est un test. Le système fonctionne correctement ! ✅',
      details,
      payload: 'test_notification',
    );

    print('✅ Notification de test envoyée avec succès');
  }

  /// Envoie une notification de test avec un vrai message depuis la base de données
  Future<void> sendTestNotificationWithMessage({
    required Contact contact,
    required String message,
  }) async {
    if (!_initialized) await init();

    // Titre avec emoji selon la catégorie
    final categoryEmoji = {
      'son': '👦',
      'daughter': '👧',
      'friend': '👥',
      'mother': '❤️',
      'father': '👨',
      'brother': '👬',
      'sister': '👭',
      'colleague': '💼',
    };

    final emoji = categoryEmoji[contact.relation.toLowerCase()] ?? '🎂';
    final title = '$emoji Anniversaire de ${contact.name}';

    // Style Big Text pour afficher le message complet
    final androidDetails = AndroidNotificationDetails(
      'birthday_reminders',
      'Rappels d\'anniversaire',
      channelDescription: 'Notifications pour les anniversaires à venir',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      // Style étendu pour afficher le message complet
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: title,
        summaryText: '📝 Appuyez pour copier le message',
      ),
      // Permettre l'expansion automatique
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      999998, // ID unique pour les tests avec message
      title,
      message,
      details,
      payload: 'message::$message', // On stocke le message dans le payload
    );

    print(
        '✅ Notification test envoyée pour ${contact.name} (${contact.relation})');
    print('📝 Message complet: $message');
  }

  /// Schedule birthday reminders for a contact
  /// Sends notifications 2 times per day (9 AM & 6 PM) for 5 days before birthday + on birthday
  Future<void> scheduleBirthdayReminders(Contact contact, String locale) async {
    if (!_initialized) await init();

    // Vérifier que le contact a un ID
    if (contact.id == null) {
      print(
          '⚠️ Cannot schedule reminders: contact ID is null for ${contact.name}');
      return;
    }

    DateTime? birthDate;
    try {
      birthDate = DateTime.parse(contact.date);
    } catch (e) {
      print('Invalid date format for contact ${contact.name}');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    // Calculate next birthday
    var nextBirthday =
        tz.TZDateTime(tz.local, now.year, birthDate.month, birthDate.day);
    if (nextBirthday.isBefore(now)) {
      nextBirthday =
          tz.TZDateTime(tz.local, now.year + 1, birthDate.month, birthDate.day);
    }

    // Cancel existing notifications
    await cancelBirthdayReminders(contact.id!);

    // Schedule for 5 days before to birthday day
    for (int daysBefore = 5; daysBefore >= 0; daysBefore--) {
      final notifDate = nextBirthday.subtract(Duration(days: daysBefore));

      if (notifDate.isBefore(now)) continue;

      // Morning 9 AM
      final morning = tz.TZDateTime(
          tz.local, notifDate.year, notifDate.month, notifDate.day, 9, 0);
      if (morning.isAfter(now)) {
        await _scheduleNotification(
          contact: contact,
          scheduledDate: morning,
          daysBefore: daysBefore,
          locale: locale,
          isMorning: true,
        );
      }

      // Evening 6 PM (skip on birthday day)
      if (daysBefore > 0) {
        final evening = tz.TZDateTime(
            tz.local, notifDate.year, notifDate.month, notifDate.day, 18, 0);
        if (evening.isAfter(now)) {
          await _scheduleNotification(
            contact: contact,
            scheduledDate: evening,
            daysBefore: daysBefore,
            locale: locale,
            isMorning: false,
          );
        }
      }
    }
  }

  int _getNotificationId(int contactId, int daysBefore, bool isMorning) {
    return contactId * 100 + daysBefore * 2 + (isMorning ? 0 : 1);
  }

  Future<void> _scheduleNotification({
    required Contact contact,
    required tz.TZDateTime scheduledDate,
    required int daysBefore,
    required String locale,
    required bool isMorning,
  }) async {
    final id = _getNotificationId(contact.id!, daysBefore, isMorning);
    final message = _generateMessage(contact, daysBefore, locale, isMorning);

    await _plugin.zonedSchedule(
      id,
      message['title']!,
      message['body']!,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'birthday_reminders',
          'Rappels d\'anniversaire',
          channelDescription: 'Notifications pour les anniversaires à venir',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: contact.id.toString(),
    );
  }

  Map<String, String> _generateMessage(
      Contact contact, int daysBefore, String locale, bool isMorning) {
    final name = contact.name;
    final relation = contact.relation;

    if (daysBefore == 0) {
      return _getBirthdayMessage(name, relation, locale);
    } else if (isMorning) {
      return _getMorningMessage(name, relation, daysBefore, locale);
    } else {
      return _getEveningMessage(name, relation, daysBefore, locale);
    }
  }

  Map<String, String> _getBirthdayMessage(
      String name, String relation, String locale) {
    final messages = locale == 'fr'
        ? [
            {
              'title': '🎉 C\'est aujourd\'hui !',
              'body':
                  'L\'anniversaire de $name est aujourd\'hui ! N\'oubliez pas de souhaiter un joyeux anniversaire à votre $relation.'
            },
            {
              'title': '🎂 Joyeux anniversaire !',
              'body':
                  '$name fête son anniversaire aujourd\'hui ! Prenez le temps de lui souhaiter.'
            },
            {
              'title': '🥳 Jour spécial !',
              'body':
                  'Aujourd\'hui c\'est l\'anniversaire de $name ! Faites-lui plaisir avec un message.'
            },
          ]
        : [
            {
              'title': '🎉 It\'s today!',
              'body':
                  '$name\'s birthday is today! Don\'t forget to wish your $relation a happy birthday.'
            },
            {
              'title': '🎂 Happy Birthday!',
              'body':
                  '$name is celebrating their birthday today! Take time to wish them well.'
            },
          ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  Map<String, String> _getMorningMessage(
      String name, String relation, int daysBefore, String locale) {
    final frMessages = {
      5: [
        {
          'title': '📅 Dans 5 jours',
          'body':
              'L\'anniversaire de $name ($relation) est dans 5 jours. Temps de réfléchir à un cadeau !'
        }
      ],
      4: [
        {
          'title': '📅 Dans 4 jours',
          'body':
              'L\'anniversaire de $name approche ! Avez-vous trouvé le cadeau parfait ?'
        }
      ],
      3: [
        {
          'title': '📅 Dans 3 jours',
          'body':
              'L\'anniversaire de $name est dans 3 jours. Préparez quelque chose de spécial !'
        }
      ],
      2: [
        {
          'title': '📅 Après-demain',
          'body':
              'L\'anniversaire de $name ($relation) est après-demain ! Dernière chance pour le cadeau.'
        }
      ],
      1: [
        {
          'title': '📅 C\'est demain !',
          'body': 'L\'anniversaire de $name est demain ! Tout est prêt ?'
        }
      ],
    };
    final enMessages = {
      5: [
        {
          'title': '📅 In 5 days',
          'body':
              '$name\'s ($relation) birthday is in 5 days. Time to think about a gift!'
        }
      ],
      4: [
        {
          'title': '📅 In 4 days',
          'body':
              '$name\'s birthday is coming! Have you found the perfect gift?'
        }
      ],
      3: [
        {
          'title': '📅 In 3 days',
          'body': '$name\'s birthday is in 3 days. Prepare something special!'
        }
      ],
      2: [
        {
          'title': '📅 Day after tomorrow',
          'body':
              '$name\'s birthday is the day after tomorrow! Last chance for the gift.'
        }
      ],
      1: [
        {
          'title': '📅 It\'s tomorrow!',
          'body': '$name\'s birthday is tomorrow! Is everything ready?'
        }
      ],
    };
    final msgs = locale == 'fr' ? frMessages : enMessages;
    return msgs[daysBefore]![0];
  }

  Map<String, String> _getEveningMessage(
      String name, String relation, int daysBefore, String locale) {
    final frMessages = {
      5: [
        {
          'title': '🌙 Rappel du soir',
          'body':
              'N\'oubliez pas : anniversaire de $name dans 5 jours. Pensez à un cadeau !'
        }
      ],
      4: [
        {
          'title': '🌙 Rappel',
          'body': 'Plus que 4 jours avant l\'anniversaire de $name ($relation).'
        }
      ],
      3: [
        {
          'title': '🌙 Important',
          'body':
              'L\'anniversaire de $name approche (3 jours). Avez-vous tout préparé ?'
        }
      ],
      2: [
        {
          'title': '🌙 Urgent !',
          'body':
              'Après-demain c\'est l\'anniversaire de $name. Dernier rappel !'
        }
      ],
      1: [
        {
          'title': '🌙 Demain !',
          'body':
              'Dernier rappel : anniversaire de votre $relation $name demain.'
        }
      ],
    };
    final enMessages = {
      5: [
        {
          'title': '🌙 Evening reminder',
          'body': 'Don\'t forget: $name\'s birthday in 5 days. Think of a gift!'
        }
      ],
      4: [
        {
          'title': '🌙 Reminder',
          'body': 'Only 4 days until $name\'s ($relation) birthday.'
        }
      ],
      3: [
        {
          'title': '🌙 Important',
          'body': '$name\'s birthday is approaching (3 days). Ready?'
        }
      ],
      2: [
        {
          'title': '🌙 Urgent!',
          'body': '$name\'s birthday is the day after tomorrow. Last reminder!'
        }
      ],
      1: [
        {
          'title': '🌙 Tomorrow!',
          'body': 'Last reminder: your $relation $name\'s birthday tomorrow.'
        }
      ],
    };
    final msgs = locale == 'fr' ? frMessages : enMessages;
    return msgs[daysBefore]![0];
  }

  Future<void> cancelBirthdayReminders(int contactId) async {
    for (int daysBefore = 5; daysBefore >= 0; daysBefore--) {
      await _plugin.cancel(_getNotificationId(contactId, daysBefore, true));
      if (daysBefore > 0) {
        await _plugin.cancel(_getNotificationId(contactId, daysBefore, false));
      }
    }
  }

  Future<void> rescheduleAllReminders(
      List<Contact> contacts, String locale) async {
    for (final contact in contacts) {
      await scheduleBirthdayReminders(contact, locale);
    }
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();
}
