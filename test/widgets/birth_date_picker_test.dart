import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/theme/app_theme.dart';
import 'package:b_link/utils/birthday.dart';
import 'package:b_link/widgets/ui/birth_date_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Ouvre le sélecteur ; [picked] reçoit la date confirmée.
  Future<void> openPicker(WidgetTester tester, ValueChanged<DateTime?> picked,
      {DateTime? initial, bool unknownYear = false}) async {
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => picked(await showBirthDatePicker(context,
                  initial: initial, allowUnknownYear: unknownYear)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Fait tourner la roue [wheel] (0 jour, 1 mois, 2 année) de [items] crans.
  Future<void> spin(WidgetTester tester, int wheel, int items) async {
    await tester.drag(
        find.byType(CupertinoPicker).at(wheel), Offset(0, -44.0 * items));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
  }

  testWidgets('le mois choisi est bien enregistré (22 novembre 2003)',
      (tester) async {
    DateTime? picked;
    await openPicker(tester, (d) => picked = d, initial: DateTime(2003, 1, 1));
    await spin(tester, 0, 21); // 1 -> 22
    await spin(tester, 1, 10); // janvier -> novembre
    expect(find.text('Samedi 22 novembre 2003'), findsOneWidget);
    await confirm(tester);
    expect(picked, DateTime(2003, 11, 22));
  });

  testWidgets('un jour trop grand pour le mois est ramené au dernier jour',
      (tester) async {
    DateTime? picked;
    await openPicker(tester, (d) => picked = d, initial: DateTime(2003, 1, 31));
    await spin(tester, 1, 1); // janvier -> février
    await confirm(tester);
    expect(picked, DateTime(2003, 2, 28));
  });

  testWidgets('année inconnue pour un proche', (tester) async {
    DateTime? picked;
    await openPicker(tester, (d) => picked = d,
        initial: DateTime(unknownBirthYear, 2, 29), unknownYear: true);
    expect(find.text('Année inconnue'), findsOneWidget);
    await confirm(tester);
    expect(picked, DateTime(unknownBirthYear, 2, 29));
  });

  testWidgets('une date future ne peut pas être validée', (tester) async {
    DateTime? picked;
    final now = DateTime.now();
    await openPicker(tester, (d) => picked = d,
        initial: DateTime(now.year, 1, 1));
    // 31 décembre de l'année en cours : dans le futur (sauf le 31/12).
    await spin(tester, 0, 30);
    await spin(tester, 1, 11);
    if (now.month == 12 && now.day == 31) return;
    expect(find.text('Cette date est dans le futur'), findsOneWidget);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });
}
