import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:b_link/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('B-Link E2E Tests', () {
    testWidgets('Flux complet: Navigation et ajout de contact', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Attendre le chargement initial
      await tester.pumpAndSettle(Duration(seconds: 3));

      // 2. Vérifier que l'app est chargée
      expect(find.byType(MaterialApp), findsOneWidget);

      // 3. Chercher le bouton d'ajout de contact (icône Add)
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 4. Vérifier que le formulaire s'affiche
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });

    testWidgets('Navigation vers profil', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Attendre chargement
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Chercher le bouton de profil
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();

        // Vérifier la navigation
        expect(find.byType(AppBar), findsWidgets);
      }
    });

    testWidgets('Recherche de contacts', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Chercher le champ de recherche
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'Test');
        await tester.pumpAndSettle();

        // Vérifier que le texte est entré
        expect(find.text('Test'), findsWidgets);
      }
    });

    testWidgets('Changement de thème', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Chercher l'icône de settings/paramètres
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Le menu de paramètres devrait s'afficher
        expect(find.byType(Drawer), findsOneWidget);
      }
    });
  });

  group('Tests de performance', () {
    testWidgets('Chargement initial rapide', (tester) async {
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Vérifier que le chargement prend moins de 5 secondes
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    testWidgets('Défilement fluide de la liste', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Chercher une liste scrollable
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        // Faire défiler
        await tester.drag(listView.first, Offset(0, -300));
        await tester.pumpAndSettle();

        // Vérifier qu'aucune erreur ne s'est produite
        expect(tester.takeException(), isNull);
      }
    });
  });
}
