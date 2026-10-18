import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/analytics_service.dart';
import '../services/constellation_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday_labels.dart';
import '../widgets/constellation/constellation_painter.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// La constellation des anniversaires : chaque jour de l'année est une
/// étoile, d'autant plus grande et brillante que des membres y sont nés.
class ConstellationScreen extends StatefulWidget {
  static const routeName = '/constellation';
  const ConstellationScreen({super.key, this.service});

  /// Remplaçable dans les tests.
  final ConstellationService? service;

  @override
  State<ConstellationScreen> createState() => _ConstellationScreenState();
}

class _ConstellationScreenState extends State<ConstellationScreen>
    with TickerProviderStateMixin {
  late final Future<ConstellationStats?> _stats =
      (widget.service ?? ConstellationService()).load();
  late final AnimationController _entry = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));
  // Une boucle de 12 s : scintillement, respiration du halo, comète.
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));
  late final AnimationController _select = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  int? _selected;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'ConstellationScreen');
  }

  @override
  void dispose() {
    _entry.dispose();
    _clock.dispose();
    _select.dispose();
    super.dispose();
  }

  /// Lance l'animation une fois les données arrivées (ou l'affiche
  /// directement si l'utilisateur a demandé moins d'animations).
  void _start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _entry.value = 1;
        _select.value = 1;
      } else {
        _entry.forward();
        _clock.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = context.watch<ProfileProvider>().profile;
    return AppScaffold(
      title: Text(l10n.translate('constellation')),
      body: FutureBuilder<ConstellationStats?>(
        future: _stats,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snap.data;
          if (stats == null || stats.total == 0) {
            return Center(
              child: EmptyState(
                icon: Icons.auto_awesome_outlined,
                title: l10n.translate('constellationEmpty'),
                message: l10n.translate('constellationEmptyDesc'),
              ),
            );
          }
          _start();
          return _Content(
            stats: stats,
            me: me,
            entry: _entry,
            clock: _clock,
            select: _select,
            selected: _selected,
            onSelect: (i) {
              if (i == _selected) return;
              HapticFeedback.selectionClick();
              setState(() => _selected = i);
              if (!MediaQuery.of(context).disableAnimations) {
                _select.forward(from: 0);
              }
            },
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final ConstellationStats stats;
  final UserProfile? me;
  final Animation<double> entry;
  final Animation<double> clock;
  final Animation<double> select;
  final int? selected;
  final ValueChanged<int?> onSelect;

  const _Content({
    required this.stats,
    required this.me,
    required this.entry,
    required this.clock,
    required this.select,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final lang = l10n.locale.languageCode;
    final number = NumberFormat.decimalPattern(lang);
    final myKey = me == null ? null : UserProfile.dayKeyOf(me!.birthDate);
    final mine = myKey == null ? null : DayRing.indexOfKey(myKey);

    final first = me?.givenName?.trim().isNotEmpty == true
        ? me!.givenName!.trim()
        : me?.name.trim().split(RegExp(r'\s+')).first;
    final family = me?.familyName?.trim().isNotEmpty == true
        ? me!.familyName!.trim()
        : (me != null && me!.name.trim().contains(' ')
            ? me!.name.trim().split(RegExp(r'\s+')).skip(1).join(' ')
            : null);
    final firstCount = first == null ? null : stats.firstNameCount(first);
    final familyCount = family == null ? null : stats.familyNameCount(family);
    final top = stats.topDays(5);

    return ListView(
      padding: AppScaffold.pagePadding(context),
      children: [
        _NightSky(
          stats: stats,
          mine: mine,
          selected: selected,
          entry: entry,
          clock: clock,
          select: select,
          onSelect: onSelect,
          centerTitle: number.format(stats.total),
          centerSubtitle: l10n.translate(stats.total == 1 ? 'memberOne' : 'members'),
        ),
        const SizedBox(height: Space.s),
        const _Legend(),
        const SizedBox(height: Space.m),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _DayCard(
            key: ValueKey(selected ?? mine ?? -1),
            stats: stats,
            index: selected ?? mine,
            isMine: selected == null || selected == mine,
          ),
        ),
        if (stats.total < 30) ...[
          const SizedBox(height: Space.m),
          NoticeCard(
              icon: Icons.hourglass_empty_rounded,
              text: l10n.translate('constellationGrowing')),
        ],
        if (top.isNotEmpty) ...[
          SectionHeader(l10n.translate('mostCelebratedDays')),
          GlassCard(
            child: Column(
              children: [
                for (final (i, e) in top.indexed) ...[
                  if (i > 0) const SizedBox(height: Space.m),
                  _Bar(
                    label: dayMonthLabel(l10n, _dateOf(e.key)),
                    value: e.value,
                    max: top.first.value,
                    highlight: e.key == myKey,
                    delay: i,
                  ),
                ],
              ],
            ),
          ),
        ],
        if ((firstCount ?? 0) > 1 || (familyCount ?? 0) > 1) ...[
          SectionHeader(l10n.translate('yourNamesakes')),
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.m, vertical: Space.s),
            child: Column(
              children: [
                if ((firstCount ?? 0) > 1)
                  ActionRow(
                    icon: Icons.badge_outlined,
                    tone: Tone.accent,
                    title: l10n
                        .translate('sameFirstName')
                        .replaceAll('{count}', number.format(firstCount))
                        .replaceAll('{name}', first!),
                  ),
                if ((firstCount ?? 0) > 1 && (familyCount ?? 0) > 1)
                  const CardDivider(),
                if ((familyCount ?? 0) > 1)
                  ActionRow(
                    icon: Icons.family_restroom_outlined,
                    tone: Tone.accent,
                    title: l10n
                        .translate('sameFamilyName')
                        .replaceAll('{count}', number.format(familyCount))
                        .replaceAll('{name}', family!),
                  ),
              ],
            ),
          ),
        ],
        if (stats.firstNames.isNotEmpty) ...[
          SectionHeader(l10n.translate('topFirstNames')),
          GlassCard(child: _NameCloud(names: stats.firstNames, highlight: first)),
        ],
        if (stats.updatedAt != null) ...[
          const SizedBox(height: Space.m),
          Text(
            l10n.translate('statsUpdated').replaceAll(
                '{date}',
                DateFormat.MMMMd(lang).add_Hm().format(stats.updatedAt!)),
            style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  static DateTime _dateOf(String key) {
    final i = DayRing.indexOfKey(key) ?? 0;
    final (m, d) = DayRing.monthDayOf(i);
    return DateTime(2000, m, d);
  }
}

/// Le panneau « ciel de nuit » : toujours sombre, comme un planétarium.
class _NightSky extends StatelessWidget {
  final ConstellationStats stats;
  final int? mine;
  final int? selected;
  final Animation<double> entry;
  final Animation<double> clock;
  final Animation<double> select;
  final ValueChanged<int?> onSelect;
  final String centerTitle;
  final String centerSubtitle;

  const _NightSky({
    required this.stats,
    required this.mine,
    required this.selected,
    required this.entry,
    required this.clock,
    required this.select,
    required this.onSelect,
    required this.centerTitle,
    required this.centerSubtitle,
  });

  static const _cool = Color(0xFFCAD3FF);
  static const _warm = Color(0xFFFFF1D0);
  static const _label = Color(0xFFC9CDEA);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n.locale.languageCode;
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final counts = List<int>.filled(DayRing.days, 0);
    stats.days.forEach((key, n) {
      final i = DayRing.indexOfKey(key);
      if (i != null) counts[i] = n;
    });
    final months = [
      for (var m = 1; m <= 12; m++)
        DateFormat.MMM(lang)
            .format(DateTime(2000, m))
            .replaceAll('.', '')
            .toUpperCase(),
    ];
    String? tag;
    final sel = selected;
    if (sel != null) {
      final (m, d) = DayRing.monthDayOf(sel);
      tag = '${dayMonthLabel(l10n, DateTime(2000, m, d))} · ${counts[sel]}';
    }

    return Semantics(
      label: l10n
          .translate('constellationSemantics')
          .replaceAll('{count}', centerTitle),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.card),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [Color(0xFF20264A), Color(0xFF10132A), Color(0xFF070913)],
                stops: [0, 0.55, 1],
              ),
            ),
            child: LayoutBuilder(builder: (context, box) {
              final size = box.biggest;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) =>
                    onSelect(ConstellationPainter.dayAt(size, d.localPosition)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: SkyPainter(
                          entry: entry,
                          line: _label,
                          labelStyle: t.labelSmall!.copyWith(
                              color: _label, fontSize: 9.5, letterSpacing: 1),
                          monthLabels: months,
                          currentMonth: now.month,
                        ),
                      ),
                    ),
                    Center(
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                            parent: entry,
                            curve: const Interval(0.45, 1, curve: Curves.easeOut)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(centerTitle,
                                style: const TextStyle(
                                    color: Color(0xFFF2F3FF),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.6)),
                            const SizedBox(height: 2),
                            Text(centerSubtitle.toUpperCase(),
                                style: TextStyle(
                                    color: _label.withValues(alpha: 0.75),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.6)),
                          ],
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ConstellationPainter(
                          counts: counts,
                          mine: mine,
                          selected: selected,
                          today: DayRing.indexOfDate(now),
                          entry: entry,
                          clock: clock,
                          select: select,
                          cool: _cool,
                          warm: _warm,
                          gold: Brand.goldSoft,
                          tagStyle: t.labelMedium!.copyWith(
                              color: const Color(0xFFF2F3FF),
                              fontWeight: FontWeight.w600),
                          selectedLabel: tag,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Clé de lecture, sous le ciel.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    // Repère + texte dans un même paragraphe : le texte passe à la ligne
    // sur les écrans étroits au lieu de déborder.
    Widget item(Widget marker, String label) => Text.rich(
          TextSpan(children: [
            WidgetSpan(
                alignment: PlaceholderAlignment.middle, child: marker),
            TextSpan(text: '  $label'),
          ]),
          style: t.bodySmall,
        );
    Widget dot(Color color) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('constellationLegend'), style: t.bodySmall),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.l,
            runSpacing: Space.xs,
            children: [
              item(dot(c.secondary), l10n.translate('legendYourDay')),
              item(Container(width: 12, height: 1, color: c.onSurfaceVariant),
                  l10n.translate('legendLines')),
              item(Container(width: 1.5, height: 10, color: c.onSurfaceVariant),
                  l10n.translate('legendToday')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Détail du jour sélectionné (ou de son propre jour).
class _DayCard extends StatelessWidget {
  final ConstellationStats stats;
  final int? index;
  final bool isMine;

  const _DayCard(
      {super.key, required this.stats, required this.index, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final i = index;
    if (i == null) {
      return GlassCard(
        child: Text(l10n.translate('tapAStar'),
            style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
      );
    }
    final (m, d) = DayRing.monthDayOf(i);
    final key = '${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final count = stats.countFor(key);
    final average = stats.total / DayRing.days;
    final ratio = average == 0 ? 0 : count / average;
    return GlassCard(
      tint: isMine ? c.secondary : null,
      child: Row(
        children: [
          IconBadge(isMine ? Icons.star_rounded : Icons.star_outline_rounded,
              tone: isMine ? Tone.accent : Tone.primary),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    dayMonthLabel(l10n, DateTime(2000, m, d)),
                    if (isMine) l10n.translate('yourDayShort'),
                  ].join(' · '),
                  style: t.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? l10n.translate('noMemberThatDay')
                      : [
                          l10n
                              .translate(count == 1 ? 'memberBornOne' : 'membersBorn')
                              .replaceAll('{count}', '$count'),
                          l10n
                              .translate('rankOfDay')
                              .replaceAll('{rank}', '${stats.rankOf(key)}'),
                          if (ratio >= 1.5)
                            l10n.translate('timesAverage').replaceAll(
                                '{x}',
                                NumberFormat('0.0', l10n.locale.languageCode)
                                    .format(ratio)),
                        ].join(' · '),
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre horizontale qui se remplit à l'ouverture, en cascade.
class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final bool highlight;
  final int delay;

  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.highlight,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final color = highlight ? c.secondary : c.primary;
    final target = max == 0 ? 0.0 : value / max;
    return Row(
      children: [
        SizedBox(width: 92, child: Text(label, style: t.bodyMedium)),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: target),
            duration: Duration(milliseconds: 700 + 90 * delay),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: math.max(v, 0.02),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Space.m),
        SizedBox(
          width: 32,
          child: Text('$value',
              style: t.labelLarge, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

/// Nuage des prénoms : taille selon la fréquence, apparition en cascade.
class _NameCloud extends StatelessWidget {
  final List<NameCount> names;
  final String? highlight;
  const _NameCloud({required this.names, this.highlight});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final list = names.take(18).toList();
    final maxCount = list.first.count;
    final mineKey = highlight == null ? null : foldName(highlight!);
    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: [
        for (final (i, n) in list.indexed)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 350 + 40 * i),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
            ),
            child: Builder(builder: (context) {
              final isMine = foldName(n.name) == mineKey;
              final color = isMine ? c.secondary : c.primary;
              final weight = n.count / maxCount;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06 + 0.12 * weight),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: n.name,
                      style: TextStyle(
                        fontSize: 13 + 7 * weight,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    TextSpan(
                      text: '  ${n.count}',
                      style: TextStyle(
                          fontSize: 12, color: c.onSurfaceVariant),
                    ),
                  ]),
                ),
              );
            }),
          ),
      ],
    );
  }
}
