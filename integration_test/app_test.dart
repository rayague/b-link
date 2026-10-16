// Tests de fumée sur un vrai appareil ou émulateur : ils vérifient ce que les
// tests unitaires ne peuvent pas couvrir (plugins natifs, assets, démarrage).
//
//   flutter test integration_test
//
// Aucun compte n'est nécessaire : sans session, l'app doit s'arrêter sur
// l'onboarding ; avec une session existante, sur l'accueil ou l'inscription.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:b_link/main.dart' as app;
import 'package:b_link/screens/auth_screen.dart';
import 'package:b_link/screens/home_screen.dart';
import 'package:b_link/screens/onboarding_screen.dart';
import 'package:b_link/screens/profile_registration_screen.dart';
import 'package:b_link/services/db_helper.dart';
import 'package:b_link/services/notification_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('message banks are imported into the real SQLite database', () async {
    final db = DBHelper();
    await db.importMessagesIfEmpty();
    for (final lang in ['fr', 'en']) {
      for (final relation in ['FRIEND', 'WIFE', 'MOTHER', 'UNKNOWN']) {
        final msg = await db.getRandomMessageByRelation(relation, lang: lang);
        expect(msg, isNotNull, reason: '$relation/$lang');
        expect(msg!.trim(), isNotEmpty, reason: '$relation/$lang');
      }
    }
  });

  test('notifications initialise without asking for permission', () async {
    await NotificationService().init(requestPermissions: false);
  });

  testWidgets('app starts on a known screen without errors', (tester) async {
    app.main();
    // Pas de pumpAndSettle : la bannière de connectivité et les indicateurs
    // de chargement peuvent animer indéfiniment.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.takeException(), isNull);
    final screens = [
      OnboardingScreen,
      AuthScreen,
      HomeScreen,
      ProfileRegistrationScreen,
    ];
    expect(
      screens.any((t) => find.byType(t).evaluate().isNotEmpty),
      isTrue,
      reason: 'expected one of $screens',
    );
  });
}
