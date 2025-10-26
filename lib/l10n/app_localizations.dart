import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Birthgram',
      'home': 'Home',
      'contacts': 'Contacts',
      'celebrations': 'Celebrations',
      'settings': 'Settings',
      'changeTheme': 'Change Theme',
      'changeLanguage': 'Change Language',
      'dark': 'Dark',
      'light': 'Light',
      'system': 'System',
    },
    'fr': {
      'appTitle': 'Birthgram',
      'home': 'Accueil',
      'contacts': 'Contacts',
      'celebrations': 'Célébrations',
      'settings': 'Paramètres',
      'changeTheme': 'Changer le thème',
      'changeLanguage': 'Changer la langue',
      'dark': 'Sombre',
      'light': 'Clair',
      'system': 'Système',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
