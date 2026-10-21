import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/screens/onboarding_screen.dart';
import 'package:b_link/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Les scènes tournent en boucle : pas de pumpAndSettle.
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  testWidgets('the four pages lead to sign-in', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const OnboardingScreen(),
      routes: {'/auth': (_) => const Scaffold(body: Text('auth'))},
    ));
    await frames(tester);
    for (final title in [
      "N'oubliez plus aucun anniversaire",
      "Rencontrez vos jumeaux d'anniversaire",
      'Des mots qui touchent',
    ]) {
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.text('Suivant'));
      await frames(tester);
    }
    expect(find.text('Votre jour, votre ciel'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await frames(tester);
    expect(find.text('auth'), findsOneWidget);
  });

  testWidgets('animations stop when the device asks for less motion',
      (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('en'), Locale('fr')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const OnboardingScreen(),
      ),
    ));
    await tester.pumpAndSettle(); // ne bloque pas : rien ne tourne
    expect(find.text("N'oubliez plus aucun anniversaire"), findsOneWidget);
  });
}
