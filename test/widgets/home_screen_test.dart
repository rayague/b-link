import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b_link/screens/home_screen.dart';
import 'package:b_link/providers/theme_provider.dart';
import 'package:b_link/providers/locale_provider.dart';
import 'package:b_link/providers/contact_provider.dart';
import 'package:b_link/services/db_helper.dart';

void main() {
  testWidgets('HomeScreen affiche les statistiques', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(
            create: (_) => ContactProvider(
              db: DBHelper(),
              notif: null,
            ),
          ),
        ],
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Vérifier que les stats sont affichées
    expect(find.text('Contacts'), findsWidgets);
    expect(find.byType(Card), findsWidgets);
  });

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

    // Vérifier thème clair initial
    expect(themeProvider.mode, ThemeMode.light);

    // Changer en mode sombre
    themeProvider.toggleTheme();
    await tester.pumpAndSettle();

    expect(themeProvider.mode, ThemeMode.dark);
  });

  testWidgets('HomeScreen affiche le titre', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(
            create: (_) => ContactProvider(
              db: DBHelper(),
              notif: null,
            ),
          ),
        ],
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Vérifier la présence d'éléments d'interface
    expect(find.byType(AppBar), findsOneWidget);
  });
}
