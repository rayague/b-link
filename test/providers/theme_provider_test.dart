import 'package:b_link/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le thème clair est le thème par défaut', () {
    expect(ThemeProvider().mode, ThemeMode.light);
  });

  test('setMode change le mode et le mémorise', () async {
    ThemeProvider().setMode(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    final restored = ThemeProvider();
    await Future<void>.delayed(Duration.zero);
    expect(restored.mode, ThemeMode.dark);
  });

  test('toggleTheme alterne entre clair et sombre', () {
    final provider = ThemeProvider();
    provider.toggleTheme();
    expect(provider.mode, ThemeMode.dark);
    provider.toggleTheme();
    expect(provider.mode, ThemeMode.light);
  });

  test('les écouteurs sont prévenus', () {
    final provider = ThemeProvider();
    var calls = 0;
    provider.addListener(() => calls++);
    provider.setMode(ThemeMode.dark);
    provider.toggleTheme();
    expect(calls, 2);
  });
}
