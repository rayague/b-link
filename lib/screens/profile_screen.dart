import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import '../widgets/social_links_widget.dart';
import '../widgets/birth_insights_widget.dart';
import '../l10n/app_localizations.dart';
import '../utils/network_error_handler.dart';
import 'admin_stats_screen.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _birthCountryController;
  late TextEditingController _birthCityController;
  Map<String, String> _socialLinks = {};
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  bool _isEditing = false;

  // Privacy settings
  bool _isPublic = false;
  bool _publicName = false;
  bool _publicBirthDate = false;
  bool _publicBirthTime = false;
  bool _publicBirthPlace = false;
  bool _publicBirthCountry = false;
  bool _publicBirthCity = false;
  bool _publicSocials = false;
  bool _publicZodiac = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    AnalyticsService().logScreenView(
      screenName: 'ProfileScreen',
      screenClass: 'ProfileScreen',
    );
    final prov = context.read<ProfileProvider>();
    final p = prov.profile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _birthPlaceController = TextEditingController(text: p?.birthplace ?? '');
    _birthCountryController =
        TextEditingController(text: p?.birthCountry ?? '');
    _birthCityController = TextEditingController(text: p?.birthCity ?? '');
    _socialLinks =
        p?.socialLinks != null ? Map<String, String>.from(p!.socialLinks!) : {};
    _birthDate = p?.birthDate;
    if (p?.birthTime != null) {
      final parts = p!.birthTime!.split(':');
      _birthTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    // Load privacy settings
    _isPublic = p?.isPublic ?? false;
    _publicName = p?.publicName ?? false;
    _publicBirthDate = p?.publicBirthDate ?? false;
    _publicBirthTime = p?.publicBirthTime ?? false;
    _publicBirthPlace = p?.publicBirthPlace ?? false;
    _publicBirthCountry = p?.publicBirthCountry ?? false;
    _publicBirthCity = p?.publicBirthCity ?? false;
    _publicSocials = p?.publicSocials ?? false;
    _publicZodiac = p?.publicZodiac ?? false;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<ProfileProvider>().profile;
    final zodiacSign = _birthDate != null ? _computeZodiac(_birthDate!) : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      body: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 220,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      // Détecter si l'AppBar est collapsée
                      final isCollapsed =
                          constraints.maxHeight <= kToolbarHeight + 40;

                      // Correction overflow: limiter la hauteur du contenu
                      return Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: constraints.maxHeight,
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Color(0xFFF3E8FF)
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        profile?.name.isNotEmpty == true
                                            ? profile!.name[0].toUpperCase()
                                            : '👤',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!isCollapsed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    profile?.name ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  actions: [
                    // Bouton Admin - Visible uniquement pour les admins
                    FutureBuilder<bool>(
                      future: _isAdminUser(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return IconButton(
                            icon: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminStatsScreen(),
                                ),
                              );
                            },
                            tooltip: 'Statistiques Admin',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.close : Icons.edit,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                  ],
                ),
                // Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Info Card
                            _buildInfoCard(isDark),
                            const SizedBox(height: 20),
                            // Zodiac Card (if birth date is set)
                            if (zodiacSign != null) ...[
                              _buildZodiacCard(zodiacSign, isDark),
                              const SizedBox(height: 20),
                            ],
                            // Birth Insights (fun facts)
                            if (_birthDate != null) ...[
                              BirthInsightsWidget(
                                birthDate: _birthDate!,
                                birthTime: _birthTime != null
                                    ? '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}'
                                    : null,
                                birthPlace: _birthPlaceController.text.isEmpty
                                    ? null
                                    : _birthPlaceController.text,
                                birthCountry:
                                    _birthCountryController.text.isEmpty
                                        ? null
                                        : _birthCountryController.text,
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Actions
                            _buildActionsSection(isDark),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ], // <-- Correction : fermeture du tableau slivers
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Valider le formulaire avant sauvegarde
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)
                  .translate('pleaseFillAllRequiredFields')),
            ],
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Vérifier que la date de naissance est définie
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).translate('birthDateRequired')),
            ],
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Créer le profil avec toutes les informations
      final updatedProfile = UserProfile(
        uid: context.read<ProfileProvider>().profile?.uid,
        name: _nameController.text.trim(),
        birthDate: _birthDate!,
        birthTime: _birthTime != null
            ? '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}'
            : null,
        birthplace: _birthPlaceController.text.trim().isEmpty
            ? null
            : _birthPlaceController.text.trim(),
        birthCountry: _birthCountryController.text.trim().isEmpty
            ? null
            : _birthCountryController.text.trim(),
        birthCity: _birthCityController.text.trim().isEmpty
            ? null
            : _birthCityController.text.trim(),
        socialLinks: Map<String, String>.from(_socialLinks),
        // Paramètres de confidentialité
        isPublic: _isPublic,
        publicName: _publicName,
        publicBirthDate: _publicBirthDate,
        publicBirthTime: _publicBirthTime,
        publicBirthPlace: _publicBirthPlace,
        publicBirthCountry: _publicBirthCountry,
        publicBirthCity: _publicBirthCity,
        publicSocials: _publicSocials,
        publicZodiac: _publicZodiac,
      );

      // Sauvegarder via le provider (local + Firebase)
      await context.read<ProfileProvider>().save(updatedProfile, push: true);

      // Passer en mode lecture
      setState(() {
        _isEditing = false;
      });

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).translate('profileSaved')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs avec messages personnalisés
      if (mounted) {
        final errorMessage = NetworkErrorHandler.getFirebaseErrorMessage(e);
        NetworkErrorHandler.showErrorSnackBar(
          context,
          errorMessage,
          onRetry: _saveProfile,
        );
      }
      // Ne pas sortir du mode édition en cas d'erreur
      debugPrint('❌ Erreur sauvegarde profil: $e');
    }
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).translate('personalInfo'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name Field
          _buildModernTextField(
            controller: _nameController,
            label: AppLocalizations.of(context).translate('fullName'),
            hint: 'Ex: Marie Dupont',
            icon: Icons.badge_outlined,
            isDark: isDark,
            enabled: _isEditing,
            validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
          ),
          const SizedBox(height: 16),

          // Birth Date
          _buildDateSelector(isDark),
          const SizedBox(height: 16),

          // Birth Time (Optional)
          _buildTimeSelector(isDark),
          const SizedBox(height: 16),

          // Birth Country (Required)
          _buildModernTextField(
            controller: _birthCountryController,
            label: AppLocalizations.of(context).translate('birthCountry'),
            hint: 'Ex: France',
            icon: Icons.flag_outlined,
            isDark: isDark,
            enabled: _isEditing,
            validator: (v) => v == null || v.isEmpty
                ? AppLocalizations.of(context).translate('enterName')
                : null,
          ),
          const SizedBox(height: 16),

          // Birth Place/City (Required)
          _buildModernTextField(
            controller: _birthPlaceController,
            label: AppLocalizations.of(context).translate('birthCity'),
            hint: 'Ex: Paris',
            icon: Icons.location_city_outlined,
            isDark: isDark,
            enabled: _isEditing,
            validator: (v) =>
                v == null || v.isEmpty ? 'Ville de naissance requise' : null,
          ),
          const SizedBox(height: 16),

          // Current City
          _buildModernTextField(
            controller: _birthCityController,
            label: AppLocalizations.of(context).translate('currentCity'),
            hint: 'Ex: Lyon',
            icon: Icons.home_outlined,
            isDark: isDark,
            enabled: _isEditing,
          ),
          const SizedBox(height: 24),

          // Privacy Settings Section
          if (_isEditing) _buildPrivacySection(context, isDark),
          if (_isEditing) const SizedBox(height: 24),

          // Social Links Section
          _buildSocialLinksSection(isDark),

          if (_isEditing) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).translate('save'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              icon,
              color: enabled
                  ? (isDark ? Colors.grey[400] : const Color(0xFF6B7280))
                  : Colors.grey[600],
            ),
            filled: true,
            fillColor: enabled
                ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB))
                : (isDark ? const Color(0xFF111827) : Colors.grey[100]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF8B5CF6),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('birthDate'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isEditing
              ? () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF8B5CF6),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (d != null) setState(() => _birthDate = d);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _isEditing
                  ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB))
                  : (isDark ? const Color(0xFF111827) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  color: _isEditing
                      ? (isDark ? Colors.grey[400] : const Color(0xFF6B7280))
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  _birthDate == null
                      ? l10n.translate('selectDate')
                      : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _birthDate == null
                        ? (isDark ? Colors.grey[600] : Colors.grey[400])
                        : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heure de naissance (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isEditing
              ? () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _birthTime ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF8B5CF6),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (t != null) setState(() => _birthTime = t);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _isEditing
                  ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB))
                  : (isDark ? const Color(0xFF111827) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _isEditing
                      ? (isDark ? Colors.grey[400] : const Color(0xFF6B7280))
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  _birthTime == null
                      ? AppLocalizations.of(context).translate('selectTime')
                      : _birthTime!.format(context),
                  style: TextStyle(
                    fontSize: 16,
                    color: _birthTime == null
                        ? (isDark ? Colors.grey[600] : Colors.grey[400])
                        : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZodiacCard(String zodiacSign, bool isDark) {
    final emoji = _zodiacEmoji(zodiacSign);
    final description = _zodiacDescription(zodiacSign);
    final period = _zodiacPeriod(zodiacSign);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF374151), const Color(0xFF1F2937)]
              : [const Color(0xFFFDF4FF), const Color(0xFFF3E8FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zodiacSign,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey[300] : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.share_rounded,
          title: 'Recommander l\'application',
          subtitle: 'Partagez B-Link avec vos amis',
          gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          isDark: isDark,
          onTap: () async {
            final profile = context.read<ProfileProvider>().profile;
            final shareText = profile == null
                ? 'Rejoins-moi sur B-Link ! 🎂'
                : 'Je suis ${profile.name}, rejoins-moi sur B-Link pour ne plus oublier les anniversaires! 🎉';
            await SharePlus.instance
                .share(ShareParams(text: shareText, subject: 'Rejoins B-Link'));
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _zodiacEmoji(String sign) {
    switch (sign) {
      case 'Bélier':
        return '♈';
      case 'Taureau':
        return '♉';
      case 'Gémeaux':
        return '♊';
      case 'Cancer':
        return '♋';
      case 'Lion':
        return '♌';
      case 'Vierge':
        return '♍';
      case 'Balance':
        return '♎';
      case 'Scorpion':
        return '♏';
      case 'Sagittaire':
        return '♐';
      case 'Capricorne':
        return '♑';
      case 'Verseau':
        return '♒';
      case 'Poissons':
        return '♓';
      default:
        return '✨';
    }
  }

  String _zodiacDescription(String sign) {
    switch (sign) {
      case 'Bélier':
        return 'Dynamique, courageux et impulsif. Vous aimez relever les défis et êtes toujours prêt pour l\'aventure.';
      case 'Taureau':
        return 'Stable, patient et sensuel. Vous appréciez les plaisirs de la vie et la sécurité.';
      case 'Gémeaux':
        return 'Curieux, adaptable et communicatif. Vous excellez dans la communication et adorez apprendre.';
      case 'Cancer':
        return 'Émotif, protecteur et intuitif. Vous êtes profondément attaché à votre famille et vos proches.';
      case 'Lion':
        return 'Charismatique, généreux et confiant. Vous aimez être au centre de l\'attention et inspirer les autres.';
      case 'Vierge':
        return 'Analytique, méthodique et réservé. Vous recherchez la perfection dans tout ce que vous faites.';
      case 'Balance':
        return 'Social, équilibré et juste. Vous recherchez l\'harmonie dans vos relations et votre environnement.';
      case 'Scorpion':
        return 'Passionné, intense et mystérieux. Vous vivez vos émotions profondément et avec intensité.';
      case 'Sagittaire':
        return 'Aventurier, optimiste et libre. Vous aimez explorer et découvrir de nouveaux horizons.';
      case 'Capricorne':
        return 'Ambitieux, discipliné et responsable. Vous travaillez dur pour atteindre vos objectifs.';
      case 'Verseau':
        return 'Original, humanitaire et indépendant. Vous aimez penser différemment et aider les autres.';
      case 'Poissons':
        return 'Empathique, artistique et rêveur. Vous êtes sensible et créatif avec une grande imagination.';
      default:
        return '';
    }
  }

  String _zodiacPeriod(String sign) {
    switch (sign) {
      case 'Bélier':
        return '21 Mars - 19 Avril';
      case 'Taureau':
        return '20 Avril - 20 Mai';
      case 'Gémeaux':
        return '21 Mai - 20 Juin';
      case 'Cancer':
        return '21 Juin - 22 Juillet';
      case 'Lion':
        return '23 Juillet - 22 Août';
      case 'Vierge':
        return '23 Août - 22 Septembre';
      case 'Balance':
        return '23 Septembre - 22 Octobre';
      case 'Scorpion':
        return '23 Octobre - 21 Novembre';
      case 'Sagittaire':
        return '22 Novembre - 21 Décembre';
      case 'Capricorne':
        return '22 Décembre - 19 Janvier';
      case 'Verseau':
        return '20 Janvier - 18 Février';
      case 'Poissons':
        return '19 Février - 20 Mars';
      default:
        return '';
    }
  }

  String _computeZodiac(DateTime birthDate) {
    final m = birthDate.month;
    final d = birthDate.day;
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'Verseau';
    if ((m == 2 && d >= 19) || (m == 3 && d <= 20)) return 'Poissons';
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'Bélier';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'Taureau';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return 'Gémeaux';
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return 'Cancer';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'Lion';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'Vierge';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return 'Balance';
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return 'Scorpion';
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return 'Sagittaire';
    return 'Capricorne';
  }

  Widget _buildSocialLinksSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.share_rounded,
              size: 20,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).translate('socialNetworks'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            if (_isEditing)
              IconButton(
                onPressed: () => _showAddSocialLinkDialog(isDark),
                icon: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                tooltip:
                    AppLocalizations.of(context).translate('addSocialNetwork'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_socialLinks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.link_off_rounded,
                  size: 48,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  _isEditing
                      ? 'Cliquez sur + pour ajouter un réseau social'
                      : 'Aucun réseau social ajouté',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          )
        else
          SocialLinksWidget(
            socialLinks: _socialLinks,
            isCompact: false,
          ),
      ],
    );
  }

  void _showAddSocialLinkDialog(bool isDark) {
    String? selectedPlatform;
    final urlController = TextEditingController();
    final platforms = [
      'Facebook',
      'Instagram',
      'Twitter',
      'LinkedIn',
      'YouTube',
      'TikTok',
      'Snapchat',
      'WhatsApp',
      'Telegram',
      'GitHub',
      'Discord',
      'Reddit',
      'Pinterest',
      'Twitch',
      'Spotify',
      'Autre',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('add_social_link'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlatform,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      prefixIcon: const Icon(Icons.apps_rounded),
                    ),
                    hint: Text(
                      AppLocalizations.of(context).translate('choose_platform'),
                      style: TextStyle(
                        color:
                            isDark ? Colors.grey[500] : const Color(0xFF9CA3AF),
                      ),
                    ),
                    dropdownColor:
                        isDark ? const Color(0xFF374151) : Colors.white,
                    items: platforms
                        .map((platform) => DropdownMenuItem(
                              value: platform,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _getSocialColors(
                                            platform.toLowerCase()),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      _getSocialIcon(platform.toLowerCase()),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(platform),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedPlatform = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('url_link'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.grey[300] : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link_rounded),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey[700]!
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey[700]!
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).translate('cancel'),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedPlatform != null &&
                                  urlController.text.isNotEmpty) {
                                setState(() {
                                  _socialLinks[selectedPlatform!
                                      .toLowerCase()] = urlController.text;
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context).translate('add'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF374151), const Color(0xFF1F2937)]
              : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.translate('privacySettings'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Master Public Switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isPublic
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPublic
                          ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                          : [const Color(0xFF6B7280), const Color(0xFF9CA3AF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isPublic ? Icons.public_rounded : Icons.lock_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('publicProfile'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        _isPublic
                            ? l10n.translate('publicProfileDesc')
                            : l10n.translate('privateProfile'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                      if (!value) {
                        // If profile becomes private, disable all visibility
                        _publicName = false;
                        _publicBirthDate = false;
                        _publicBirthTime = false;
                        _publicBirthPlace = false;
                        _publicBirthCountry = false;
                        _publicBirthCity = false;
                        _publicSocials = false;
                        _publicZodiac = false;
                      }
                    });
                  },
                  activeThumbColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),

          if (_isPublic) ...[
            const SizedBox(height: 16),
            Text(
              l10n.translate('visibleInfo'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            _buildPrivacySwitch(l10n.translate('name'), _publicName,
                Icons.badge_outlined, isDark, (val) {
              setState(() => _publicName = val);
            }),
            _buildPrivacySwitch(l10n.translate('birthDate'), _publicBirthDate,
                Icons.cake_outlined, isDark, (val) {
              setState(() => _publicBirthDate = val);
            }),
            _buildPrivacySwitch(l10n.translate('birthTime'), _publicBirthTime,
                Icons.access_time_outlined, isDark, (val) {
              setState(() => _publicBirthTime = val);
            }),
            _buildPrivacySwitch(l10n.translate('birthCountry'),
                _publicBirthCountry, Icons.flag_outlined, isDark, (val) {
              setState(() => _publicBirthCountry = val);
            }),
            _buildPrivacySwitch(l10n.translate('birthCity'), _publicBirthPlace,
                Icons.location_city_outlined, isDark, (val) {
              setState(() => _publicBirthPlace = val);
            }),
            _buildPrivacySwitch(l10n.translate('currentCity'), _publicBirthCity,
                Icons.home_outlined, isDark, (val) {
              setState(() => _publicBirthCity = val);
            }),
            _buildPrivacySwitch(l10n.translate('myZodiac'), _publicZodiac,
                Icons.stars_rounded, isDark, (val) {
              setState(() => _publicZodiac = val);
            }),
            _buildPrivacySwitch(l10n.translate('socialNetworks'),
                _publicSocials, Icons.share_outlined, isDark, (val) {
              setState(() => _publicSocials = val);
            }),
          ],
        ],
      ),
    );
  }

  /// Vérifier si l'utilisateur actuel est l'administrateur
  Future<bool> _isAdminUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Vérifier dans Firestore si l'utilisateur est admin
    final adminService = AdminService();
    return await adminService.isUserAdmin(user.uid);
  }

  Widget _buildPrivacySwitch(
    String label,
    bool value,
    IconData icon,
    bool isDark,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value
                  ? const Color(0xFF3B82F6)
                  : (isDark ? Colors.grey[600] : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF3B82F6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
      case 'x':
        return Icons.alternate_email;
      case 'linkedin':
        return Icons.business;
      case 'youtube':
        return Icons.play_arrow;
      case 'tiktok':
        return Icons.music_note;
      case 'snapchat':
        return Icons.camera;
      case 'whatsapp':
        return Icons.phone;
      case 'telegram':
        return Icons.send;
      case 'github':
        return Icons.code;
      case 'discord':
        return Icons.forum;
      case 'reddit':
        return Icons.reddit;
      case 'pinterest':
        return Icons.push_pin;
      case 'twitch':
        return Icons.videocam;
      case 'spotify':
        return Icons.music_video;
      default:
        return Icons.link;
    }
  }

  List<Color> _getSocialColors(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return [const Color(0xFF1877F2), const Color(0xFF42A5F5)];
      case 'instagram':
        return [const Color(0xFFE4405F), const Color(0xFFFCAF45)];
      case 'twitter':
      case 'x':
        return [const Color(0xFF1DA1F2), const Color(0xFF42A5F5)];
      case 'linkedin':
        return [const Color(0xFF0A66C2), const Color(0xFF42A5F5)];
      case 'youtube':
        return [const Color(0xFFFF0000), const Color(0xFFE57373)];
      case 'tiktok':
        return [const Color(0xFF000000), const Color(0xFF69C9D0)];
      case 'snapchat':
        return [const Color(0xFFFFFC00), const Color(0xFFFDD835)];
      case 'whatsapp':
        return [const Color(0xFF25D366), const Color(0xFF66BB6A)];
      case 'telegram':
        return [const Color(0xFF0088CC), const Color(0xFF42A5F5)];
      case 'github':
        return [const Color(0xFF181717), const Color(0xFF424242)];
      case 'discord':
        return [const Color(0xFF5865F2), const Color(0xFF7289DA)];
      case 'reddit':
        return [const Color(0xFFFF4500), const Color(0xFFFF6B35)];
      case 'pinterest':
        return [const Color(0xFFE60023), const Color(0xFFE57373)];
      case 'twitch':
        return [const Color(0xFF9146FF), const Color(0xFFAB47BC)];
      case 'spotify':
        return [const Color(0xFF1DB954), const Color(0xFF66BB6A)];
      default:
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
    }
  }
}
