import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/zodiac_content.dart';
import '../l10n/zodiac_portraits.dart';
import '../providers/profile_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Le signe de l'utilisateur : un portrait détaillé, ses dons, ce qui le
/// fait grandir, l'amour, l'amitié, le travail, ses affinités.
class ZodiacScreen extends StatefulWidget {
  static const routeName = '/zodiac';
  const ZodiacScreen({super.key});

  @override
  State<ZodiacScreen> createState() => _ZodiacScreenState();
}

class _ZodiacScreenState extends State<ZodiacScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'ZodiacScreen');
  }

  /// Symbole du signe en présentation texte (U+FE0E) plutôt qu'en émoji
  /// coloré, plus sobre.
  static String glyph(String id) =>
      '${ZodiacContent.emoji(id).replaceAll('️', '')}︎';

  static IconData _elementIcon(String id) =>
      switch (ZodiacContent.of(id)?.elementId) {
        'fire' => Icons.local_fire_department_outlined,
        'earth' => Icons.landscape_outlined,
        'air' => Icons.air_rounded,
        _ => Icons.water_drop_outlined,
      };

  static const _giftIcons = [
    Icons.auto_awesome_outlined,
    Icons.bolt_outlined,
    Icons.favorite_border_rounded,
    Icons.star_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileProvider>().profile;

    if (profile?.zodiac == null) {
      return AppScaffold(
        title: Text(l10n.translate('yourZodiacSign')),
        body: Center(
          child: EmptyState(
            icon: Icons.auto_awesome_outlined,
            title: l10n.translate('chooseBirthDate'),
          ),
        ),
      );
    }

    final id = profile!.zodiac!;
    final lang = l10n.locale.languageCode;
    final portrait = ZodiacPortrait.of(id, lang);
    final modality = l10n.translate(
        const ['modalityCardinal', 'modalityFixed', 'modalityMutable'][
            zodiacModality(id).clamp(0, 2)]);
    final opposite = zodiacOpposite(id);
    var section = 0;
    Widget reveal(Widget child) => _Reveal(index: section++, child: child);

    return AppScaffold(
      title: Text(l10n.translate('yourZodiacSign')),
      body: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          reveal(GlassCard(
            tint: c.secondary,
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      c.secondary.withValues(alpha: 0.22),
                      c.secondary.withValues(alpha: 0.06),
                    ]),
                    border:
                        Border.all(color: c.secondary.withValues(alpha: 0.35)),
                  ),
                  child: Text(glyph(id),
                      style: TextStyle(fontSize: 44, color: c.secondary)),
                ),
                const SizedBox(height: Space.l),
                Text(ZodiacContent.name(id, lang), style: t.headlineMedium),
                const SizedBox(height: Space.xs),
                Text(ZodiacContent.period(id, lang),
                    style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                const SizedBox(height: Space.l),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    Pill(ZodiacContent.element(id, lang),
                        icon: _elementIcon(id), tone: Tone.accent),
                    Pill(modality, icon: Icons.change_circle_outlined),
                    Pill(ZodiacContent.planet(id, lang),
                        icon: Icons.public_rounded),
                  ],
                ),
                const SizedBox(height: Space.l),
                Text(
                  ZodiacContent.description(id, lang),
                  style: t.titleMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )),
          if (portrait != null) ...[
            SectionHeader(l10n.translate('zodiacPortrait')),
            reveal(GlassCard(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, p) in portrait.portrait.indexed) ...[
                    if (i > 0) const SizedBox(height: Space.l),
                    Text(p, style: t.bodyLarge?.copyWith(height: 1.65)),
                  ],
                ],
              ),
            )),
            SectionHeader(l10n.translate('zodiacGifts')),
            reveal(Column(
              children: [
                for (var i = 0; i < portrait.gifts.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: Space.s),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var j = i; j < i + 2; j++) ...[
                          if (j > i) const SizedBox(width: Space.s),
                          Expanded(
                            child: j < portrait.gifts.length
                                ? _GiftCard(
                                    icon: _giftIcons[j % _giftIcons.length],
                                    title: portrait.gifts[j].$1,
                                    text: portrait.gifts[j].$2,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            )),
            SectionHeader(l10n.translate('zodiacLife')),
            reveal(GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.l, vertical: Space.s),
              child: Column(
                children: [
                  _LifeRow(
                      icon: Icons.favorite_border_rounded,
                      title: l10n.translate('zodiacLove'),
                      text: portrait.love),
                  const CardDivider(),
                  _LifeRow(
                      icon: Icons.people_outline_rounded,
                      title: l10n.translate('zodiacFriendship'),
                      text: portrait.friendship),
                  const CardDivider(),
                  _LifeRow(
                      icon: Icons.work_outline_rounded,
                      title: l10n.translate('zodiacWork'),
                      text: portrait.work),
                ],
              ),
            )),
            SectionHeader(l10n.translate('zodiacGrowth')),
            reveal(GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, g) in portrait.growth.indexed) ...[
                    if (i > 0) const SizedBox(height: Space.m),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.spa_outlined, size: 20, color: c.secondary),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Text(g,
                              style: t.bodyMedium?.copyWith(height: 1.5)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )),
          ],
          SectionHeader(l10n.translate('zodiacAffinities')),
          reveal(GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('zodiacAffinitiesDesc'),
                    style: t.bodySmall),
                const SizedBox(height: Space.m),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    for (final other in zodiacAffinities(id))
                      Pill('${glyph(other)}  ${ZodiacContent.name(other, lang)}',
                          tone: Tone.primary),
                  ],
                ),
                const SizedBox(height: Space.l),
                const Divider(),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    Text(glyph(opposite),
                        style: TextStyle(fontSize: 22, color: c.secondary)),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${l10n.translate('zodiacOpposite')} : '
                              '${ZodiacContent.name(opposite, lang)}',
                              style: t.titleSmall),
                          Text(l10n.translate('zodiacOppositeDesc'),
                              style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
          SectionHeader(l10n.translate('zodiacTraits')),
          reveal(GlassCard(
            child: Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final trait in ZodiacContent.traits(id, lang))
                  Pill(trait, tone: Tone.primary),
              ],
            ),
          )),
          SectionHeader(l10n.translate('zodiacQuotes')),
          for (final quote in ZodiacContent.quotes(id, lang)) ...[
            reveal(GlassCard(
              padding: const EdgeInsets.all(Space.l),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: c.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: Space.l),
                    Expanded(
                      child: Text(
                        quote,
                        style: t.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: Space.s),
          ],
          const SizedBox(height: Space.l),
          Text(
            l10n.translate('zodiacDisclaimer'),
            style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Apparition douce, décalée section par section, à l'ouverture.
class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;
  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.07).clamp(0.0, 0.5);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (delay * 1000).round()),
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

class _GiftCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _GiftCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, tone: Tone.accent),
          const SizedBox(height: Space.m),
          Text(title, style: t.titleSmall),
          const SizedBox(height: Space.xs),
          Text(text, style: t.bodySmall?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

class _LifeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _LifeRow({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall),
                const SizedBox(height: Space.xs),
                Text(text, style: t.bodyMedium?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
