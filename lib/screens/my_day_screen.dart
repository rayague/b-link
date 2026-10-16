import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../l10n/zodiac_content.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/analytics_service.dart';
import '../services/constellation_service.dart';
import '../services/famous_births_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';
import '../utils/birthday.dart';
import '../utils/birthday_labels.dart';
import '../utils/day_facts.dart';
import '../utils/share_image.dart';
import '../utils/zodiac.dart';
import '../widgets/day_card.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// « Mon jour » : ce que sa date de naissance a de particulier, les
/// personnalités nées le même jour, et une carte à partager.
class MyDayScreen extends StatefulWidget {
  static const routeName = '/my-day';
  const MyDayScreen({super.key, this.famous, this.stats});

  /// Remplaçables dans les tests.
  final FamousBirthsService? famous;
  final ConstellationService? stats;

  @override
  State<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends State<MyDayScreen> {
  Future<List<FamousBirth>>? _famous;
  Future<ConstellationStats?>? _stats;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'MyDayScreen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final me = context.read<ProfileProvider>().profile;
    if (me == null || _famous != null) return;
    final lang = AppLocalizations.of(context).locale.languageCode;
    _famous = (widget.famous ?? FamousBirthsService())
        .forDay(me.birthDate.month, me.birthDate.day, lang);
    _stats = (widget.stats ?? ConstellationService()).load();
  }

  String _millions(AppLocalizations l10n, double v) {
    final n = NumberFormat('#,##0.0', l10n.locale.languageCode).format(v / 1e6);
    return l10n.translate('millionsShort').replaceAll('{n}', n);
  }

  Future<void> _share(UserProfile me, ConstellationStats? stats) async {
    final l10n = AppLocalizations.of(context);
    final key = GlobalKey();
    // On ne se compte pas soi-même (si l'on est dans l'annuaire).
    final self = me.shouldBePublished ? 1 : 0;
    final twins =
        (stats?.countFor(UserProfile.dayKeyOf(me.birthDate)) ?? 0) - self;
    final card = DayCard(
      eyebrow: l10n.translate('cardMyBirthday'),
      date: dayMonthLabel(l10n, me.birthDate),
      headline: l10n
          .translate('cardWorldTwins')
          .replaceAll('{n}', _millions(l10n, worldTwins(me.birthDate))),
      detail: twins > 0
          ? l10n.translate('cardAppTwins').replaceAll('{count}', '$twins')
          : null,
      footer: l10n.translate('cardInvite'),
      link: AppLinks.website.replaceFirst('https://', ''),
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => _SharePreview(boundaryKey: key, card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final me = context.watch<ProfileProvider>().profile;
    if (me == null) {
      return AppScaffold(
        title: Text(l10n.translate('myDay')),
        body: Center(
          child: EmptyState(
              icon: Icons.cake_outlined, title: l10n.translate('chooseBirthDate')),
        ),
      );
    }

    final now = DateTime.now();
    final birth = me.birthDate;
    final lang = l10n.locale.languageCode;
    final sign = Zodiac.computeZodiac(birth);
    final days = daysUntilBirthday(birth, now);
    final lived = daysLived(birth, now);
    final number = NumberFormat.decimalPattern(lang);
    final dayKey = UserProfile.dayKeyOf(birth);

    return AppScaffold(
      title: Text(l10n.translate('myDay')),
      body: FutureBuilder<ConstellationStats?>(
        future: _stats,
        builder: (context, statsSnap) {
          final stats = statsSnap.data;
          final appTwins = stats == null
              ? null
              : stats.countFor(dayKey) - (me.shouldBePublished ? 1 : 0);
          return ListView(
            padding: AppScaffold.pagePadding(context),
            children: [
              GlassCard(
                tint: c.secondary,
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('yourBirthday').toUpperCase(),
                        style: t.labelSmall?.copyWith(color: c.onSurfaceVariant)),
                    const SizedBox(height: Space.xs),
                    Text(dayMonthLabel(l10n, birth), style: t.displaySmall),
                    const SizedBox(height: Space.xs),
                    Text(
                      [
                        if (hasBirthYear(birth))
                          l10n.translate('bornOnWeekday').replaceAll(
                              '{day}', DateFormat.EEEE(lang).format(birth)),
                        ZodiacContent.name(sign, lang),
                      ].join(' · '),
                      style: t.bodyLarge?.copyWith(color: c.onSurfaceVariant),
                    ),
                    const SizedBox(height: Space.l),
                    Text(
                      days == 0
                          ? l10n.translate('itsYourBirthday')
                          : l10n
                              .translate(days == 1
                                  ? 'daysBeforeBirthdayOne'
                                  : 'daysBeforeBirthday')
                              .replaceAll('{count}', '$days'),
                      style: t.titleMedium?.copyWith(color: c.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.m),
              _FactsGrid(facts: [
                (
                  Icons.public_rounded,
                  '≈ ${_millions(l10n, worldTwins(birth))}',
                  l10n.translate('factWorldTwins'),
                ),
                if (appTwins != null)
                  (
                    Icons.people_alt_outlined,
                    number.format(appTwins < 0 ? 0 : appTwins),
                    l10n.translate('factAppTwins'),
                  ),
                if (lived != null)
                  (
                    Icons.wb_sunny_outlined,
                    number.format(lived),
                    l10n.translate('factDaysLived'),
                  ),
                if (lived != null)
                  (
                    Icons.nightlight_outlined,
                    number.format(fullMoonsSeen(lived)),
                    l10n.translate('factFullMoons'),
                  ),
              ]),
              if (stats != null && stats.total > 0 && stats.countFor(dayKey) > 0) ...[
                const SizedBox(height: Space.m),
                ActionRow(
                  icon: Icons.auto_graph_rounded,
                  tone: Tone.accent,
                  title: l10n
                      .translate('dayRank')
                      .replaceAll('{rank}', '${stats.rankOf(dayKey)}'),
                  subtitle: l10n.translate('dayRankDesc'),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/constellation'),
                ),
              ],
              const SizedBox(height: Space.l),
              FilledButton.icon(
                onPressed: () => _share(me, stats),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(l10n.translate('shareMyDay')),
              ),
              SectionHeader(l10n.translate('famousSameDay')),
              _FamousList(future: _famous),
              SectionHeader(l10n.translate('yourZodiacSign'),
                  actionLabel: l10n.translate('viewAll'),
                  onAction: () => Navigator.of(context).pushNamed('/zodiac')),
              GlassCard(
                onTap: () => Navigator.of(context).pushNamed('/zodiac'),
                child: Row(
                  children: [
                    const IconBadge(Icons.auto_awesome_outlined,
                        tone: Tone.accent),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ZodiacContent.name(sign, lang),
                              style: t.titleSmall),
                          Text(ZodiacContent.period(sign, lang),
                              style: t.bodySmall),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

typedef _Fact = (IconData, String, String);

class _FactsGrid extends StatelessWidget {
  final List<_Fact> facts;
  const _FactsGrid({required this.facts});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget cell(_Fact f) => GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(f.$1, size: 36),
              const SizedBox(height: Space.m),
              Text(f.$2, style: t.titleLarge),
              const SizedBox(height: 2),
              Text(f.$3, style: t.bodySmall),
            ],
          ),
        );
    return Column(
      children: [
        for (var i = 0; i < facts.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Space.s),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cell(facts[i])),
                const SizedBox(width: Space.s),
                Expanded(
                    child: i + 1 < facts.length
                        ? cell(facts[i + 1])
                        : const SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FamousList extends StatelessWidget {
  final Future<List<FamousBirth>>? future;
  const _FamousList({required this.future});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return FutureBuilder<List<FamousBirth>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const GlassCard(
            child: SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator())),
          );
        }
        final list = snap.data ?? const <FamousBirth>[];
        if (list.isEmpty) {
          return GlassCard(
            child: Text(l10n.translate('famousUnavailable'),
                style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.m, vertical: Space.xs),
              child: Column(
                children: [
                  for (final (i, f) in list.indexed) ...[
                    if (i > 0) const Divider(indent: 60),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _Portrait(birth: f),
                      title: Text(f.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          if (f.year != null) '${f.year}',
                          if (f.description != null) f.description!,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: f.url == null
                          ? null
                          : Icon(Icons.north_east_rounded,
                              size: 18, color: c.onSurfaceVariant),
                      onTap: f.url == null
                          ? null
                          : () => launchUrl(Uri.parse(f.url!),
                              mode: LaunchMode.externalApplication),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Space.s),
            Text(l10n.translate('sourceWikipedia'),
                style: t.bodySmall, textAlign: TextAlign.end),
          ],
        );
      },
    );
  }
}

class _Portrait extends StatelessWidget {
  final FamousBirth birth;
  const _Portrait({required this.birth});

  @override
  Widget build(BuildContext context) {
    final fallback = InitialsAvatar(name: birth.name, size: 44);
    final url = birth.thumbnail;
    if (url == null) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        cacheWidth: 132,
        headers: const {'User-Agent': 'B-Link/1.0 (https://b-link-3b2d5.web.app)'},
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

/// Aperçu de la carte « Mon jour » puis partage de l'image.
class _SharePreview extends StatefulWidget {
  final GlobalKey boundaryKey;
  final DayCard card;
  const _SharePreview({required this.boundaryKey, required this.card});

  @override
  State<_SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<_SharePreview> {
  bool _sharing = false;

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      await shareWidgetImage(
        widget.boundaryKey,
        fileName: 'b-link-mon-jour.png',
        text: '${widget.card.headline}\n${l10n.translate('cardInvite')} ${AppLinks.invite}',
      );
      AnalyticsService().logMyDayShared();
    } catch (e) {
      debugPrint('❌ Partage de « Mon jour »: $e');
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('actionFailed'))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(Space.l),
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.card),
                  child: RepaintBoundary(
                      key: widget.boundaryKey, child: widget.card),
                ),
              ),
            ),
            const SizedBox(height: Space.l),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.translate('close')),
                  ),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: FilledButton(
                    onPressed: _sharing ? null : _share,
                    child: Text(l10n.translate('shareCard')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
