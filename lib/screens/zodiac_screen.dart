import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/zodiac_content.dart';
import '../providers/profile_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Le signe de l'utilisateur : élément, planète, traits et citations.
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
  static String _glyph(String emoji) =>
      '${emoji.replaceAll('️', '')}︎';

  static IconData _elementIcon(String id) =>
      switch (ZodiacContent.of(id)?.elementId) {
        'fire' => Icons.local_fire_department_outlined,
        'earth' => Icons.landscape_outlined,
        'air' => Icons.air_rounded,
        _ => Icons.water_drop_outlined,
      };

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

    return AppScaffold(
      title: Text(l10n.translate('yourZodiacSign')),
      body: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.secondary.withValues(alpha: 0.12),
                    border: Border.all(color: c.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Text(_glyph(ZodiacContent.emoji(id)),
                      style: TextStyle(fontSize: 40, color: c.secondary)),
                ),
                const SizedBox(height: Space.l),
                Text(ZodiacContent.name(id, lang), style: t.headlineMedium),
                const SizedBox(height: Space.xs),
                Text(ZodiacContent.period(id, lang),
                    style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                const SizedBox(height: Space.l),
                Text(
                  ZodiacContent.description(id, lang),
                  style: t.bodyLarge?.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Fact(
                    icon: _elementIcon(id),
                    label: l10n.translate('zodiacElement'),
                    value: ZodiacContent.element(id, lang),
                  ),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: _Fact(
                    icon: Icons.public_rounded,
                    label: l10n.translate('zodiacPlanet'),
                    value: ZodiacContent.planet(id, lang),
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(l10n.translate('zodiacTraits')),
          GlassCard(
            child: Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final trait in ZodiacContent.traits(id, lang))
                  Pill(trait, tone: Tone.primary),
              ],
            ),
          ),
          SectionHeader(l10n.translate('zodiacQuotes')),
          for (final quote in ZodiacContent.quotes(id, lang)) ...[
            GlassCard(
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
            ),
            const SizedBox(height: Space.s),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Fact({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon),
          const SizedBox(height: Space.m),
          Text(label, style: t.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: t.titleMedium),
        ],
      ),
    );
  }
}
