import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/zodiac_content.dart';
import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/safety_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday_labels.dart';
import '../widgets/birth_insights_widget.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/social_links_widget.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Profil public d'un jumeau d'anniversaire : seulement ce qu'il a choisi
/// de montrer, avec signalement et blocage.
class PublicProfileScreen extends StatefulWidget {
  static const routeName = '/public-profile';
  final UserProfile profile;

  const PublicProfileScreen({super.key, required this.profile});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile get profile => widget.profile;

  @override
  void initState() {
    super.initState();
    // Une fois par ouverture (et non à chaque reconstruction).
    AnalyticsService().logScreenView(screenName: 'PublicProfileScreen');
  }

  Future<void> _report() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showGlassSheet<String>(
      context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.translate('reportReason'),
                style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: Space.s),
            for (final r in SafetyService.reasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.translate('reason_$r')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(sheet).pop(r),
              ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await SafetyService().report(profile.uid!, reason);
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('reportSent'))));
    } catch (e) {
      debugPrint('❌ Signalement: $e');
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('actionFailed'))));
    }
  }

  /// Bloque le profil puis revient à la liste, en lui signalant de le masquer.
  Future<void> _block() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('block')),
        content: Text(l10n.translate('blockConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.translate('cancel'))),
          TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.translate('block'))),
        ],
      ),
    );
    if (ok != true) return;
    await SafetyService()
        .block(profile.uid!, name: profile.publicName ? profile.name : null);
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.translate('profileBlocked'))));
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final lang = l10n.locale.languageCode;
    final name = profile.isPublic && profile.publicName
        ? profile.name
        : l10n.translate('anonymousProfile');

    final place = [
      if (profile.publicBirthPlace) profile.birthplace,
      if (profile.publicBirthCountry) profile.birthCountry,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');

    final rows = <Widget>[
      if (profile.publicBirthDate)
        InfoRow(
          icon: Icons.cake_outlined,
          label: l10n.translate('birthDate'),
          value: [
            fullDateLabel(l10n, profile.birthDate),
            if (profile.publicBirthTime && profile.birthTime != null)
              profile.birthTime!,
          ].join(' · '),
        )
      else
        InfoRow(
          icon: Icons.cake_outlined,
          label: l10n.translate('birthday'),
          value: dayMonthLabel(l10n, profile.birthDate),
        ),
      if (place.isNotEmpty)
        InfoRow(
            icon: Icons.place_outlined,
            label: l10n.translate('birthPlace'),
            value: place),
      if (profile.publicBirthCity && (profile.birthCity ?? '').isNotEmpty)
        InfoRow(
            icon: Icons.home_outlined,
            label: l10n.translate('currentCity'),
            value: profile.birthCity!),
      if (profile.publicZodiac && profile.zodiac != null)
        InfoRow(
            icon: Icons.auto_awesome_outlined,
            label: l10n.translate('zodiacSign'),
            value: ZodiacContent.name(profile.zodiac!, lang)),
    ];

    return AppScaffold(
      actions: [
        if (profile.uid != null)
          PopupMenuButton<String>(
            onSelected: (v) => v == 'report' ? _report() : _block(),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'report', child: Text(l10n.translate('report'))),
              PopupMenuItem(
                value: 'block',
                child: Text(l10n.translate('block'),
                    style: TextStyle(color: c.error)),
              ),
            ],
          ),
      ],
      body: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              children: [
                ProfileAvatar(
                  uid: profile.uid,
                  name: name,
                  size: 88,
                  showPhoto: profile.publicPhoto,
                ),
                const SizedBox(height: Space.l),
                Text(name, style: t.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: Space.s),
                Pill(l10n.translate('birthdayTwin'),
                    icon: Icons.cake_outlined, tone: Tone.accent),
              ],
            ),
          ),
          if (!profile.isPublic) ...[
            const SizedBox(height: Space.m),
            GlassCard(
              child: EmptyState(
                icon: Icons.lock_outline_rounded,
                title: l10n.translate('privateProfile'),
                message: l10n.translate('privateProfileDesc'),
              ),
            ),
          ] else ...[
            const SizedBox(height: Space.m),
            GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.l, vertical: Space.s),
              child: Column(
                children: [
                  for (final (i, row) in rows.indexed) ...[
                    if (i > 0) const CardDivider(),
                    row,
                  ],
                ],
              ),
            ),
            if (profile.publicSocials &&
                (profile.socialLinks?.isNotEmpty ?? false)) ...[
              SectionHeader(l10n.translate('socialNetworks')),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.m, vertical: Space.s),
                child: SocialLinksWidget(socialLinks: profile.socialLinks!),
              ),
            ],
            if (profile.publicBirthDate) ...[
              const SizedBox(height: Space.m),
              BirthInsightsWidget(
                birthDate: profile.birthDate,
                // Profil d'une autre personne : à la 3e personne.
                personName: profile.publicName ? profile.name : '',
                birthTime: profile.publicBirthTime ? profile.birthTime : null,
                birthPlace: profile.publicBirthPlace ? profile.birthplace : null,
                birthCountry:
                    profile.publicBirthCountry ? profile.birthCountry : null,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
