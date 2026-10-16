import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/models/contact.dart';
import 'package:b_link/models/user_profile.dart';
import 'package:b_link/providers/contact_provider.dart';
import 'package:b_link/providers/locale_provider.dart';
import 'package:b_link/providers/profile_provider.dart';
import 'package:b_link/providers/theme_provider.dart';
import 'package:b_link/screens/home_screen.dart';
import 'package:b_link/screens/import_contacts_screen.dart';
import 'package:b_link/screens/list_screen.dart';
import 'package:b_link/services/phone_contacts_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart' show PermissionStatus;
import 'package:b_link/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDb {
  final List<Contact> rows;
  _FakeDb(this.rows);
  Future<List<Contact>> getContacts() async => List.of(rows);
  Future<int> insertContact(Contact c) async {
    rows.add(c.copyWith(id: rows.length + 100));
    return rows.length + 99;
  }
}

class _FakePhone extends PhoneContactsService {
  final PermissionStatus status;
  _FakePhone(this.status);
  @override
  Future<PermissionStatus> requestRead() async => status;
  @override
  Future<List<PhoneContact>> load() async => [
        PhoneContact(id: 'a', name: 'Léa', birthday: DateTime(1995, 3, 21)),
        const PhoneContact(id: 'b', name: 'Noah'),
        PhoneContact(id: 'c', name: 'Hugo', birthday: DateTime(1990, 1, 2)),
      ];
}

class _FakeNotif {
  Future<void> init() async {}
  Future<void> rescheduleAllReminders(List<Contact> c, String l) async {}
  Future<void> scheduleBirthdayReminders(dynamic c, String l) async {}
}

class _FakeProfile extends ProfileProvider {
  final UserProfile? me;
  _FakeProfile(this.me);
  @override
  UserProfile? get profile => me;
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Né il y a [age] ans, anniversaire dans [days] jours.
String _birth(int days, int age) {
  final d = DateTime.now().add(Duration(days: days));
  return _iso(DateTime(d.year - age, d.month, d.day));
}

Future<void> _pump(WidgetTester tester, Widget screen, List<Contact> contacts,
    {UserProfile? me}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final provider = ContactProvider.test(db: _FakeDb(contacts), notif: _FakeNotif());
  await provider.loadContacts();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider<ContactProvider>.value(value: provider),
      ChangeNotifierProvider<ProfileProvider>(create: (_) => _FakeProfile(me)),
    ],
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
      home: screen,
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final me = UserProfile(
      uid: 'me', name: 'Ray Ague', givenName: 'Ray', birthDate: DateTime(1996, 3, 21));

  testWidgets('home puts today\'s birthday first with its age', (tester) async {
    await _pump(
      tester,
      const HomeScreen(),
      [
        Contact(id: 1, name: 'Hugo', date: _birth(3, 34), relation: 'BROTHER'),
        Contact(id: 2, name: 'Camille', date: _birth(0, 29), relation: 'FRIEND'),
      ],
      me: me,
    );
    expect(find.text('Bonjour, Ray'), findsOneWidget);
    expect(find.text('Camille'), findsOneWidget);
    expect(find.text("Fête ses 29 ans aujourd'hui"), findsOneWidget);
    expect(find.text('Écrire un message'), findsOneWidget);
    // Hugo est dans « À venir », avec son compte à rebours.
    expect(find.text('Hugo'), findsOneWidget);
    expect(find.text('Dans 3 j'), findsOneWidget);
  });

  testWidgets('home shows the next birthday when none is today',
      (tester) async {
    await _pump(
      tester,
      const HomeScreen(),
      [Contact(id: 1, name: 'Léa', date: _birth(12, 27), relation: 'FRIEND')],
      me: me,
    );
    expect(find.text('PROCHAIN ANNIVERSAIRE'), findsOneWidget);
    expect(find.text('Léa'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // Pas de section « À venir » vide sous la carte.
    expect(find.text('À venir'), findsNothing);
  });

  testWidgets('contact list is sorted by next birthday and searchable',
      (tester) async {
    await _pump(tester, const ListScreen(), [
      Contact(id: 1, name: 'Zoé', date: _birth(40, 20), relation: 'FRIEND'),
      Contact(id: 2, name: 'Adam', date: _birth(2, 30), relation: 'BROTHER'),
      Contact(id: 3, name: 'Maman', date: _birth(0, 58), relation: 'MOTHER'),
    ]);
    final names = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((s) => s == 'Zoé' || s == 'Adam' || s == 'Maman')
        .toList();
    expect(names, ['Maman', 'Adam', 'Zoé']);
    expect(find.text("Aujourd'hui"), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'frère');
    await tester.pump();
    expect(find.text('Adam'), findsOneWidget);
    expect(find.text('Zoé'), findsNothing);
  });

  testWidgets('import preselects contacts with a birthday and skips known ones',
      (tester) async {
    final contacts = [
      Contact(id: 1, name: 'Hugo', date: '1990-01-02', relation: 'BROTHER'),
    ];
    await _pump(tester,
        ImportContactsScreen(service: _FakePhone(PermissionStatus.granted)),
        contacts);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Léa'), findsOneWidget);
    expect(find.text('Noah'), findsOneWidget);
    expect(find.text('Hugo'), findsNothing); // déjà dans B-Link
    expect(find.text('Importer (1)'), findsOneWidget);
    await tester.tap(find.text('Importer (1)'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(contacts.map((c) => c.name), containsAll(['Hugo', 'Léa']));
    expect(contacts.length, 2); // Noah, sans date, n'est pas importé
  });

  testWidgets('import explains a refused permission', (tester) async {
    await _pump(tester,
        ImportContactsScreen(service: _FakePhone(PermissionStatus.denied)), []);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Autoriser l'accès"), findsOneWidget);
  });
}
