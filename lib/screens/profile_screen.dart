import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../l10n/zodiac_content.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../services/photo_service.dart';
import '../services/safety_service.dart';
import '../theme/app_theme.dart';
import '../utils/account_actions.dart' as account;
import '../utils/app_links.dart';
import '../utils/birthday_labels.dart';
import '../utils/zodiac.dart';
import '../widgets/birth_insights_widget.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/social_links_widget.dart';
import '../widgets/ui/country_sheet.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';
import 'admin_stats_screen.dart';
import '../widgets/ui/birth_date_picker.dart';

/// Profil de l'utilisateur : informations, confidentialité, réseaux,
/// réglages et compte.
class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _birthPlace = TextEditingController();
  final _birthCountry = TextEditingController();
  final _currentCity = TextEditingController();
  Map<String, String> _socialLinks = {};
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  bool _editing = false;
  bool _saving = false;
  late final Future<bool> _isAdmin = _checkAdmin();

  // Confidentialité
  bool _isPublic = false;
  bool _publicName = false;
  bool _publicBirthDate = false;
  bool _publicBirthTime = false;
  bool _publicBirthPlace = false;
  bool _publicBirthCountry = false;
  bool _publicBirthCity = false;
  String? _countryCode; // pays de résidence (ISO alpha-2)
  bool _publicCountry = false;
  bool _publicPhoto = false;
  bool _publicSocials = false;
  bool _publicZodiac = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'ProfileScreen');
    _fill(context.read<ProfileProvider>().profile);
  }

  @override
  void dispose() {
    _name.dispose();
    _birthPlace.dispose();
    _birthCountry.dispose();
    _currentCity.dispose();
    super.dispose();
  }

  /// Remplit le formulaire (ouverture, et « Annuler » qui oublie les
  /// modifications en cours).
  void _fill(UserProfile? p) {
    _name.text = p?.name ?? '';
    _birthPlace.text = p?.birthplace ?? '';
    _birthCountry.text = p?.birthCountry ?? '';
    _currentCity.text = p?.birthCity ?? '';
    _socialLinks = Map<String, String>.from(p?.socialLinks ?? const {});
    _birthDate = p?.birthDate;
    _birthTime = _parseTime(p?.birthTime);
    _isPublic = p?.isPublic ?? false;
    _publicName = p?.publicName ?? false;
    _publicBirthDate = p?.publicBirthDate ?? false;
    _publicBirthTime = p?.publicBirthTime ?? false;
    _publicBirthPlace = p?.publicBirthPlace ?? false;
    _publicBirthCountry = p?.publicBirthCountry ?? false;
    _publicBirthCity = p?.publicBirthCity ?? false;
    _countryCode = p?.countryCode;
    _publicCountry = p?.publicCountry ?? false;
    _publicPhoto = p?.publicPhoto ?? false;
    _publicSocials = p?.publicSocials ?? false;
    _publicZodiac = p?.publicZodiac ?? false;
  }

  /// « HH:mm » ; une valeur mal formée est ignorée au lieu de faire
  /// planter l'écran.
  static TimeOfDay? _parseTime(String? s) {
    final parts = s?.split(':');
    if (parts == null || parts.length < 2) return null;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? get _timeString => _birthTime == null
      ? null
      : '${_birthTime!.hour.toString().padLeft(2, '0')}:'
          '${_birthTime!.minute.toString().padLeft(2, '0')}';

  Future<bool> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      return await AdminService().isUserAdmin(uid);
    } catch (_) {
      return false;
    }
  }

  /// Moins de 16 ans : pas d'annuaire public (voir UserProfile.minPublicAge).
  bool get _canBePublic =>
      _birthDate == null || UserProfile.canBePublic(_birthDate!);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      messenger.showSnackBar(SnackBar(
          content: Text(l10n.translate(_birthDate == null
              ? 'birthDateRequired'
              : 'pleaseFillAllRequiredFields'))));
      return;
    }
    final provider = context.read<ProfileProvider>();
    // Le document Firestore est écrit en `merge` avec toutes les clés : tout
    // champ non repris ici serait remis à null. On conserve donc les champs
    // que cet écran n'édite pas.
    final previous = provider.profile;
    final name = _name.text.trim();
    final nameChanged = previous == null || previous.name != name;
    final nameParts = name.split(RegExp(r'\s+'));
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final updated = UserProfile(
      uid: previous?.uid,
      name: name,
      givenName: nameChanged ? nameParts.first : previous.givenName,
      familyName: nameChanged ? nameParts.skip(1).join(' ') : previous.familyName,
      timezone: previous?.timezone,
      bio: previous?.bio,
      zodiac: Zodiac.computeZodiac(_birthDate!),
      birthDate: _birthDate!,
      birthTime: _timeString,
      birthplace: opt(_birthPlace),
      birthCountry: opt(_birthCountry),
      birthCity: opt(_currentCity),
      socialLinks: Map<String, String>.from(_socialLinks),
      isPublic: _isPublic && _canBePublic,
      publicName: _publicName,
      publicBirthDate: _publicBirthDate,
      publicBirthTime: _publicBirthTime,
      publicBirthPlace: _publicBirthPlace,
      publicBirthCountry: _publicBirthCountry,
      publicBirthCity: _publicBirthCity,
      countryCode: _countryCode,
      publicCountry: _publicCountry,
      // Sinon chaque enregistrement « oublierait » la photo.
      hasPhoto: previous?.hasPhoto ?? false,
      publicPhoto: _publicPhoto,
      publicSocials: _publicSocials,
      publicZodiac: _publicZodiac,
    );

    setState(() => _saving = true);
    try {
      await provider.save(updated, push: true);
      if (!mounted) return;
      setState(() => _editing = false);
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('profileSaved'))));
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde profil: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.translate('profileSaveFailed')),
        action: SnackBarAction(label: l10n.translate('retry'), onPressed: _save),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _fill(context.read<ProfileProvider>().profile);
      _editing = false;
    });
  }

  /// Choisir ou supprimer la photo de profil.
  Future<void> _changePhoto() async {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<ProfileProvider>();
    final current = provider.profile;
    if (current == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final action = await showGlassSheet<String>(
      context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.translate('changePhoto')),
              onTap: () => Navigator.of(sheet).pop('pick'),
            ),
            if (current.hasPhoto)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(sheet).colorScheme.error),
                title: Text(l10n.translate('removePhoto'),
                    style: TextStyle(color: Theme.of(sheet).colorScheme.error)),
                onTap: () => Navigator.of(sheet).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      if (action == 'pick') {
        if (!await PhotoService().pickAndUpload()) return;
        current.hasPhoto = true;
      } else {
        await PhotoService().deleteMine();
        current.hasPhoto = false;
      }
      await provider.save(current);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Photo de profil: $e');
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('photoUploadFailed'))));
    }
  }

  /// Liste des profils bloqués, avec déblocage.
  Future<void> _showBlocked() {
    final l10n = AppLocalizations.of(context);
    final safety = SafetyService();
    return showGlassSheet<void>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => FutureBuilder<List<BlockedProfile>>(
          future: safety.blockedProfiles(),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(Space.xxl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final blocked = snap.data ?? const <BlockedProfile>[];
            return Padding(
              padding:
                  const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.translate('blockedProfiles'),
                      style: Theme.of(sheet).textTheme.titleLarge),
                  const SizedBox(height: Space.s),
                  if (blocked.isEmpty)
                    EmptyState(
                        icon: Icons.block_outlined,
                        title: l10n.translate('noBlockedProfiles'))
                  else
                    for (final b in blocked)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: InitialsAvatar(
                            name: b.name ?? '?', size: 40),
                        title: Text(
                            b.name ?? l10n.translate('anonymousProfile')),
                        trailing: TextButton(
                          onPressed: () async {
                            await safety.unblock(b.uid);
                            setSheet(() {}); // recharge la liste
                          },
                          child: Text(l10n.translate('unblock')),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addSocialLink() async {
    final l10n = AppLocalizations.of(context);
    final result = await showGlassSheet<(String, String)>(
      context,
      builder: (_) => const _SocialLinkSheet(),
    );
    if (result == null) return;
    setState(() => _socialLinks[result.$1] = result.$2);
    if (!mounted) return;
    if (!_publicSocials && _isPublic) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('socialLinksHiddenHint'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    return AppScaffold(
      title: Text(l10n.translate('myProfile')),
      actions: [
        FutureBuilder<bool>(
          future: _isAdmin,
          builder: (context, snap) => snap.data == true
              ? IconButton(
                  tooltip: l10n.translate('adminStats'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AdminStatsScreen())),
                )
              : const SizedBox.shrink(),
        ),
        if (_editing) ...[
          TextButton(
              onPressed: _saving ? null : _cancelEdit,
              child: Text(l10n.translate('cancel'))),
        ] else
          IconButton(
            tooltip: l10n.translate('edit'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => setState(() => _editing = true),
          ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppScaffold.pagePadding(context),
          children: [
            _header(profile),
            if (provider.hiddenByModeration) ...[
              const SizedBox(height: Space.m),
              NoticeCard(
                icon: Icons.visibility_off_outlined,
                text: l10n.translate('profileHiddenByModeration'),
                tone: Tone.danger,
              ),
            ],
            SectionHeader(l10n.translate('personalInfo')),
            _editing ? _infoForm() : _infoView(),
            if (_editing) ...[
              SectionHeader(l10n.translate('privacySettings')),
              _privacy(),
            ],
            SectionHeader(
              l10n.translate('socialNetworks'),
              actionLabel: _editing ? l10n.translate('add') : null,
              onAction: _addSocialLink,
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.m, vertical: Space.s),
              child: _socialLinks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Space.m),
                      child: Text(
                        l10n.translate(
                            _editing ? 'noSocialAddHint' : 'noSocialYet'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    )
                  : SocialLinksWidget(
                      socialLinks: _socialLinks,
                      onRemove: _editing
                          ? (k) => setState(() => _socialLinks.remove(k))
                          : null,
                    ),
            ),
            if (_editing) ...[
              const SizedBox(height: Space.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.translate('save')),
              ),
            ] else ...[
              if (_birthDate != null) ...[
                SectionHeader(l10n.translate('yourZodiacSign')),
                _zodiacCard(),
                const SizedBox(height: Space.m),
                BirthInsightsWidget(
                  birthDate: _birthDate!,
                  birthTime: _timeString,
                  birthPlace: _birthPlace.text.isEmpty ? null : _birthPlace.text,
                  birthCountry:
                      _birthCountry.text.isEmpty ? null : _birthCountry.text,
                ),
              ],
              SectionHeader(l10n.translate('settings')),
              _settingsCard(),
              SectionHeader(l10n.translate('account')),
              _accountCard(profile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(UserProfile? profile) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final sign = _birthDate == null ? null : Zodiac.computeZodiac(_birthDate!);
    return GlassCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        children: [
          Stack(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: _changePhoto,
                child: ProfileAvatar(
                  uid: profile?.uid,
                  name: profile?.name ?? '',
                  size: 88,
                  showPhoto: profile?.hasPhoto ?? false,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: c.primary,
                  shape: CircleBorder(side: BorderSide(color: c.surface, width: 2)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _changePhoto,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.photo_camera_outlined,
                          size: 16, color: c.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.l),
          Text(profile?.name ?? '',
              style: t.headlineSmall, textAlign: TextAlign.center),
          if (_birthDate != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              [
                fullDateLabel(l10n, _birthDate!),
                if (sign != null)
                  ZodiacContent.name(sign, l10n.locale.languageCode),
              ].join(' · '),
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Space.m),
          Pill(
            l10n.translate(
                profile?.isPublic == true ? 'publicProfile' : 'privateProfileShort'),
            icon: profile?.isPublic == true
                ? Icons.public_rounded
                : Icons.lock_outline_rounded,
            tone: profile?.isPublic == true ? Tone.primary : Tone.neutral,
          ),
        ],
      ),
    );
  }

  Widget _infoView() {
    final l10n = AppLocalizations.of(context);
    String? orNull(String s) => s.trim().isEmpty ? null : s.trim();
    final country = _countryCode == null ? null : Country.tryParse(_countryCode!);
    final rows = <Widget>[
      InfoRow(
          icon: Icons.person_outline_rounded,
          label: l10n.translate('fullName'),
          value: _name.text),
      if (_birthDate != null)
        InfoRow(
            icon: Icons.cake_outlined,
            label: l10n.translate('birthDate'),
            value: [
              fullDateLabel(l10n, _birthDate!),
              if (_birthTime != null) _birthTime!.format(context),
            ].join(' · ')),
      if (orNull(_birthPlace.text) != null || orNull(_birthCountry.text) != null)
        InfoRow(
            icon: Icons.place_outlined,
            label: l10n.translate('birthPlace'),
            value: [orNull(_birthPlace.text), orNull(_birthCountry.text)]
                .whereType<String>()
                .join(', ')),
      if (orNull(_currentCity.text) != null)
        InfoRow(
            icon: Icons.home_outlined,
            label: l10n.translate('currentCity'),
            value: _currentCity.text.trim()),
      if (country != null)
        InfoRow(
            icon: Icons.flag_outlined,
            label: l10n.translate('countryOfResidence'),
            value: countryLabel(context, country)),
    ];
    return GlassCard(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const CardDivider(),
            row,
          ],
        ],
      ),
    );
  }

  Widget _infoForm() {
    final l10n = AppLocalizations.of(context);
    final country = _countryCode == null ? null : Country.tryParse(_countryCode!);
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.translate('requiredField') : null;
    return GlassCard(
      child: Column(
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: l10n.translate('fullName'),
                prefixIcon: const Icon(Icons.person_outline_rounded)),
            validator: required,
          ),
          const SizedBox(height: Space.m),
          PickerField(
            label: l10n.translate('birthDate'),
            icon: Icons.cake_outlined,
            value: _birthDate == null ? null : fullDateLabel(l10n, _birthDate!),
            placeholder: l10n.translate('selectDate'),
            onTap: () async {
              final d =
                  await showBirthDatePicker(context, initial: _birthDate);
              if (d != null) setState(() => _birthDate = d);
            },
          ),
          const SizedBox(height: Space.m),
          PickerField(
            label: l10n.translate('birthTimeOptional'),
            icon: Icons.schedule_rounded,
            value: _birthTime?.format(context),
            placeholder: l10n.translate('selectTime'),
            onTap: () async {
              final t = await showTimePicker(
                  context: context,
                  initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0));
              if (t != null) setState(() => _birthTime = t);
            },
          ),
          const SizedBox(height: Space.m),
          TextFormField(
            controller: _birthPlace,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: l10n.translate('birthCity'),
                prefixIcon: const Icon(Icons.place_outlined)),
          ),
          const SizedBox(height: Space.m),
          // Choisi dans la liste (nom enregistré dans la langue de l'app).
          PickerField(
            label: l10n.translate('birthCountry'),
            icon: Icons.public_rounded,
            value: _birthCountry.text.trim().isEmpty
                ? null
                : _birthCountry.text.trim(),
            placeholder: l10n.translate('chooseCountry'),
            onTap: () async {
              final c = await showCountrySheet(context);
              if (c != null && context.mounted) {
                setState(() => _birthCountry.text = countryLabel(context, c));
              }
            },
          ),
          const SizedBox(height: Space.m),
          TextFormField(
            controller: _currentCity,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: l10n.translate('currentCity'),
                prefixIcon: const Icon(Icons.home_outlined)),
          ),
          const SizedBox(height: Space.m),
          PickerField(
            label: l10n.translate('countryOfResidence'),
            icon: Icons.flag_outlined,
            leading: country == null ? null : Text(country.flagEmoji),
            value: country == null ? null : countryLabel(context, country),
            placeholder: l10n.translate('chooseCountry'),
            onTap: () async {
              final c = await showCountrySheet(context, selected: _countryCode);
              if (c != null) setState(() => _countryCode = c.countryCode);
            },
          ),
        ],
      ),
    );
  }

  Widget _privacy() {
    final l10n = AppLocalizations.of(context);
    Widget toggle(String label, bool value, ValueChanged<bool> onChanged) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          value: value,
          onChanged: onChanged,
        );
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.translate('publicProfile')),
            subtitle: Text(l10n.translate(!_canBePublic
                ? 'publicAgeRestriction'
                : _isPublic
                    ? 'publicProfileDesc'
                    : 'privateProfile')),
            value: _isPublic && _canBePublic,
            onChanged: !_canBePublic
                ? null
                : (v) => setState(() {
                      _isPublic = v;
                      if (!v) {
                        // Profil privé : plus rien n'est visible.
                        _publicName = _publicBirthDate = _publicBirthTime =
                            _publicBirthPlace = _publicBirthCountry =
                                _publicBirthCity = _publicCountry =
                                    _publicPhoto = _publicSocials =
                                        _publicZodiac = false;
                      }
                    }),
          ),
          if (_isPublic && _canBePublic) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: Space.m, bottom: Space.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.translate('visibleInfo'),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
            toggle(l10n.translate('name'), _publicName,
                (v) => setState(() => _publicName = v)),
            toggle(l10n.translate('showMyPhoto'), _publicPhoto,
                (v) => setState(() => _publicPhoto = v)),
            toggle(l10n.translate('birthDate'), _publicBirthDate,
                (v) => setState(() => _publicBirthDate = v)),
            toggle(l10n.translate('birthTime'), _publicBirthTime,
                (v) => setState(() => _publicBirthTime = v)),
            toggle(l10n.translate('birthCity'), _publicBirthPlace,
                (v) => setState(() => _publicBirthPlace = v)),
            toggle(l10n.translate('birthCountry'), _publicBirthCountry,
                (v) => setState(() => _publicBirthCountry = v)),
            toggle(l10n.translate('currentCity'), _publicBirthCity,
                (v) => setState(() => _publicBirthCity = v)),
            toggle(l10n.translate('showMyCountry'), _publicCountry,
                (v) => setState(() => _publicCountry = v)),
            toggle(l10n.translate('zodiacSign'), _publicZodiac,
                (v) => setState(() => _publicZodiac = v)),
            toggle(l10n.translate('socialNetworks'), _publicSocials,
                (v) => setState(() => _publicSocials = v)),
          ],
        ],
      ),
    );
  }

  Widget _zodiacCard() {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final sign = Zodiac.computeZodiac(_birthDate!);
    final lang = l10n.locale.languageCode;
    return GlassCard(
      padding: const EdgeInsets.all(Space.l),
      onTap: () => Navigator.of(context).pushNamed('/zodiac'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(Icons.auto_awesome_outlined, tone: Tone.accent),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ZodiacContent.name(sign, lang), style: t.titleMedium),
                    Text(ZodiacContent.period(sign, lang), style: t.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: Space.m),
          Text(ZodiacContent.description(sign, lang),
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
      child: Column(
        children: [
          // RGPD : consentement aux statistiques, réversible à tout moment.
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
            onTap: _showBlocked,
          ),
        ],
      ),
    );
  }

  Widget _accountCard(UserProfile? profile) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
      child: Column(
        children: [
          ActionRow(
            icon: Icons.mark_email_unread_outlined,
            title: l10n.translate('myWishes'),
            subtitle: l10n.translate('myWishesDesc'),
            tone: Tone.accent,
            onTap: () => Navigator.of(context).pushNamed('/wishes'),
          ),
          const CardDivider(),
          ActionRow(
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
          const CardDivider(),
          ActionRow(
            icon: Icons.privacy_tip_outlined,
            title: l10n.translate('privacyPolicy'),
            tone: Tone.neutral,
            onTap: () => launchUrl(Uri.parse(AppLinks.privacy),
                mode: LaunchMode.externalApplication),
          ),
          const CardDivider(),
          ActionRow(
            icon: Icons.logout_rounded,
            title: l10n.translate('logout'),
            tone: Tone.neutral,
            onTap: () => account.signOut(context),
          ),
          const CardDivider(),
          ActionRow(
            icon: Icons.delete_outline_rounded,
            title: l10n.translate('deleteAccount'),
            subtitle: l10n.translate('deleteAccountDesc'),
            tone: Tone.danger,
            onTap: () => account.deleteAccount(context),
          ),
        ],
      ),
    );
  }
}

/// Ajout d'un réseau social : plateforme puis adresse du profil.
class _SocialLinkSheet extends StatefulWidget {
  const _SocialLinkSheet();

  @override
  State<_SocialLinkSheet> createState() => _SocialLinkSheetState();
}

class _SocialLinkSheetState extends State<_SocialLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  String _platform = SocialLinksWidget.platforms.first;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  /// Une adresse plausible : un domaine, pas d'espace.
  static bool _looksLikeUrl(String s) {
    final v = s.trim();
    if (v.isEmpty || v.contains(' ')) return false;
    final uri = Uri.tryParse(v.startsWith('http') ? v : 'https://$v');
    return uri != null && uri.host.contains('.');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.translate('add_social_link'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.l),
            DropdownButtonFormField<String>(
              initialValue: _platform,
              style: Theme.of(context).textTheme.bodyLarge,
              borderRadius: BorderRadius.circular(Radii.control),
              decoration: InputDecoration(
                labelText: l10n.translate('choose_platform'),
                prefixIcon: Icon(SocialLinksWidget.iconFor(_platform)),
              ),
              items: [
                for (final p in SocialLinksWidget.platforms)
                  DropdownMenuItem(
                      value: p, child: Text(SocialLinksWidget.displayName(p))),
              ],
              onChanged: (v) => setState(() => _platform = v ?? _platform),
            ),
            const SizedBox(height: Space.m),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.translate('url_link'),
                hintText: 'instagram.com/…',
                prefixIcon: const Icon(Icons.link_rounded),
              ),
              validator: (v) =>
                  _looksLikeUrl(v ?? '') ? null : l10n.translate('invalidUrl'),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.of(context).pop((_platform, _url.text.trim()));
              },
              child: Text(l10n.translate('add')),
            ),
          ],
        ),
      ),
    );
  }
}
