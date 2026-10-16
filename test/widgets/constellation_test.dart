import 'package:b_link/l10n/app_localizations.dart';
import 'package:b_link/models/user_profile.dart';
import 'package:b_link/providers/profile_provider.dart';
import 'package:b_link/screens/constellation_screen.dart';
import 'package:b_link/services/constellation_service.dart';
import 'package:b_link/theme/app_theme.dart';
import 'package:b_link/widgets/constellation/constellation_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeProfile extends ProfileProvider {
  @override
  UserProfile? get profile => UserProfile(
      uid: 'me', name: 'Ray Ague', givenName: 'Ray', birthDate: DateTime(1996, 3, 21));
}

class _FakeStats extends ConstellationService {
  final ConstellationStats? stats;
  _FakeStats(this.stats);
  @override
  Future<ConstellationStats?> load({bool refresh = false}) async => stats;
}

Future<void> _pump(WidgetTester tester, ConstellationStats? stats,
    {bool reduceMotion = false}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(ChangeNotifierProvider<ProfileProvider>(
    create: (_) => _FakeProfile(),
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
        home: ConstellationScreen(service: _FakeStats(stats)),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('day ring', () {
    test('index of a day key, leap year included', () {
      expect(DayRing.indexOfKey('01-01'), 0);
      expect(DayRing.indexOfKey('02-29'), 59);
      expect(DayRing.indexOfKey('03-01'), 60);
      expect(DayRing.indexOfKey('12-31'), 365);
      expect(DayRing.indexOfKey('02-30'), isNull);
      expect(DayRing.indexOfKey('13-01'), isNull);
      expect(DayRing.indexOfKey('nope'), isNull);
    });

    test('index back to month and day', () {
      for (final key in ['01-01', '02-29', '03-21', '07-14', '12-31']) {
        final (m, d) = DayRing.monthDayOf(DayRing.indexOfKey(key)!);
        expect('${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
            key);
      }
    });

    test('levels: square root scale, all zero stays zero', () {
      expect(normalizeCounts([0, 4, 16]), [0, 0.5, 1]);
      expect(normalizeCounts([0, 0]), [0, 0]);
    });

    test('smoothing wraps around the year', () {
      final v = List<double>.filled(366, 0)..[0] = 7;
      final s = smoothCircular(v);
      expect(s[0], 1);
      expect(s[365], 1); // 31 décembre voit le 1er janvier
      expect(s[4], 0);
    });

    test('a tap on the ring finds its day; the centre finds nothing', () {
      const size = Size(400, 400);
      final top = size.center(Offset.zero) - Offset(0, DayRing.outer(size));
      expect(ConstellationPainter.dayAt(size, top), 0);
      final right = size.center(Offset.zero) + Offset(DayRing.outer(size), 0);
      expect(ConstellationPainter.dayAt(size, right), 92); // ~1er avril
      expect(ConstellationPainter.dayAt(size, size.center(Offset.zero)), isNull);
    });
  });

  final stats = ConstellationStats(
    total: 40,
    days: const {'03-21': 6, '07-14': 9, '12-25': 1},
    firstNames: const [(name: 'Ray', count: 3), (name: 'Léa', count: 5)],
  );

  testWidgets('shows the total, my day and the most celebrated days',
      (tester) async {
    await _pump(tester, stats);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('40'), findsOneWidget);
    expect(find.text('21 mars · votre jour'), findsOneWidget);
    expect(find.text('Les jours les plus fêtés'), findsOneWidget);
    expect(find.text('14 juillet'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('3 membres s\'appellent Ray'), findsOneWidget);
  });

  testWidgets('tapping a star shows its day', (tester) async {
    await _pump(tester, stats);
    await tester.pump(const Duration(seconds: 2));
    final box = tester.getRect(find.byType(AspectRatio));
    // 1er janvier : tout en haut de l'anneau.
    await tester.tapAt(box.center - Offset(0, box.width * 0.30));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 janvier'), findsOneWidget);
    expect(find.text("Aucun membre né ce jour-là pour l'instant"), findsOneWidget);
  });

  testWidgets('reduced motion: drawn at once, nothing keeps animating',
      (tester) async {
    await _pump(tester, stats, reduceMotion: true);
    // Les barres et le nuage de prénoms finissent leur courte apparition.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Plus aucune image programmée : pas d'animation infinie.
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('no statistics yet: a friendly empty state', (tester) async {
    await _pump(tester, null);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('La constellation se prépare'), findsOneWidget);
  });
}
