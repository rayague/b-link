import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../services/analytics_service.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';
import '../utils/account_actions.dart' as account;
import '../utils/app_links.dart';
import '../widgets/blocked_profiles_sheet.dart';
import '../widgets/reminder_settings_section.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Réglages, rangés par thème : apparence, rappels, confidentialité,
/// partage. Le compte (déconnexion, suppression) est isolé tout en bas, en
/// rouge, et chaque action demande confirmation.
class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'SettingsScreen');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final themeProv = context.watch<ThemeProvider>();
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    final profile = context.watch<ProfileProvider>().profile;

    Widget label(String key) => Padding(
          padding: const EdgeInsets.only(bottom: Space.s),
          child: Text(l10n.translate(key), style: t.titleSmall),
        );

    return AppScaffold(
      title: Text(l10n.translate('settings')),
      body: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          SectionHeader(l10n.translate('appearance')),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label('theme'),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.translate('light'))),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.translate('dark'))),
                    ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.translate('system'))),
                  ],
                  selected: {themeProv.mode},
                  onSelectionChanged: (s) => themeProv.setMode(s.first),
                ),
                const SizedBox(height: Space.l),
                label('changeLanguage'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fr', label: Text('Français')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {lang},
                  onSelectionChanged: (s) => changeAppLocale(context, s.first),
                ),
              ],
            ),
          ),
          SectionHeader(l10n.translate('remindersTitle')),
          const GlassCard(child: ReminderSettingsSection()),
          SectionHeader(l10n.translate('privacyAndSafety')),
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.m, vertical: Space.s),
            child: Column(
              children: [
                // RGPD : consentement aux statistiques, réversible.
                ActionRow(
                  icon: Icons.insights_outlined,
                  title: l10n.translate('analyticsSetting'),
                  subtitle: l10n.translate('analyticsSettingDesc'),
                  tone: Tone.neutral,
                  trailing: Switch(
                    value: AnalyticsService().consent == true,
                    onChanged: (granted) async {
                      await AnalyticsService().setConsent(granted);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const CardDivider(),
                ActionRow(
                  icon: Icons.block_outlined,
                  title: l10n.translate('blockedProfiles'),
                  subtitle: l10n.translate('blockedProfilesDesc'),
                  tone: Tone.neutral,
                  onTap: () => showBlockedProfilesSheet(context),
                ),
                const CardDivider(),
                ActionRow(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.translate('privacyPolicy'),
                  tone: Tone.neutral,
                  onTap: () => launchUrl(Uri.parse(AppLinks.privacy),
                      mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
          SectionHeader(l10n.translate('shareSection')),
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.m, vertical: Space.s),
            child: ActionRow(
              icon: Icons.ios_share_rounded,
              title: l10n.translate('recommendApp'),
              subtitle: l10n.translate('recommendAppDesc'),
              onTap: () => SharePlus.instance.share(ShareParams(
                text: profile == null
                    ? l10n.translate('shareDefaultText')
                    : l10n
                        .translate('shareProfileText')
                        .replaceAll('{name}', profile.name),
              )),
            ),
          ),
          const SizedBox(height: Space.xxl),
          const _AccountZone(),
        ],
      ),
    );
  }
}

/// Déconnexion et suppression du compte : à part, en rouge, bien visibles.
class _AccountZone extends StatelessWidget {
  const _AccountZone();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return GlassCard(
      tint: c.error,
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.manage_accounts_outlined, color: c.error),
              const SizedBox(width: Space.s),
              Text(l10n.translate('account'),
                  style: t.titleMedium?.copyWith(color: c.error)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(l10n.translate('accountZoneDesc'), style: t.bodySmall),
          const SizedBox(height: Space.l),
          OutlinedButton.icon(
            onPressed: () => account.signOut(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.error,
              side: BorderSide(color: c.error.withValues(alpha: 0.6)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text(l10n.translate('logout')),
          ),
          const SizedBox(height: Space.s),
          FilledButton.icon(
            onPressed: () => account.deleteAccount(context),
            style: FilledButton.styleFrom(
              backgroundColor: c.error,
              foregroundColor: c.onError,
            ),
            icon: const Icon(Icons.delete_forever_outlined, size: 20),
            label: Text(l10n.translate('deleteAccount')),
          ),
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
