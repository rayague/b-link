import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:b_link/providers/locale_provider.dart';

void main() {
  group('LocaleProvider Tests', () {
    test('Locale initial est français', () {
      final provider = LocaleProvider();
      expect(provider.locale.languageCode, 'fr');
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
      final provider = LocaleProvider();

      provider.setLocale(Locale('en'));
      provider.setLocale(Locale('es'));
      provider.setLocale(Locale('fr'));

      expect(provider.locale.languageCode, 'fr');
    });
  });
}
