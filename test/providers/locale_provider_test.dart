import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:b_link/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocaleProvider Tests', () {
    test('Locale initiale = langue de l\'appareil si supportée, sinon anglais',
        () {
      expect(LocaleProvider(deviceLanguage: 'fr').locale.languageCode, 'fr');
      expect(LocaleProvider(deviceLanguage: 'de').locale.languageCode, 'en');
    });

    test('la langue choisie est mémorisée entre deux lancements', () async {
      LocaleProvider(deviceLanguage: 'en').setLocale(const Locale('fr'));
      await Future<void>.delayed(Duration.zero);
      expect(await LocaleProvider.savedLanguageCode(), 'fr');

      final restarted = LocaleProvider(deviceLanguage: 'en');
      await Future<void>.delayed(Duration.zero);
      expect(restarted.locale.languageCode, 'fr');
    });

    test('une langue non supportée retombe sur l\'anglais', () {
      final provider = LocaleProvider(deviceLanguage: 'fr')
        ..setLocale(const Locale('es'));
      expect(provider.locale.languageCode, 'en');
    });

    test('setLocale change la langue', () {
      final provider = LocaleProvider();

      provider.setLocale(Locale('en'));
      expect(provider.locale.languageCode, 'en');

      provider.setLocale(Locale('fr'));
      expect(provider.locale.languageCode, 'fr');
    });

    test('notifyListeners est appelé lors du changement', () {
      final provider = LocaleProvider();
      bool listenerCalled = false;

      provider.addListener(() {
        listenerCalled = true;
      });

      provider.setLocale(Locale('en'));
      expect(listenerCalled, true);
    });

    test('Changements multiples de locale', () {
      final provider = LocaleProvider(deviceLanguage: 'en');

      provider.setLocale(Locale('en'));
      provider.setLocale(Locale('es'));
      provider.setLocale(Locale('fr'));

      expect(provider.locale.languageCode, 'fr');
    });
  });
}
