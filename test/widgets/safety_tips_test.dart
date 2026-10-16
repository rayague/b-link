import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/screens/meetups_screen.dart';

void main() {
  for (final lang in ['fr', 'en']) {
    testWidgets('safety tips are shown in $lang (meeting strangers)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: const [Locale('en'), Locale('fr')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: SafetyTipsCard()),
      ));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations(Locale(lang));
      for (final key in [
        'safetyTitle',
        'safetyPublicPlace',
        'safetyTellSomeone',
        'safetyNoAddress',
        'safetyReport',
      ]) {
        expect(find.textContaining(l10n.translate(key)), findsOneWidget,
            reason: key);
      }
    });
  }
}
