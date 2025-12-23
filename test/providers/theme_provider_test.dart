import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/providers/theme_provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeProvider Tests', () {
    test('Mode initial est light', () {
      final provider = ThemeProvider();
      expect(provider.mode, ThemeMode.light);
    });

    test('toggleTheme change le mode', () {
      final provider = ThemeProvider();
      expect(provider.mode, ThemeMode.light);

      provider.toggleTheme();
      expect(provider.mode, ThemeMode.dark);

      provider.toggleTheme();
      expect(provider.mode, ThemeMode.light);
    });

    test('Plusieurs toggles fonctionnent correctement', () {
      final provider = ThemeProvider();

      provider.toggleTheme(); // dark
      provider.toggleTheme(); // light
      provider.toggleTheme(); // dark

      expect(provider.mode, ThemeMode.dark);
    });

    test('notifyListeners est appelé lors du toggle', () {
      final provider = ThemeProvider();
      bool listenerCalled = false;

      provider.addListener(() {
        listenerCalled = true;
      });

      provider.toggleTheme();
      expect(listenerCalled, true);
    });
  });
}
