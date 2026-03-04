import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/providers/theme_provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeProvider Tests', () {
    test('Mode initial est system', () {
      final provider = ThemeProvider();
      expect(provider.mode, ThemeMode.system);
    });

    test('setMode change le mode', () {
      final provider = ThemeProvider();
      provider.setMode(ThemeMode.light);
      expect(provider.mode, ThemeMode.light);

      provider.setMode(ThemeMode.dark);
      expect(provider.mode, ThemeMode.dark);
    });

    test('toggleTheme alterne entre light et dark', () {
      final provider = ThemeProvider();
      // From system, toggle goes to dark (since it's not dark)
      provider.toggleTheme();
      expect(provider.mode, ThemeMode.dark);

      provider.toggleTheme();
      expect(provider.mode, ThemeMode.light);

      provider.toggleTheme();
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

    test('notifyListeners est appelé lors de setMode', () {
      final provider = ThemeProvider();
      bool listenerCalled = false;

      provider.addListener(() {
        listenerCalled = true;
      });

      provider.setMode(ThemeMode.dark);
      expect(listenerCalled, true);
    });
  });
}
