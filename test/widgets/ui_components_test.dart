import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/models/contact.dart';
import 'package:b_link/theme/app_theme.dart';
import 'package:b_link/utils/birthday_labels.dart';
import 'package:b_link/widgets/contact_form.dart';
import 'package:b_link/widgets/ui/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('InitialsAvatar', () {
    test('same name, same colour; independent of case and spaces', () {
      expect(InitialsAvatar.hueFor('Camille'), InitialsAvatar.hueFor(' camille '));
      expect(InitialsAvatar.hueFor('Camille'),
          isNot(InitialsAvatar.hueFor('Hugo')));
    });

    test('initial handles empty and accented names', () {
      expect(InitialsAvatar.initialOf(''), '?');
      expect(InitialsAvatar.initialOf('  élodie'), 'É');
    });
  });

  group('birthday labels', () {
    final fr = AppLocalizations(const Locale('fr'));
    final en = AppLocalizations(const Locale('en'));

    test('countdown', () {
      expect(countdownLabel(fr, 0), "Aujourd'hui");
      expect(countdownLabel(fr, 1), 'Demain');
      expect(countdownLabel(fr, 12), 'Dans 12 j');
      expect(countdownLabel(en, 12), 'In 12 d');
    });

    test('age at next birthday', () {
      final now = DateTime(2026, 10, 16);
      expect(ageAtNextBirthday(DateTime(1996, 10, 16), now), 30);
      expect(ageAtNextBirthday(DateTime(1996, 10, 15), now), 31);
      expect(ageAtNextBirthday(DateTime(2026, 10, 16), now), isNull);
    });
  });

  testWidgets('contact form requires a name and a birth date',
      (tester) async {
    Contact? saved;
    await tester.pumpWidget(_app(ContactForm(
      submitLabel: 'OK',
      onSubmit: (c) async => saved = c,
    )));
    await tester.pumpAndSettle(); // chargement des traductions

    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(saved, isNull);
    expect(find.text('Veuillez entrer un nom'), findsOneWidget);
    expect(find.text('Veuillez sélectionner une date'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '  Léa Bernard ');
    await tester.tap(find.text('Sélectionner une date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer')); // valide les roues
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, 'Léa Bernard');
    expect(saved!.relation, 'FRIEND');
    expect(saved!.phone, isNull);
    final now = DateTime.now();
    // Sans date initiale, les roues partent du 1er janvier, 25 ans plus tôt.
    expect(saved!.date, '${now.year - 25}-01-01');
  });

  testWidgets('contact form keeps an old lowercase relation', (tester) async {
    Contact? saved;
    await tester.pumpWidget(_app(ContactForm(
      initial: Contact(id: 7, uuid: 'u', name: 'Bob', date: '1990-05-01', relation: 'mother'),
      submitLabel: 'OK',
      onSubmit: (c) async => saved = c,
    )));
    await tester.pumpAndSettle(); // chargement des traductions
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(saved!.relation, 'MOTHER');
    expect(saved!.id, 7);
    expect(saved!.uuid, 'u');
  });
}
