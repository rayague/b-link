import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/contact_provider.dart';
import '../l10n/app_localizations.dart';
import '../test_notifications.dart';
import 'init_admin_screen.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final contacts = Provider.of<ContactProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Upcoming birthdays
    final upcomingBirthdays = contacts.contacts.where((c) {
      if (c.date.isEmpty) return false;
      final now = DateTime.now();
      final bday = DateTime.tryParse(c.date);
      if (bday == null) return false;
      final thisYear = DateTime(now.year, bday.month, bday.day);
      final diff = thisYear.difference(now).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                      : [
                          const Color(0xFF3B82F6),
                          const Color(0xFF60A5FA),
                          const Color(0xFF93C5FD)
                        ],
                ),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cake_outlined,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.translate('appTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Animated circles background
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Bouton temporaire pour initialiser le premier admin
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                tooltip: 'Initialiser Admin (à utiliser une seule fois)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InitAdminScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => _showSettingsSheet(context),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Card
                      _buildStatsCard(context, contacts, loc, isDark),
                      const SizedBox(height: 24),

                      // Upcoming Birthdays Section
                      if (upcomingBirthdays.isNotEmpty) ...[
                        _buildSectionHeader(
                            context, '🎉 ${loc.translate("celebrations")}', () {
                          Navigator.of(context).pushNamed('/same-day');
                        }),
                        const SizedBox(height: 12),
                        ...upcomingBirthdays.take(3).map((contact) =>
                            _buildUpcomingBirthdayCard(
                                context, contact, isDark)),
                        const SizedBox(height: 24),
                      ],

                      // Quick Actions
                      _buildSectionHeader(
                          context, '⚡ ${loc.translate("quickActions")}', null),
                      const SizedBox(height: 12),
                      _buildQuickActions(context, loc, isDark),

                      // Extra spacing for FAB
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null, // Removed to avoid overlap
    );
  }

  Widget _buildStatsCard(BuildContext context, ContactProvider contacts,
      AppLocalizations loc, bool isDark) {
    final totalContacts = contacts.contacts.length;
    final contactsWithBirthday =
        contacts.contacts.where((c) => c.date.isNotEmpty).length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F2937), const Color(0xFF374151)]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('yourContacts'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalContacts ${loc.translate("contactsCount")}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                Icons.cake_rounded,
                '$contactsWithBirthday',
                loc.translate('birthdaysLabel'),
                const Color(0xFFEC4899),
                isDark,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                Icons.notifications_active_rounded,
                '${contacts.contacts.where((c) => c.date.isNotEmpty).length}',
                loc.translate('activeLabel'),
                const Color(0xFF10B981),
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: Text(AppLocalizations.of(context).translate('viewAll')),
          ),
      ],
    );
  }

  Widget _buildUpcomingBirthdayCard(
      BuildContext context, dynamic contact, bool isDark) {
    final bdayStr = contact.date;
    if (bdayStr.isEmpty) return const SizedBox.shrink();

    final bday = DateTime.tryParse(bdayStr);
    if (bday == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final thisYear = DateTime(now.year, bday.month, bday.day);
    final daysUntil = thisYear.difference(now).inDays;

    final loc = AppLocalizations.of(context);
    String subtitleText;
    if (daysUntil == 0) {
      subtitleText = loc.translate('today');
    } else if (daysUntil == 1) {
      subtitleText =
          loc.translate('inDays').replaceAll('{count}', '$daysUntil');
    } else {
      subtitleText =
          loc.translate('inDaysPlural').replaceAll('{count}', '$daysUntil');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color((math.Random(contact.name.hashCode).nextDouble() *
                            0xFFFFFF)
                        .toInt())
                    .withOpacity(1.0),
                Color((math.Random(contact.name.hashCode + 1).nextDouble() *
                            0xFFFFFF)
                        .toInt())
                    .withOpacity(1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              contact.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(
            color: daysUntil == 0 ? const Color(0xFFEC4899) : null,
            fontWeight: daysUntil == 0 ? FontWeight.w600 : null,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEC4899).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${bday.day}/${bday.month}',
            style: const TextStyle(
              color: Color(0xFFEC4899),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, AppLocalizations loc, bool isDark) {
    final actions = [
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: loc.translate('addContactAction'),
        gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        onTap: () => Navigator.of(context).pushNamed('/list'),
      ),
      _QuickAction(
        icon: Icons.stars_rounded,
        label: loc.translate('myZodiac'),
        gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        onTap: () => Navigator.of(context).pushNamed('/zodiac'),
      ),
      _QuickAction(
        icon: Icons.cake_rounded,
        label: loc.translate('sameDayAction'),
        gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
        onTap: () => Navigator.of(context).pushNamed('/same-day'),
      ),
      _QuickAction(
        icon: Icons.person_rounded,
        label: loc.translate('myProfileAction'),
        gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
        onTap: () => Navigator.of(context).pushNamed('/profile'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: action.gradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: action.gradient[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CustomSettingsSheet(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}

class CustomAppDrawer extends StatelessWidget {
  const CustomAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Center(
                child: Row(
                  children: [
                    Image.asset('assets/logoApp.jpg', height: 56),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(loc.translate('appTitle'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20))),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(loc.translate('home')),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(loc.translate('contacts')),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(loc.translate('myProfile')),
              onTap: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: Text(loc.translate('celebrations')),
              onTap: () {
                Navigator.of(context).pushNamed('/same-day');
              },
            ),
            // DEBUG: Test notifications
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: const Text('🔔 Test Notifications', style: TextStyle(color: Colors.orange)),
              subtitle: const Text('Debug only', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(loc.translate('changeTheme')),
              subtitle: Text(themeProv.mode == ThemeMode.dark
                  ? loc.translate('dark')
                  : themeProv.mode == ThemeMode.light
                      ? loc.translate('light')
                      : loc.translate('system')),
              onTap: () {
                // cycle theme
                if (themeProv.mode == ThemeMode.system) {
                  themeProv.setMode(ThemeMode.light);
                } else if (themeProv.mode == ThemeMode.light) {
                  themeProv.setMode(ThemeMode.dark);
                } else {
                  themeProv.setMode(ThemeMode.system);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(loc.translate('changeLanguage')),
              subtitle: Text(localeProv.locale.languageCode.toUpperCase()),
              onTap: () {
                // toggle en/fr
                if (localeProv.locale.languageCode == 'en') {
                  localeProv.setLocale(const Locale('fr'));
                } else {
                  localeProv.setLocale(const Locale('en'));
                }
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child:
                  Text('v1.0.0', style: Theme.of(context).textTheme.bodySmall),
            )
          ],
        ),
      ),
    );
  }
}

// Modern Settings Bottom Sheet
class CustomSettingsSheet extends StatelessWidget {
  const CustomSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                child: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate('settings'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Theme Selector
          Text(
            '🎨 ${loc.translate("changeTheme")}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeOption(
                context,
                Icons.light_mode_rounded,
                loc.translate('light'),
                themeProv.mode == ThemeMode.light,
                () => themeProv.setMode(ThemeMode.light),
                const Color(0xFFFCD34D),
                isDark,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                Icons.dark_mode_rounded,
                loc.translate('dark'),
                themeProv.mode == ThemeMode.dark,
                () => themeProv.setMode(ThemeMode.dark),
                const Color(0xFF6366F1),
                isDark,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                Icons.brightness_auto_rounded,
                loc.translate('system'),
                themeProv.mode == ThemeMode.system,
                () => themeProv.setMode(ThemeMode.system),
                const Color(0xFF10B981),
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Language Selector
          Text(
            '🌍 ${loc.translate("changeLanguage")}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLanguageOption(
                context,
                '🇬🇧',
                'English',
                localeProv.locale.languageCode == 'en',
                () => localeProv.setLocale(const Locale('en')),
                isDark,
              ),
              const SizedBox(width: 12),
              _buildLanguageOption(
                context,
                '🇫🇷',
                'Français',
                localeProv.locale.languageCode == 'fr',
                () => localeProv.setLocale(const Locale('fr')),
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : (isDark ? const Color(0xFF374151) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String flag,
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3B82F6).withOpacity(0.15)
                : (isDark ? const Color(0xFF374151) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
