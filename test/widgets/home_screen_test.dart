import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b_link/providers/theme_provider.dart';

void main() {
  // Note: HomeScreen widget tests that require Firebase (AnalyticsService)
  // are skipped because Firebase.initializeApp() cannot be called in unit tests
  // without a full Firebase emulator setup.

  testWidgets('HomeScreen change de thème', (tester) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: Builder(
          builder: (context) => MaterialApp(
            themeMode: Provider.of<ThemeProvider>(context).mode,
            home: Scaffold(
              body: Center(child: Text('Test')),
            ),
          ),
        ),
      ),
    );

    // Vérifier thème initial est system
    expect(themeProvider.mode, ThemeMode.system);

    // Changer en mode sombre
    themeProvider.toggleTheme();
    await tester.pumpAndSettle();

    expect(themeProvider.mode, ThemeMode.dark);
  });
}
