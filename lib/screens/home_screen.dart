import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
// same_day_screen import removed - not used directly here

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logoApp.jpg', height: 36),
            const SizedBox(width: 8),
            Text(loc.translate('home')),
          ],
        ),
      ),
      drawer: const CustomAppDrawer(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative hero images
            Image.asset('assets/pictureFirst.jpg', width: 220, height: 140, fit: BoxFit.cover),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Text(loc.translate('appTitle'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Manage contacts and birthdays', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Image.asset('assets/pictureSecond.jpg', width: 200, height: 120, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }
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
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Center(
                child: Row(
                  children: [
                    Image.asset('assets/logoApp.jpg', height: 56),
                    const SizedBox(width: 12),
                    Expanded(child: Text(loc.translate('appTitle'), style: const TextStyle(color: Colors.white, fontSize: 20))),
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
              title: const Text('Mon profil'),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(loc.translate('changeTheme')),
              subtitle: Text(themeProv.mode == ThemeMode.dark ? loc.translate('dark') : themeProv.mode == ThemeMode.light ? loc.translate('light') : loc.translate('system')),
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
              child: Text('v1.0.0', style: Theme.of(context).textTheme.bodySmall),
            )
          ],
        ),
      ),
    );
  }
}
