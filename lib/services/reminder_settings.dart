import 'package:shared_preferences/shared_preferences.dart';

/// Préférences des rappels d'anniversaire (mémorisées sur l'appareil, lues
/// aussi par la tâche d'arrière-plan).
class ReminderSettings {
  final int hour;
  final int minute;

  /// Rappel une semaine avant (le temps de préparer un cadeau).
  final bool weekBefore;

  /// Rappel la veille.
  final bool dayBefore;

  const ReminderSettings({
    this.hour = 9,
    this.minute = 0,
    this.weekBefore = false,
    this.dayBefore = true,
  });

  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _weekKey = 'reminder_week_before';
  static const _dayKey = 'reminder_day_before';

  static Future<ReminderSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      const d = ReminderSettings();
      return ReminderSettings(
        hour: (p.getInt(_hourKey) ?? d.hour).clamp(0, 23),
        minute: (p.getInt(_minuteKey) ?? d.minute).clamp(0, 59),
        weekBefore: p.getBool(_weekKey) ?? d.weekBefore,
        dayBefore: p.getBool(_dayKey) ?? d.dayBefore,
      );
    } catch (_) {
      return const ReminderSettings();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_hourKey, hour);
    await p.setInt(_minuteKey, minute);
    await p.setBool(_weekKey, weekBefore);
    await p.setBool(_dayKey, dayBefore);
  }

  ReminderSettings copyWith(
          {int? hour, int? minute, bool? weekBefore, bool? dayBefore}) =>
      ReminderSettings(
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        weekBefore: weekBefore ?? this.weekBefore,
        dayBefore: dayBefore ?? this.dayBefore,
      );
}
