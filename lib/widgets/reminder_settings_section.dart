import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_settings.dart';
import '../theme/app_theme.dart';
import '../utils/birthday.dart';
import '../utils/birthday_labels.dart';
import 'ui/components.dart';

/// Réglages des rappels : heure, et quand être prévenu (du jour même à un
/// mois avant, au choix). Chaque changement est enregistré puis tous les
/// rappels sont reprogrammés.
class ReminderSettingsSection extends StatefulWidget {
  const ReminderSettingsSection({super.key, this.notifications});

  /// Remplaçable dans les tests.
  final NotificationService? notifications;

  @override
  State<ReminderSettingsSection> createState() =>
      _ReminderSettingsSectionState();
}

class _ReminderSettingsSectionState extends State<ReminderSettingsSection> {
  ReminderSettings? _settings;
  bool _notifyNewTwins = true;
  bool? _allowed;

  NotificationService get _notifications =>
      widget.notifications ?? NotificationService();

  @override
  void initState() {
    super.initState();
    ReminderSettings.load().then((s) {
      if (mounted) setState(() => _settings = s);
    });
    MessagingService().notifyNewTwins().then((v) {
      if (mounted) setState(() => _notifyNewTwins = v);
    }).catchError((_) {});
    _notifications.notificationsEnabled().then((v) {
      if (mounted) setState(() => _allowed = v);
    }).catchError((_) {});
  }

  Future<void> _update(ReminderSettings next) async {
    setState(() => _settings = next);
    await next.save();
    if (!mounted) return;
    final locale = context.read<LocaleProvider>().locale.languageCode;
    await context.read<ContactProvider>().rescheduleAllReminders(locale);
  }

  Future<void> _allow() async {
    final granted = await _notifications.requestPermission();
    if (mounted) setState(() => _allowed = granted ?? _allowed);
  }

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    await _notifications.showTestReminder(
        l10n.translate('testReminderName'), l10n.locale.languageCode);
  }

  static String _offsetLabel(AppLocalizations l10n, int offset) =>
      switch (offset) {
        0 => l10n.translate('remindSameDay'),
        1 => l10n.translate('remindDayBefore'),
        7 => l10n.translate('remindWeekBefore'),
        14 => l10n.translate('remindTwoWeeksBefore'),
        30 => l10n.translate('remindMonthBefore'),
        _ => l10n.translate('remindDaysBefore').replaceAll('{n}', '$offset'),
      };

  /// « Pour Camille (21 mars) : le 20 et le 21 mars, à 09:00. »
  String _preview(AppLocalizations l10n, ReminderSettings s) {
    final now = DateTime.now();
    final contacts = context.read<ContactProvider>().contacts;
    String name = l10n.translate('testReminderName');
    DateTime day = DateTime(now.year + 1, 3, 21);
    final upcoming = context.read<ContactProvider>().upcoming(366, now: now);
    if (upcoming.isNotEmpty && contacts.isNotEmpty) {
      final c = upcoming.first;
      name = c.name.split(' ').first;
      day = nextBirthday(parseBirthDate(c.date)!, now);
    }
    final dates = [
      for (final o in s.sortedOffsets)
        dayMonthLabel(l10n, DateTime(day.year, day.month, day.day - o)),
    ];
    final time = TimeOfDay(hour: s.hour, minute: s.minute).format(context);
    return l10n
        .translate('reminderPreview')
        .replaceAll('{name}', name)
        .replaceAll('{date}', dayMonthLabel(l10n, day))
        .replaceAll('{dates}', dates.join(', '))
        .replaceAll('{time}', time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final s = _settings;
    if (s == null) {
      return const Padding(
        padding: EdgeInsets.all(Space.l),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final time = TimeOfDay(hour: s.hour, minute: s.minute);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_allowed == false) ...[
          NoticeCard(
            icon: Icons.notifications_off_outlined,
            tone: Tone.danger,
            text: l10n.translate('notificationsBlocked'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed: _allow,
                child: Text(l10n.translate('allowNotifications'))),
          ),
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_rounded),
          title: Text(l10n.translate('reminderTime')),
          trailing: Text(time.format(context), style: t.titleSmall),
          onTap: () async {
            final picked =
                await showTimePicker(context: context, initialTime: time);
            if (picked != null) {
              await _update(
                  s.copyWith(hour: picked.hour, minute: picked.minute));
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: Space.xs, bottom: Space.s),
          child: Text(l10n.translate('remindWhen'), style: t.bodySmall),
        ),
        Wrap(
          spacing: Space.s,
          runSpacing: Space.s,
          children: [
            for (final o in kReminderOffsetsDisplay)
              FilterChip(
                label: Text(_offsetLabel(l10n, o)),
                selected: s.offsets.contains(o),
                onSelected: (_) => _update(s.toggle(o)),
              ),
          ],
        ),
        const SizedBox(height: Space.m),
        if (s.isEmpty)
          NoticeCard(
            icon: Icons.notifications_paused_outlined,
            tone: Tone.danger,
            text: l10n.translate('noReminderSelected'),
          )
        else
          Text(_preview(l10n, s), style: t.bodySmall),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _test,
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: Text(l10n.translate('testReminder')),
          ),
        ),
        const Divider(),
        // Préférence du compte (lue par le serveur), pas de l'appareil.
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.group_add_outlined),
          title: Text(l10n.translate('newTwinsSetting')),
          subtitle: Text(l10n.translate('newTwinsSettingDesc')),
          value: _notifyNewTwins,
          onChanged: (v) async {
            setState(() => _notifyNewTwins = v);
            try {
              await MessagingService().setNotifyNewTwins(v);
            } catch (_) {
              if (mounted) setState(() => _notifyNewTwins = !v);
            }
          },
        ),
      ],
    );
  }
}
