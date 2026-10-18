import 'package:shared_preferences/shared_preferences.dart';

/// Rappels possibles, en jours avant l'anniversaire (0 = le jour même).
///
/// La position dans cette liste fixe l'emplacement de l'identifiant de
/// notification (voir NotificationService.notificationId) : ne jamais
/// réordonner, seulement ajouter à la fin (10 places au plus).
const List<int> kReminderOffsets = [0, 1, 7, 2, 3, 14, 30];

/// Ordre d'affichage des choix (du plus tôt au jour même).
const List<int> kReminderOffsetsDisplay = [30, 14, 7, 3, 2, 1, 0];

/// Préférences des rappels d'anniversaire (mémorisées sur l'appareil, lues
/// aussi par la tâche d'arrière-plan).
class ReminderSettings {
  final int hour;
  final int minute;

  /// Jours avant l'anniversaire où prévenir (valeurs de [kReminderOffsets]).
  final Set<int> offsets;

  const ReminderSettings({
    this.hour = 9,
    this.minute = 0,
    this.offsets = const {0, 1},
  });

  bool get isEmpty => offsets.isEmpty;

  /// Rappels du plus tôt au plus tard (30 j, …, la veille, le jour même).
  List<int> get sortedOffsets =>
      [for (final o in kReminderOffsetsDisplay) if (offsets.contains(o)) o];

  ReminderSettings toggle(int offset) => copyWith(
        offsets: offsets.contains(offset)
            ? ({...offsets}..remove(offset))
            : {...offsets, offset},
      );

  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _offsetsKey = 'reminder_offsets';
  // Anciennes préférences (avant le choix libre des rappels).
  static const _legacyWeekKey = 'reminder_week_before';
  static const _legacyDayKey = 'reminder_day_before';

  static Future<ReminderSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      const d = ReminderSettings();
      final saved = p.getStringList(_offsetsKey);
      final Set<int> offsets;
      if (saved != null) {
        offsets = {
          for (final s in saved)
            if (kReminderOffsets.contains(int.tryParse(s))) int.parse(s),
        };
      } else {
        // Migration : le jour même était toujours prévu.
        offsets = {
          0,
          if (p.getBool(_legacyDayKey) ?? true) 1,
          if (p.getBool(_legacyWeekKey) ?? false) 7,
        };
      }
      return ReminderSettings(
        hour: (p.getInt(_hourKey) ?? d.hour).clamp(0, 23),
        minute: (p.getInt(_minuteKey) ?? d.minute).clamp(0, 59),
        offsets: offsets,
      );
    } catch (_) {
      return const ReminderSettings();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_hourKey, hour);
    await p.setInt(_minuteKey, minute);
    await p.setStringList(_offsetsKey, [for (final o in offsets) '$o']);
    await p.remove(_legacyWeekKey);
    await p.remove(_legacyDayKey);
  }

  ReminderSettings copyWith({int? hour, int? minute, Set<int>? offsets}) =>
      ReminderSettings(
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        offsets: offsets ?? this.offsets,
      );
}
