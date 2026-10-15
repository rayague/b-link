import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import '../utils/zodiac.dart';
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

class ProfileRegistrationScreen extends StatefulWidget {
  const ProfileRegistrationScreen({super.key});

  @override
  State<ProfileRegistrationScreen> createState() =>
      _ProfileRegistrationScreenState();
}

class _ProfileRegistrationScreenState extends State<ProfileRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _givenCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  final _birthPlaceCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
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
    AnalyticsService().logScreenView(
      screenName: 'ProfileRegistrationScreen',
      screenClass: 'ProfileRegistrationScreen',
    );
    // Pré-remplir avec le nom du compte Google s'il existe.
    final displayName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      final parts = displayName.split(RegExp(r'\s+'));
      _givenCtrl.text = parts.first;
      _familyCtrl.text = parts.skip(1).join(' ');
    }
  }

  @override
  void dispose() {
    _givenCtrl.dispose();
    _familyCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _socialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFEC4899), // Pink
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).translate('regCreateYourProfile'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).translate('regCompleteYourInformationToGet'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Form Container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          // Given Name
                          _buildTextField(
                            controller: _givenCtrl,
                            label: AppLocalizations.of(context).translate('regGivenNameFirst'),
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty
                                ? AppLocalizations.of(context).translate('regRequired')
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Family Name
                          _buildTextField(
                            controller: _familyCtrl,
                            label: AppLocalizations.of(context).translate('regFamilyNameLast'),
                            icon: Icons.family_restroom_outlined,
                            validator: (v) => v == null || v.isEmpty
                                ? AppLocalizations.of(context).translate('regRequired')
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Birth Date
                          _buildDatePicker(),
                          const SizedBox(height: 16),

                          // Birth Time
                          _buildTimePicker(),
                          const SizedBox(height: 16),

                          // Pays de résidence
                          _buildCountryPicker(),
                          const SizedBox(height: 16),

                          // Birth Place
                          _buildTextField(
                            controller: _birthPlaceCtrl,
                            label: AppLocalizations.of(context).translate('regBirthPlaceCityCountry'),
                            icon: Icons.location_on_outlined,
                            required: false,
                          ),
                          const SizedBox(height: 16),

                          // Social Link
                          _buildTextField(
                            controller: _socialCtrl,
                            label: AppLocalizations.of(context).translate('regPublicSocialLinkOptional'),
                            icon: Icons.link_outlined,
                            required: false,
                          ),
                          const SizedBox(height: 24),

                          // Privacy Section
                          _buildPrivacySection(),

                          const SizedBox(height: 32),

                          // Save Button
                          _buildSaveButton(),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime(1990, 1, 1),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (d != null) setState(() => _birthDate = d);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: const Color(0xFF6366F1)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _birthDate == null
                    ? AppLocalizations.of(context).translate('regBirthDate')
                    : _birthDate!.toLocal().toString().split(' ')[0],
                style: TextStyle(
                  fontSize: 16,
                  color: _birthDate == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 12, minute: 0),
        );
        if (t != null) setState(() => _birthTime = t);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: const Color(0xFF6366F1)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _birthTime == null
                    ? AppLocalizations.of(context).translate('regBirthTimeOptional')
                    : _birthTime!.format(context),
                style: TextStyle(
                  fontSize: 16,
                  color: _birthTime == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).translate('regPrivacy'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context).translate('regMakeMyProfilePublic'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: _canBePublic
                ? null
                : Text(AppLocalizations.of(context)
                    .translate('publicAgeRestriction')),
            value: _isPublic && _canBePublic,
            activeThumbColor: const Color(0xFF6366F1),
            onChanged:
                _canBePublic ? (v) => setState(() => _isPublic = v) : null,
          ),
          if (_isPublic && _canBePublic) ...[
            const Divider(),
            _buildCheckbox(
              AppLocalizations.of(context).translate('regShowMyName'),
              _publicName,
              (v) => setState(() => _publicName = v ?? false),
            ),
            _buildCheckbox(
              AppLocalizations.of(context).translate('regShowMyFullBirthDate'),
              _publicBirthDate,
              (v) => setState(() => _publicBirthDate = v ?? false),
            ),
            _buildCheckbox(
              AppLocalizations.of(context).translate('regShowMyBirthPlace'),
              _publicBirthPlace,
              (v) => setState(() => _publicBirthPlace = v ?? false),
            ),
            _buildCheckbox(
              AppLocalizations.of(context).translate('regShowMySocialLinks'),
              _publicSocials,
              (v) => setState(() => _publicSocials = v ?? false),
            ),
            _buildCheckbox(
              AppLocalizations.of(context).translate('showMyCountry'),
              _publicCountry,
              (v) => setState(() => _publicCountry = v ?? false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountryPicker() {
    final country =
        _countryCode == null ? null : Country.tryParse(_countryCode!);
    final name = country == null
        ? null
        : CountryLocalizations.of(context)
                ?.countryName(countryCode: country.countryCode) ??
            country.name;
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => showCountryPicker(
        context: context,
        onSelect: (c) => setState(() => _countryCode = c.countryCode),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(country?.flagEmoji ?? '🌍', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name == null
                    ? l10n.translate('countryOfResidence')
                    : '${l10n.translate('countryOfResidence')} : $name',
                style: TextStyle(
                  fontSize: 16,
                  color: name == null ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// Moins de 16 ans : pas d'annuaire public (voir UserProfile.minPublicAge).
  bool get _canBePublic =>
      _birthDate == null || UserProfile.canBePublic(_birthDate!);

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      activeColor: const Color(0xFF6366F1),
      onChanged: onChanged,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).translate('regSaveProfile'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('birthDateRequired'))));
      return;
    }
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final displayName = '${_givenCtrl.text} ${_familyCtrl.text}';
    final profile = UserProfile(
      name: displayName,
      givenName: _givenCtrl.text,
      familyName: _familyCtrl.text,
      birthDate: DateTime(_birthDate!.year, _birthDate!.month, _birthDate!.day),
      birthTime: _birthTime == null
          ? null
          : '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}',
      birthplace: _birthPlaceCtrl.text.isEmpty ? null : _birthPlaceCtrl.text,
      socialLinks:
          _socialCtrl.text.isEmpty ? null : {'primary': _socialCtrl.text},
      zodiac: Zodiac.computeZodiac(_birthDate!),
      isPublic: _isPublic && _canBePublic,
      publicName: _publicName,
      publicBirthDate: _publicBirthDate,
      publicBirthPlace: _publicBirthPlace,
      publicSocials: _publicSocials,
      countryCode: _countryCode,
      publicCountry: _publicCountry,
    );
    try {
      await provider.save(profile, push: true);
    } catch (e) {
      debugPrint('❌ Enregistrement du profil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('actionFailed'))));
      return;
    }
    // After save, navigate home
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }
}
