import 'dart:ui' show PlatformDispatcher;

import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday_labels.dart';
import '../utils/zodiac.dart';
import '../widgets/social_links_widget.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';
import '../widgets/ui/birth_date_picker.dart';

/// Création du profil après la première connexion : la date de naissance
/// est indispensable (rappels, annuaire « Même jour »).
class ProfileRegistrationScreen extends StatefulWidget {
  const ProfileRegistrationScreen({super.key});

  @override
  State<ProfileRegistrationScreen> createState() =>
      _ProfileRegistrationScreenState();
}

class _ProfileRegistrationScreenState extends State<ProfileRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _given = TextEditingController();
  final _family = TextEditingController();
  final _birthPlace = TextEditingController();
  final _social = TextEditingController();
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  bool _dateError = false;
  bool _saving = false;
  bool _isPublic = false;
  bool _publicName = false;
  bool _publicBirthDate = false;
  bool _publicBirthPlace = false;
  bool _publicSocials = false;
  bool _publicCountry = false;

  /// Pays de résidence, pré-rempli avec celui de l'appareil (modifiable).
  String? _countryCode = _deviceCountry();

  static String? _deviceCountry() {
    final code = PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    return UserProfile.isValidCountryCode(code) ? code : null;
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'ProfileRegistrationScreen');
    // Pré-remplir avec le nom du compte Google s'il existe.
    try {
      final displayName =
          FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
      if (displayName.isNotEmpty) {
        final parts = displayName.split(RegExp(r'\s+'));
        _given.text = parts.first;
        _family.text = parts.skip(1).join(' ');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _given.dispose();
    _family.dispose();
    _birthPlace.dispose();
    _social.dispose();
    super.dispose();
  }

  /// Moins de 16 ans : pas d'annuaire public (voir UserProfile.minPublicAge).
  bool get _canBePublic =>
      _birthDate == null || UserProfile.canBePublic(_birthDate!);

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final valid = _formKey.currentState!.validate();
    setState(() => _dateError = _birthDate == null);
    if (!valid || _birthDate == null) return;

    final given = _given.text.trim(), family = _family.text.trim();
    final b = _birthDate!;
    final social = _social.text.trim();
    final profile = UserProfile(
      name: '$given $family'.trim(),
      givenName: given,
      familyName: family,
      birthDate: DateTime(b.year, b.month, b.day),
      birthTime: _birthTime == null
          ? null
          : '${_birthTime!.hour.toString().padLeft(2, '0')}:'
              '${_birthTime!.minute.toString().padLeft(2, '0')}',
      birthplace: _birthPlace.text.trim().isEmpty ? null : _birthPlace.text.trim(),
      socialLinks: social.isEmpty
          ? null
          : {SocialLinksWidget.platformFromUrl(social): social},
      zodiac: Zodiac.computeZodiac(b),
      isPublic: _isPublic && _canBePublic,
      publicName: _publicName,
      publicBirthDate: _publicBirthDate,
      publicBirthPlace: _publicBirthPlace,
      publicSocials: _publicSocials,
      countryCode: _countryCode,
      publicCountry: _publicCountry,
    );
    setState(() => _saving = true);
    try {
      await context.read<ProfileProvider>().save(profile, push: true);
    } catch (e) {
      debugPrint('❌ Enregistrement du profil: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('actionFailed'))));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final country = _countryCode == null ? null : Country.tryParse(_countryCode!);
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.translate('regRequired') : null;

    Widget toggle(String label, bool value, ValueChanged<bool> onChanged) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label, style: t.bodyLarge),
          value: value,
          onChanged: onChanged,
        );

    return AppScaffold(
      title: Text(l10n.translate('regCreateYourProfile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppScaffold.pagePadding(context),
          children: [
            Text(l10n.translate('regCompleteYourInformationToGet'),
                style: t.bodyLarge?.copyWith(color: c.onSurfaceVariant)),
            SectionHeader(l10n.translate('regIdentity')),
            GlassCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _given,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        labelText: l10n.translate('regGivenNameFirst'),
                        prefixIcon: const Icon(Icons.person_outline_rounded)),
                    validator: required,
                  ),
                  const SizedBox(height: Space.m),
                  TextFormField(
                    controller: _family,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                        labelText: l10n.translate('regFamilyNameLast'),
                        prefixIcon: const Icon(Icons.badge_outlined)),
                    validator: required,
                  ),
                ],
              ),
            ),
            SectionHeader(l10n.translate('regBirth')),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PickerField(
                    label: l10n.translate('regBirthDate'),
                    icon: Icons.cake_outlined,
                    value: _birthDate == null
                        ? null
                        : fullDateLabel(l10n, _birthDate!),
                    placeholder: l10n.translate('selectDate'),
                    onTap: () async {
                      final d = await showBirthDatePicker(context,
                          initial: _birthDate);
                      if (d != null) {
                        setState(() {
                          _birthDate = d;
                          _dateError = false;
                        });
                      }
                    },
                  ),
                  if (_dateError)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: Space.l, top: Space.xs),
                      child: Text(l10n.translate('birthDateRequired'),
                          style: t.bodySmall?.copyWith(color: c.error)),
                    ),
                  const SizedBox(height: Space.m),
                  PickerField(
                    label: l10n.translate('regBirthTimeOptional'),
                    icon: Icons.schedule_rounded,
                    value: _birthTime?.format(context),
                    placeholder: l10n.translate('selectTime'),
                    onTap: () async {
                      final tm = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 0));
                      if (tm != null) setState(() => _birthTime = tm);
                    },
                  ),
                  const SizedBox(height: Space.m),
                  TextFormField(
                    controller: _birthPlace,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                        labelText: l10n.translate('regBirthPlaceCityCountry'),
                        prefixIcon: const Icon(Icons.place_outlined)),
                  ),
                ],
              ),
            ),
            SectionHeader(l10n.translate('regWhereYouLive')),
            GlassCard(
              child: Column(
                children: [
                  PickerField(
                    label: l10n.translate('countryOfResidence'),
                    icon: Icons.flag_outlined,
                    leading: country == null ? null : Text(country.flagEmoji),
                    value: country == null
                        ? null
                        : CountryLocalizations.of(context)
                                ?.countryName(countryCode: country.countryCode) ??
                            country.name,
                    placeholder: l10n.translate('chooseCountry'),
                    onTap: () => showCountryPicker(
                      context: context,
                      onSelect: (c) =>
                          setState(() => _countryCode = c.countryCode),
                    ),
                  ),
                  const SizedBox(height: Space.m),
                  TextFormField(
                    controller: _social,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                        labelText: l10n.translate('regPublicSocialLinkOptional'),
                        prefixIcon: const Icon(Icons.link_rounded)),
                  ),
                ],
              ),
            ),
            SectionHeader(l10n.translate('regPrivacy')),
            GlassCard(
              padding:
                  const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.translate('regMakeMyProfilePublic')),
                    subtitle: Text(l10n.translate(_canBePublic
                        ? 'regPublicExplain'
                        : 'publicAgeRestriction')),
                    value: _isPublic && _canBePublic,
                    onChanged: _canBePublic
                        ? (v) => setState(() => _isPublic = v)
                        : null,
                  ),
                  if (_isPublic && _canBePublic) ...[
                    const Divider(),
                    toggle(l10n.translate('regShowMyName'), _publicName,
                        (v) => setState(() => _publicName = v)),
                    toggle(l10n.translate('regShowMyFullBirthDate'),
                        _publicBirthDate,
                        (v) => setState(() => _publicBirthDate = v)),
                    toggle(l10n.translate('regShowMyBirthPlace'),
                        _publicBirthPlace,
                        (v) => setState(() => _publicBirthPlace = v)),
                    toggle(l10n.translate('showMyCountry'), _publicCountry,
                        (v) => setState(() => _publicCountry = v)),
                    toggle(l10n.translate('regShowMySocialLinks'),
                        _publicSocials,
                        (v) => setState(() => _publicSocials = v)),
                  ],
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
                  : Text(l10n.translate('regSaveProfile')),
            ),
          ],
        ),
      ),
    );
  }
}
