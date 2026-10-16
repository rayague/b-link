import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/meetup_service.dart';
import '../services/safety_service.dart';
import '../theme/app_theme.dart';
import '../utils/city.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Rencontres entre jumeaux d'anniversaire de la même ville.
class MeetupsScreen extends StatefulWidget {
  static const routeName = '/meetups';
  const MeetupsScreen({super.key});

  @override
  State<MeetupsScreen> createState() => _MeetupsScreenState();
}

/// Peut organiser / rejoindre : présent dans l'annuaire public (16+, non
/// masqué), comme l'exigent les règles Firestore.
bool canTakePart(ProfileProvider p) =>
    (p.profile?.shouldBePublished ?? false) && !p.hiddenByModeration;

String formatMeetupDate(BuildContext context, DateTime at) {
  final locale = AppLocalizations.of(context).locale.languageCode;
  return DateFormat.yMMMMEEEEd(locale).add_Hm().format(at);
}

class _MeetupsScreenState extends State<MeetupsScreen> {
  final _service = MeetupService();
  Future<List<Meetup>>? _future;

  String? _dayKey(UserProfile? p) =>
      p == null ? null : UserProfile.dayKeyOf(p.birthDate);
  String? _cityKey(UserProfile? p) => cityKey(p?.countryCode, p?.birthCity);

  void _reload() {
    final p = context.read<ProfileProvider>().profile;
    final day = _dayKey(p), city = _cityKey(p);
    setState(() {
      _future = day == null || city == null
          ? Future.value(const <Meetup>[])
          : _service.upcoming(birthDayKey: day, cityKey: city);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final profileProv = context.watch<ProfileProvider>();
    final city = _cityKey(profileProv.profile);
    final eligible = canTakePart(profileProv);
    final padding = AppScaffold.pagePadding(context, bottom: 96);

    return AppScaffold(
      title: Text(l10n.translate('meetupsTitle')),
      floatingActionButton: city != null && eligible
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.translate('organizeMeetup')),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const MeetupFormScreen()));
                if (created == true) _reload();
              },
            )
          : null,
      body: RefreshIndicator(
        edgeOffset: padding.top,
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            Text(l10n.translate('meetupsIntro'),
                style: t.bodyLarge?.copyWith(color: c.onSurfaceVariant)),
            const SizedBox(height: Space.l),
            if (city == null)
              NoticeCard(
                  icon: Icons.location_city_outlined,
                  text: l10n.translate('setCityHint'))
            else if (!eligible)
              NoticeCard(
                  icon: Icons.public_rounded,
                  text: l10n.translate('meetupsNeedPublic')),
            if (city != null)
              FutureBuilder<List<Meetup>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(Space.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final meetups = snap.data ?? const <Meetup>[];
                  if (meetups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: Space.s),
                      child: GlassCard(
                        child: EmptyState(
                          icon: Icons.celebration_outlined,
                          title: l10n.translate('noMeetups'),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final m in meetups) ...[
                        const SizedBox(height: Space.s),
                        GlassCard(
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    MeetupDetailScreen(meetupId: m.id)));
                            _reload();
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const IconBadge(Icons.celebration_outlined,
                                  tone: Tone.accent),
                              const SizedBox(width: Space.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.title, style: t.titleSmall),
                                    const SizedBox(height: 2),
                                    Text(formatMeetupDate(context, m.startsAt),
                                        style: t.bodySmall),
                                    Text(m.placeHint, style: t.bodySmall),
                                  ],
                                ),
                              ),
                              const SizedBox(width: Space.s),
                              Pill('${m.attendeeCount}/${m.maxAttendees}',
                                  icon: Icons.people_outline_rounded),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Conseils affichés sur chaque rencontre : rencontrer des inconnus.
class SafetyTipsCard extends StatelessWidget {
  const SafetyTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return GlassCard(
      tint: c.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield_outlined, color: c.secondary, size: 20),
            const SizedBox(width: Space.s),
            Expanded(
                child: Text(l10n.translate('safetyTitle'), style: t.titleSmall)),
          ]),
          const SizedBox(height: Space.s),
          for (final key in const [
            'safetyPublicPlace',
            'safetyTellSomeone',
            'safetyNoAddress',
            'safetyReport',
          ])
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('·  ', style: t.bodyMedium),
                  Expanded(child: Text(l10n.translate(key), style: t.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Formulaire « Organiser une rencontre ».
class MeetupFormScreen extends StatefulWidget {
  const MeetupFormScreen({super.key});

  @override
  State<MeetupFormScreen> createState() => _MeetupFormScreenState();
}

class _MeetupFormScreenState extends State<MeetupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _description = TextEditingController();
  DateTime _startsAt = DateTime.now().add(const Duration(days: 7));
  int _max = 6;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_startsAt));
    if (time == null) return;
    setState(() => _startsAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (!_startsAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('meetupDateInPast'))));
      return;
    }
    final p = context.read<ProfileProvider>().profile!;
    setState(() => _saving = true);
    try {
      await MeetupService().create(
        title: _title.text,
        description: _description.text,
        placeHint: _place.text,
        birthDayKey: UserProfile.dayKeyOf(p.birthDate),
        cityKey: cityKey(p.countryCode, p.birthCity)!,
        startsAt: _startsAt,
        maxAttendees: _max,
        creatorName: p.publicName ? p.name : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('❌ Création de rencontre: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('actionFailed'))));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    String? required(String? v, int min, int max) {
      final s = v?.trim() ?? '';
      if (s.length < min) return l10n.translate('fieldTooShort');
      if (s.length > max) return l10n.translate('fieldTooLong');
      return null;
    }

    return AppScaffold(
      title: Text(l10n.translate('organizeMeetup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppScaffold.pagePadding(context),
          children: [
            const SafetyTipsCard(),
            const SizedBox(height: Space.m),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                        labelText: l10n.translate('meetupTitleField'),
                        prefixIcon: const Icon(Icons.title_rounded)),
                    validator: (v) => required(v, 3, 80),
                  ),
                  const SizedBox(height: Space.xs),
                  TextFormField(
                    controller: _place,
                    maxLength: 100,
                    decoration: InputDecoration(
                        labelText: l10n.translate('meetupPlaceField'),
                        helperText: l10n.translate('meetupPlaceHelp'),
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.place_outlined)),
                    validator: (v) => required(v, 2, 100),
                  ),
                  const SizedBox(height: Space.s),
                  PickerField(
                    label: l10n.translate('meetupDateField'),
                    icon: Icons.event_outlined,
                    value: formatMeetupDate(context, _startsAt),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: Space.l),
                  Text('${l10n.translate('meetupMaxAttendees')} : $_max',
                      style: t.bodyMedium),
                  Slider(
                    value: _max.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
                    label: '$_max',
                    onChanged: (v) => setState(() => _max = v.round()),
                  ),
                  TextFormField(
                    controller: _description,
                    maxLength: 500,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                        labelText: l10n.translate('meetupDescriptionField'),
                        alignLabelWithHint: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.translate('organizeMeetup')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Détail d'une rencontre : participants, inscription, sécurité.
class MeetupDetailScreen extends StatefulWidget {
  final String meetupId;
  const MeetupDetailScreen({super.key, required this.meetupId});

  @override
  State<MeetupDetailScreen> createState() => _MeetupDetailScreenState();
}

class _MeetupDetailScreenState extends State<MeetupDetailScreen> {
  final _service = MeetupService();
  late Future<(Meetup?, List<MeetupAttendee>, bool)> _future = _load();
  bool _busy = false;

  Future<(Meetup?, List<MeetupAttendee>, bool)> _load() async => (
        await _service.get(widget.meetupId),
        await _service.attendees(widget.meetupId),
        await _service.isAttending(widget.meetupId),
      );

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      debugPrint('❌ Rencontre: $e');
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('actionFailed'))));
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _future = _load();
      });
    }
  }

  Future<void> _confirmCancel(Meetup meetup) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('cancelMeetup')),
        content: Text(l10n.translate('cancelMeetupConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('back'))),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('cancelMeetup')),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => _service.cancel(meetup.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final profileProv = context.watch<ProfileProvider>();
    final me = profileProv.profile;

    return AppScaffold(
      title: Text(l10n.translate('meetupsTitle')),
      body: FutureBuilder<(Meetup?, List<MeetupAttendee>, bool)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final (meetup, attendees, attending) =
              snap.data ?? (null, const <MeetupAttendee>[], false);
          if (meetup == null) {
            return Center(
              child: EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: l10n.translate('meetupGone')),
            );
          }
          final isCreator = me?.uid == meetup.creatorUid;
          return ListView(
            padding: AppScaffold.pagePadding(context),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meetup.title, style: t.headlineSmall),
                    if (meetup.cancelled) ...[
                      const SizedBox(height: Space.s),
                      Pill(l10n.translate('meetupCancelled'), tone: Tone.danger),
                    ],
                    const SizedBox(height: Space.m),
                    InfoRow(
                        icon: Icons.event_outlined,
                        label: l10n.translate('meetupDateField'),
                        value: formatMeetupDate(context, meetup.startsAt)),
                    const CardDivider(),
                    InfoRow(
                        icon: Icons.place_outlined,
                        label: l10n.translate('meetupPlaceField'),
                        value: meetup.placeHint),
                    const CardDivider(),
                    InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: l10n.translate('meetupOrganizer'),
                        value: meetup.creatorName ??
                            l10n.translate('anonymousProfile')),
                    if (meetup.description.isNotEmpty) ...[
                      const SizedBox(height: Space.m),
                      Text(meetup.description,
                          style:
                              t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              SectionHeader('${l10n.translate('meetupAttendees')} '
                  '(${meetup.attendeeCount}/${meetup.maxAttendees})'),
              if (attendees.isNotEmpty)
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.m, vertical: Space.s),
                  child: Column(
                    children: [
                      for (final a in attendees)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading:
                              InitialsAvatar(name: a.name ?? '?', size: 36),
                          title:
                              Text(a.name ?? l10n.translate('anonymousProfile')),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: Space.l),
              if (!meetup.cancelled && !isCreator && canTakePart(profileProv))
                attending
                    ? OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() => _service.leave(meetup.id)),
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(l10n.translate('leaveMeetup')),
                      )
                    : FilledButton.icon(
                        onPressed: _busy || meetup.isFull
                            ? null
                            : () => _run(() => _service.join(meetup.id,
                                publicName: me!.publicName ? me.name : null)),
                        icon: const Icon(Icons.how_to_reg_outlined),
                        label: Text(l10n.translate(
                            meetup.isFull ? 'meetupFull' : 'joinMeetup')),
                      ),
              if (isCreator && !meetup.cancelled)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: c.error),
                  onPressed: _busy ? null : () => _confirmCancel(meetup),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(l10n.translate('cancelMeetup')),
                ),
              const SizedBox(height: Space.l),
              const SafetyTipsCard(),
              if (!isCreator) ...[
                const SizedBox(height: Space.s),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: c.onSurfaceVariant),
                  onPressed: _busy
                      ? null
                      : () {
                          final messenger = ScaffoldMessenger.of(context);
                          _run(() async {
                            await SafetyService()
                                .report(meetup.creatorUid, 'inappropriate');
                            messenger.showSnackBar(SnackBar(
                                content: Text(l10n.translate('reportSent'))));
                          });
                        },
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(l10n.translate('reportOrganizer')),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
