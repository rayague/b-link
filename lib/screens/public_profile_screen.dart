import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../widgets/social_links_widget.dart';
import '../widgets/birth_insights_widget.dart';
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/safety_service.dart';

class PublicProfileScreen extends StatelessWidget {
  static const routeName = '/public-profile';
  final UserProfile profile;

  const PublicProfileScreen({
    super.key,
    required this.profile,
  });

  Future<void> _report(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.translate('reportReason')),
        children: [
          for (final r in SafetyService.reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(r),
              child: Text(l10n.translate('reason_$r')),
            ),
        ],
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
  Future<void> _block(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.translate('blockConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.translate('cancel'))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.translate('block'))),
        ],
      ),
    );
    if (ok != true) return;
    await SafetyService().block(profile.uid!,
        name: profile.publicName ? profile.name : null);
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.translate('profileBlocked'))));
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Track screen view
    AnalyticsService().logScreenView(
      screenName: 'PublicProfileScreen',
      screenClass: 'PublicProfileScreen',
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFFF9FAFB), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                actions: [
                  if (profile.uid != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) => value == 'report'
                          ? _report(context)
                          : _block(context),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'report',
                            child: Text(l10n.translate('report'))),
                        PopupMenuItem(
                            value: 'block',
                            child: Text(l10n.translate('block'))),
                      ],
                    ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCollapsed = constraints.maxHeight < 120;
                    return Stack(
                      fit: StackFit.expand,
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
                        // Avatar et nom
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  profile.isPublic
                                      ? Icons.person_rounded
                                      : Icons.lock_rounded,
                                  size: 40,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                              if (!isCollapsed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: profile.isPublic && profile.publicName
                                      ? Text(
                                          profile.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          l10n.translate('privateProfile'),
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
                        // Nom dans la barre réduite
                        if (isCollapsed)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: profile.isPublic && profile.publicName
                                  ? Text(
                                      profile.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : Text(
                                      l10n.translate('privateProfile'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!profile.isPublic)
                        _buildPrivateProfileCard(isDark, l10n)
                      else ...[
                        // Public profile content
                        if (profile.publicBirthDate || profile.publicBirthTime)
                          _buildInfoSection(
                            l10n.translate('birthDate'),
                            Icons.cake_rounded,
                            _getFormattedBirthDate(),
                            isDark,
                          ),

                        if (profile.publicBirthCountry ||
                            profile.publicBirthPlace)
                          _buildInfoSection(
                            l10n.translate('birthPlace'),
                            Icons.location_on_rounded,
                            _getFormattedBirthPlace(),
                            isDark,
                          ),

                        if (profile.publicBirthCity &&
                            profile.birthCity != null)
                          _buildInfoSection(
                            l10n.translate('currentCity'),
                            Icons.home_rounded,
                            profile.birthCity!,
                            isDark,
                          ),

                        if (profile.publicZodiac && profile.zodiac != null)
                          _buildInfoSection(
                            l10n.translate('zodiacSign'),
                            Icons.stars_rounded,
                            profile.zodiac!,
                            isDark,
                          ),

                        // Social links
                        if (profile.publicSocials &&
                            profile.socialLinks != null &&
                            profile.socialLinks!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle(l10n.translate('socialNetworks'),
                              Icons.share_rounded, isDark),
                          const SizedBox(height: 12),
                          SocialLinksWidget(
                            socialLinks: profile.socialLinks!,
                            isCompact: false,
                          ),
                        ],

                        // Birth insights (fun facts)
                        if (profile.publicBirthDate) ...[
                          const SizedBox(height: 24),
                          BirthInsightsWidget(
                            birthDate: profile.birthDate,
                            birthTime: profile.publicBirthTime
                                ? profile.birthTime
                                : null,
                            birthPlace: profile.publicBirthPlace
                                ? profile.birthplace
                                : null,
                            birthCountry: profile.publicBirthCountry
                                ? profile.birthCountry
                                : null,
                          ),
                        ],
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivateProfileCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.translate('privateProfile'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('privateProfileDesc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
      String title, IconData icon, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedBirthDate([BuildContext? context]) {
    final parts = <String>[];
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (profile.publicBirthDate) {
      final months = l10n != null
          ? [
              l10n.translate('month_january'),
              l10n.translate('month_february'),
              l10n.translate('month_march'),
              l10n.translate('month_april'),
              l10n.translate('month_may'),
              l10n.translate('month_june'),
              l10n.translate('month_july'),
              l10n.translate('month_august'),
              l10n.translate('month_september'),
              l10n.translate('month_october'),
              l10n.translate('month_november'),
              l10n.translate('month_december'),
            ]
          : [
              'janvier',
              'février',
              'mars',
              'avril',
              'mai',
              'juin',
              'juillet',
              'août',
              'septembre',
              'octobre',
              'novembre',
              'décembre',
            ];
      parts.add(
          '${profile.birthDate.day} ${months[profile.birthDate.month - 1]} ${profile.birthDate.year}');
    }
    if (profile.publicBirthTime && profile.birthTime != null) {
      parts.add(
          '${l10n != null ? l10n.translate('atTime') : 'à'} ${profile.birthTime}');
    }
    return parts.join(' ');
  }

  String _getFormattedBirthPlace() {
    final parts = <String>[];

    if (profile.publicBirthPlace && profile.birthplace != null) {
      parts.add(profile.birthplace!);
    }

    if (profile.publicBirthCountry && profile.birthCountry != null) {
      parts.add(profile.birthCountry!);
    }

    return parts.join(', ');
  }
}
