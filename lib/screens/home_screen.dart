import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../services/analytics_service.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday.dart';
import '../utils/birthday_labels.dart';
import '../utils/relations.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/message_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/reminder_settings_section.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Accueil : l'anniversaire du jour (ou le prochain), les suivants, et
/// l'accès aux autres espaces.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Fenêtre des anniversaires listés sur l'accueil.
  static const _horizonDays = 30;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'HomeScreen');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final contacts = context.watch<ContactProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final now = DateTime.now();

    final upcoming = [
      for (final contact in contacts.upcoming(_horizonDays, now: now))
        (contact, daysUntilBirthday(parseBirthDate(contact.date)!, now)),
    ];
    final today = [for (final u in upcoming) if (u.$2 == 0) u.$1];
    final later = [for (final u in upcoming) if (u.$2 > 0) u];
    // Le premier à venir est déjà sur la carte principale s'il n'y a pas
    // d'anniversaire aujourd'hui.
    final listed = later.skip(today.isEmpty ? 1 : 0).take(5).toList();
    final firstName = profile?.givenName?.trim().isNotEmpty == true
        ? profile!.givenName!.trim()
        : (profile?.name.trim().split(RegExp(r'\s+')).first ?? '');

    return AppScaffold(
      actions: [
        IconButton(
          tooltip: l10n.translate('settings'),
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => showGlassSheet<void>(
            context,
            builder: (_) => const SettingsSheet(),
          ),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: AppScaffold.pagePadding(context, top: Space.l),
              children: [
                Text(
                  DateFormat.MMMMEEEEd(l10n.locale.languageCode)
                      .format(now)
                      .toUpperCase(),
                  style: t.labelSmall?.copyWith(color: c.onSurfaceVariant),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  firstName.isEmpty
                      ? l10n.translate('helloNoName')
                      : l10n.translate('hello').replaceAll('{name}', firstName),
                  style: t.headlineMedium,
                ),
                const SizedBox(height: Space.xl),
                _HeroCard(today: today, next: later.isEmpty ? null : later.first),
                const SizedBox(height: Space.m),
                _StatsRow(contacts: contacts.contacts, now: now),
                if (listed.isNotEmpty) ...[
                  SectionHeader(
                    l10n.translate('upcomingTitle'),
                    actionLabel: l10n.translate('viewAll'),
                    onAction: () => Navigator.of(context).pushNamed('/list'),
                  ),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    child: Column(
                      children: [
                        for (final (i, (contact, days)) in listed.indexed) ...[
                          if (i > 0) const Divider(indent: 72),
                          _UpcomingTile(contact: contact, days: days),
                        ],
                      ],
                    ),
                  ),
                ],
                SectionHeader(l10n.translate('exploreTitle')),
                const _ExploreGrid(),
              ],
            ),
          ),
          const OfflineBanner(),
        ],
      ),
    );
  }
}

/// Carte principale : les anniversaires du jour, sinon le prochain.
class _HeroCard extends StatelessWidget {
  final List<Contact> today;
  final (Contact, int)? next;
  const _HeroCard({required this.today, required this.next});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    if (today.isNotEmpty) {
      final first = today.first;
      final names = today.map((x) => x.name).join(', ');
      final birth = parseBirthDate(first.date);
      final age = birth == null ? null : ageAtNextBirthday(birth, DateTime.now());
      return GlassCard(
        tint: c.secondary,
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pill(l10n.translate('todayShort'),
                tone: Tone.accent, icon: Icons.cake_outlined, strong: true),
            const SizedBox(height: Space.l),
            Text(names, style: t.headlineSmall),
            const SizedBox(height: Space.xs),
            Text(
              today.length == 1 && age != null
                  ? l10n.translate('turnsAgeToday').replaceAll('{age}', '$age')
                  : l10n.translate('birthdayToday'),
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: Space.l),
            FilledButton.icon(
              onPressed: () => showBirthdayMessageSheet(context,
                  name: first.name,
                  relation: first.relation,
                  phone: first.phone),
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(l10n.translate('writeMessage')),
            ),
          ],
        ),
      );
    }

    final n = next;
    if (n == null) {
      return GlassCard(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconBadge(Icons.event_available_outlined),
            const SizedBox(height: Space.l),
            Text(l10n.translate('noUpcomingBirthdays'), style: t.titleMedium),
            const SizedBox(height: Space.xs),
            Text(l10n.translate('noUpcomingHint'),
                style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
            const SizedBox(height: Space.l),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/import'),
              icon: const Icon(Icons.contacts_outlined),
              label: Text(l10n.translate('importContacts')),
            ),
            const SizedBox(height: Space.s),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/list'),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: Text(l10n.translate('addContactAction')),
            ),
          ],
        ),
      );
    }

    final (contact, days) = n;
    final birth = parseBirthDate(contact.date)!;
    final age = ageAtNextBirthday(birth, DateTime.now());
    return GlassCard(
      padding: const EdgeInsets.all(Space.xl),
      onTap: () => Navigator.of(context).pushNamed('/detail', arguments: contact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('nextBirthday').toUpperCase(),
              style: t.labelSmall?.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: Space.l),
          Row(
            children: [
              ContactAvatar(
                  name: contact.name, imagePath: contact.imageUri, size: 56),
              const SizedBox(width: Space.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.name,
                        style: t.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      [
                        dayMonthLabel(l10n, birth),
                        if (age != null)
                          l10n.translate('turnsAge').replaceAll('{age}', '$age'),
                      ].join(' · '),
                      style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$days', style: t.displaySmall?.copyWith(color: c.primary)),
              const SizedBox(width: Space.s),
              Text(
                l10n.translate(days == 1 ? 'dayLeft' : 'daysLeft'),
                style: t.bodyLarge?.copyWith(color: c.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Trois chiffres utiles : contacts, anniversaires cette semaine, ce mois.
class _StatsRow extends StatelessWidget {
  final List<Contact> contacts;
  final DateTime now;
  const _StatsRow({required this.contacts, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    var week = 0, month = 0;
    for (final c in contacts) {
      final birth = parseBirthDate(c.date);
      if (birth == null) continue;
      if (daysUntilBirthday(birth, now) < 7) week++;
      if (birth.month == now.month) month++;
    }
    Widget stat(String value, String label) => Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.l, vertical: Space.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
    return Row(
      children: [
        stat('${contacts.length}', l10n.translate('statContacts')),
        const SizedBox(width: Space.s),
        stat('$week', l10n.translate('statThisWeek')),
        const SizedBox(width: Space.s),
        stat('$month', l10n.translate('statThisMonth')),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final Contact contact;
  final int days;
  const _UpcomingTile({required this.contact, required this.days});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final birth = parseBirthDate(contact.date)!;
    return ListTile(
      onTap: () => Navigator.of(context).pushNamed('/detail', arguments: contact),
      leading: ContactAvatar(name: contact.name, imagePath: contact.imageUri),
      title: Text(contact.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
          '${relationLabel(l10n, contact.relation)} · ${dayMonthLabel(l10n, birth)}'),
      trailing: Pill(countdownLabel(l10n, days),
          tone: days <= 7 ? Tone.primary : Tone.neutral),
    );
  }
}

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget tile(IconData icon, String title, String subtitle, String route,
            {Tone tone = Tone.primary}) =>
        GlassCard(
          onTap: () => Navigator.of(context).pushNamed(route),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon, tone: tone),
              const SizedBox(height: Space.m),
              Text(title, style: t.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
    final tiles = [
      tile(Icons.people_alt_outlined, l10n.translate('contacts'),
          l10n.translate('exploreContactsDesc'), '/list'),
      tile(Icons.public_rounded, l10n.translate('sameDay'),
          l10n.translate('exploreSameDayDesc'), '/same-day',
          tone: Tone.accent),
      tile(Icons.auto_awesome_outlined, l10n.translate('yourZodiacSign'),
          l10n.translate('exploreZodiacDesc'), '/zodiac'),
      tile(Icons.person_outline_rounded, l10n.translate('myProfile'),
          l10n.translate('exploreProfileDesc'), '/profile'),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Space.s),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: Space.s),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Réglages : apparence, langue, rappels.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          Space.page, Space.s, Space.page, Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.translate('settings'), style: t.titleLarge),
          const SizedBox(height: Space.xl),
          Text(l10n.translate('appearance'), style: t.titleSmall),
          const SizedBox(height: Space.s),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined, size: 18),
                  label: Text(l10n.translate('light'))),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text(l10n.translate('dark'))),
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                  label: Text(l10n.translate('system'))),
            ],
            selected: {themeProv.mode},
            onSelectionChanged: (s) => themeProv.setMode(s.first),
          ),
          const SizedBox(height: Space.xl),
          Text(l10n.translate('changeLanguage'), style: t.titleSmall),
          const SizedBox(height: Space.s),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fr', label: Text('Français')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {lang},
            onSelectionChanged: (s) => changeAppLocale(context, s.first),
          ),
          const SizedBox(height: Space.xl),
          const ReminderSettingsSection(),
        ],
      ),
    );
  }
}

/// Change la langue et reprogramme les rappels pour qu'ils soient rédigés
/// dans la nouvelle langue.
void changeAppLocale(BuildContext context, String languageCode) {
  context.read<LocaleProvider>().setLocale(Locale(languageCode));
  context.read<ContactProvider>().rescheduleAllReminders(languageCode);
  MessagingService().updateLocale(languageCode);
}
