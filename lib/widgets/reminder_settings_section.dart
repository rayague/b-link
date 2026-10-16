import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../services/messaging_service.dart';
import '../services/reminder_settings.dart';

/// Réglages des rappels : heure, rappel une semaine avant, rappel la veille.
/// Chaque changement est enregistré puis tous les rappels sont reprogrammés.
class ReminderSettingsSection extends StatefulWidget {
  const ReminderSettingsSection({super.key});

  @override
  State<ReminderSettingsSection> createState() =>
      _ReminderSettingsSectionState();
}

class _ReminderSettingsSectionState extends State<ReminderSettingsSection> {
  ReminderSettings? _settings;
  bool _notifyNewTwins = true;

  @override
  void initState() {
    super.initState();
    ReminderSettings.load().then((s) {
      if (mounted) setState(() => _settings = s);
    });
    MessagingService().notifyNewTwins().then((v) {
      if (mounted) setState(() => _notifyNewTwins = v);
    });
  }

  Future<void> _update(ReminderSettings next) async {
    setState(() => _settings = next);
    await next.save();
    if (!mounted) return;
    final locale = context.read<LocaleProvider>().locale.languageCode;
    await context.read<ContactProvider>().rescheduleAllReminders(locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = _settings;
    if (s == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final time = TimeOfDay(hour: s.hour, minute: s.minute);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.translate('remindersTitle'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_rounded),
          title: Text(l10n.translate('reminderTime')),
          trailing: Text(time.format(context),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () async {
            final picked =
                await showTimePicker(context: context, initialTime: time);
            if (picked != null) {
              await _update(
                  s.copyWith(hour: picked.hour, minute: picked.minute));
            }
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.card_giftcard_rounded),
          title: Text(l10n.translate('reminderWeekBefore')),
          subtitle: Text(l10n.translate('reminderWeekBeforeDesc')),
          value: s.weekBefore,
          onChanged: (v) => _update(s.copyWith(weekBefore: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_active_outlined),
          title: Text(l10n.translate('reminderDayBefore')),
          subtitle: Text(l10n.translate('reminderDayBeforeDesc')),
          value: s.dayBefore,
          onChanged: (v) => _update(s.copyWith(dayBefore: v)),
        ),
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
