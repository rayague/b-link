import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/models/user_profile.dart';
import 'package:b_link/providers/profile_provider.dart';
import 'package:b_link/screens/wishes_screen.dart';
import 'package:b_link/services/wish_service.dart';
import 'package:b_link/theme/app_theme.dart';
import 'package:b_link/widgets/today_twins_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProfile extends ProfileProvider {
  final UserProfile? me;
  _FakeProfile(this.me);
  @override
  UserProfile? get profile => me;
}

class _FakeWishes extends WishService {
  final List<Wish> wishes;
  final sent = <(String, int, String?)>[];
  _FakeWishes([this.wishes = const []]);
  @override
  Future<List<Wish>> received() async => wishes;
  @override
  Future<bool> alreadySent(String toUid) async => false;
  @override
  Future<Set<int>> receivedBy(String toUid) async => {};
  @override
  Future<List<int>> sentRecently() async => const [];
  @override
  Future<void> send(
      {required String toUid, required int wish, String? fromName}) async {
    sent.add((toUid, wish, fromName));
  }
}

Future<void> _pump(WidgetTester tester, Widget child, UserProfile me) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<ProfileProvider>(
    create: (_) => _FakeProfile(me),
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
      home: Scaffold(body: child),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

UserProfile _me({bool public = true}) => UserProfile(
      uid: 'me',
      name: 'Ray Ague',
      givenName: 'Ray',
      birthDate: DateTime(1996, 3, 21),
      isPublic: public,
      publicName: true,
    );

void main() {
  test('a wish document is read with its sender and message', () {
    final w = Wish.fromMap('bob_2026', {
      'fromUid': 'bob',
      'fromName': 'Bob',
      'wish': 3,
    });
    expect(w.fromUid, 'bob');
    expect(w.wish, 3);
    expect(w.createdAt, isNull);
  });

  testWidgets('today\'s twins: hidden when empty', (tester) async {
    await _pump(tester, TodayTwinsSection(loader: () async => const []), _me());
    expect(find.textContaining("aujourd'hui"), findsNothing);
  });

  testWidgets('today\'s twins: shows first names and opens the wish sheet',
      (tester) async {
    await _pump(
      tester,
      SingleChildScrollView(
        child: TodayTwinsSection(
          loader: () async => const [
            (uid: 'a', name: 'Léa Bernard', showPhoto: false),
            (uid: 'b', name: '', showPhoto: false),
          ],
        ),
      ),
      _me(),
    );
    await tester.pumpAndSettle();
    expect(find.text("Ils fêtent leur anniversaire aujourd'hui (2)"),
        findsOneWidget);
    expect(find.text('Léa'), findsOneWidget);
    expect(find.text('Profil anonyme'), findsOneWidget);

    await tester.tap(find.text('Léa'));
    await tester.pumpAndSettle();
    expect(find.text('Souhaiter un joyeux anniversaire à Léa'), findsOneWidget);
    expect(find.text('Envoyer un vœu'), findsOneWidget);
  });

  testWidgets('a private profile is asked to go public before sending',
      (tester) async {
    await _pump(
      tester,
      TodayTwinsSection(
        loader: () async => const [(uid: 'a', name: 'Léa', showPhoto: false)],
      ),
      _me(public: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Léa'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rendez votre profil public'), findsOneWidget);
    expect(find.text('Envoyer un vœu'), findsNothing);
  });

  testWidgets('the wall shows each wish in the reader\'s language',
      (tester) async {
    final service = _FakeWishes([
      Wish(id: '1', fromUid: 'bob', fromName: 'Bob', wish: 12, createdAt: DateTime(2026, 3, 21, 9)),
      const Wish(id: '2', fromUid: 'x', wish: 1),
    ]);
    await _pump(tester, WishesScreen(service: service), _me());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2 vœux reçus'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.textContaining("Que la chance t'accompagne"), findsOneWidget);
    expect(find.text("Un jumeau d'anniversaire"), findsOneWidget);
  });

  group('which wishes are offered', () {
    test('never a message the person already received, if possible', () {
      final order = WishService.proposals(
          receivedByThem: {0, 1, 2, 3}, sentRecently: const [], seed: 1);
      expect(order, hasLength(WishService.count - 4));
      expect(order.toSet().intersection({0, 1, 2, 3}), isEmpty);
      expect(order.toSet().length, order.length); // aucun doublon
    });

    test('messages I sent recently come last', () {
      final order = WishService.proposals(
          receivedByThem: const {}, sentRecently: const [5, 6], seed: 2);
      expect(order.sublist(order.length - 2).toSet(), {5, 6});
    });

    test('when everything was received, all messages are offered again', () {
      final order = WishService.proposals(
          receivedByThem: {for (var i = 0; i < WishService.count; i++) i},
          sentRecently: const [],
          seed: 3);
      expect(order.toSet().length, WishService.count);
    });

    test('every message exists in both languages, with emojis', () {
      final emoji = RegExp(r'[🌀-🫿☀-➿]', unicode: true);
      for (final lang in ['fr', 'en']) {
        final l10n = AppLocalizations(Locale(lang));
        final texts = <String>{};
        for (var i = 0; i < WishService.count; i++) {
          final s = l10n.translate('wish_$i');
          expect(s, isNot('wish_$i'));
          expect(s.length, greaterThan(70), reason: 'wish_$i ($lang)');
          expect(emoji.hasMatch(s), isTrue, reason: 'wish_$i ($lang)');
          texts.add(s);
        }
        expect(texts.length, WishService.count); // tous différents
      }
    });
  });
}
