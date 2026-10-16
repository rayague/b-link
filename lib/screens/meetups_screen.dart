import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/meetup_service.dart';
import '../services/safety_service.dart';
import '../utils/city.dart';

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
    final profileProv = context.watch<ProfileProvider>();
    final city = _cityKey(profileProv.profile);
    final eligible = canTakePart(profileProv);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('meetupsTitle'))),
      floatingActionButton: city != null && eligible
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l10n.translate('organizeMeetup')),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const MeetupFormScreen()));
                if (created == true) _reload();
              },
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.translate('meetupsIntro'),
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            if (city == null)
              _InfoCard(icon: Icons.location_city, text: l10n.translate('setCityHint'))
            else if (!eligible)
              _InfoCard(
                  icon: Icons.public, text: l10n.translate('meetupsNeedPublic')),
            if (city != null)
              FutureBuilder<List<Meetup>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final meetups = snap.data ?? const <Meetup>[];
                  if (meetups.isEmpty) {
                    return _InfoCard(
                        icon: Icons.celebration_outlined,
                        text: l10n.translate('noMeetups'));
                  }
                  return Column(children: [
                    for (final m in meetups)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.celebration),
                          title: Text(m.title),
                          subtitle: Text(
                              '${formatMeetupDate(context, m.startsAt)}\n📍 ${m.placeHint}'),
                          isThreeLine: true,
                          trailing: Text('${m.attendeeCount}/${m.maxAttendees}'),
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => MeetupDetailScreen(meetupId: m.id)));
                            _reload();
                          },
                        ),
                      ),
                  ]);
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ]),
        ),
      );
}

/// Conseils affichés sur chaque rencontre : rencontrer des inconnus.
class SafetyTipsCard extends StatelessWidget {
  const SafetyTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Colors.amber.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.shield_outlined, color: Colors.amber),
              const SizedBox(width: 8),
              Text(l10n.translate('safetyTitle'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            for (final key in ['safetyPublicPlace', 'safetyTellSomeone', 'safetyNoAddress', 'safetyReport'])
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• ${l10n.translate(key)}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire "Organiser une rencontre".
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
    String? required(String? v, int min, int max) {
      final t = v?.trim() ?? '';
      if (t.length < min) return l10n.translate('fieldTooShort');
      if (t.length > max) return l10n.translate('fieldTooLong');
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('organizeMeetup'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SafetyTipsCard(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: InputDecoration(labelText: l10n.translate('meetupTitleField')),
              validator: (v) => required(v, 3, 80),
            ),
            TextFormField(
              controller: _place,
              maxLength: 100,
              decoration: InputDecoration(
                  labelText: l10n.translate('meetupPlaceField'),
                  helperText: l10n.translate('meetupPlaceHelp')),
              validator: (v) => required(v, 2, 100),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(formatMeetupDate(context, _startsAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            Text('${l10n.translate('meetupMaxAttendees')} : $_max'),
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
              decoration: InputDecoration(
                  labelText: l10n.translate('meetupDescriptionField')),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.celebration),
              label: Text(l10n.translate('organizeMeetup')),
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.translate('actionFailed'))));
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileProv = context.watch<ProfileProvider>();
    final me = profileProv.profile;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('meetupsTitle'))),
      body: FutureBuilder<(Meetup?, List<MeetupAttendee>, bool)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final (meetup, attendees, attending) =
              snap.data ?? (null, const <MeetupAttendee>[], false);
          if (meetup == null) {
            return Center(child: Text(l10n.translate('meetupGone')));
          }
          final isCreator = me?.uid == meetup.creatorUid;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(meetup.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              if (meetup.cancelled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.translate('meetupCancelled'),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(formatMeetupDate(context, meetup.startsAt)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(meetup.placeHint),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(meetup.creatorName ?? l10n.translate('anonymousProfile')),
                subtitle: Text(l10n.translate('meetupOrganizer')),
              ),
              if (meetup.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(meetup.description),
              ],
              const SizedBox(height: 16),
              Text(
                '${l10n.translate('meetupAttendees')} '
                '(${meetup.attendeeCount}/${meetup.maxAttendees})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final a in attendees)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.person),
                  title: Text(a.name ?? l10n.translate('anonymousProfile')),
                ),
              const SizedBox(height: 16),
              if (!meetup.cancelled && !isCreator && canTakePart(profileProv))
                attending
                    ? OutlinedButton.icon(
                        onPressed: _busy ? null : () => _run(() => _service.leave(meetup.id)),
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.translate('leaveMeetup')),
                      )
                    : FilledButton.icon(
                        onPressed: _busy || meetup.isFull
                            ? null
                            : () => _run(() => _service.join(meetup.id,
                                publicName: me!.publicName ? me.name : null)),
                        icon: const Icon(Icons.how_to_reg),
                        label: Text(l10n.translate(
                            meetup.isFull ? 'meetupFull' : 'joinMeetup')),
                      ),
              if (isCreator && !meetup.cancelled)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(() => _service.cancel(meetup.id)),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: Text(l10n.translate('cancelMeetup')),
                ),
              const SizedBox(height: 16),
              const SafetyTipsCard(),
              if (!isCreator)
                TextButton.icon(
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
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(l10n.translate('reportOrganizer')),
                ),
            ],
          );
        },
      ),
    );
  }
}
