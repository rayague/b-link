import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contact_provider.dart';
import 'services/analytics_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_queue_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'screens/contact_detail_screen.dart';
import 'screens/celebration_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_registration_screen.dart';
import 'screens/same_day_screen.dart';
// import 'screens/sync_admin_screen.dart'; // Déprécié - Utiliser AdminStatsScreen
import 'screens/zodiac_screen.dart';
// import 'screens/public_profile_screen.dart'; // Unused
import 'providers/profile_provider.dart';
import 'services/background_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform as dynamic);
  } catch (_) {
    // If Firebase isn't configured yet (no firebase_options.dart), continue without it.
  }
  
  // Initialiser les services de connectivité et synchronisation
  ConnectivityService().initialize();
  SyncQueueService().initialize();
  
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const _App(),
    );
  }
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);

    final dodgerBlue = const Color(0xFF1E90FF);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
          seedColor: dodgerBlue, brightness: Brightness.light),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
          seedColor: dodgerBlue, brightness: Brightness.dark),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'B-Link',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProv.mode,
      locale: localeProv.locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [
        AnalyticsService().getAnalyticsObserver(), // Analytics tracking
      ],
      home: const EntryPointStateful(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/auth': (_) => const AuthScreen(),
        '/same-day': (_) => const SameDayScreen(),
        '/profile-register': (_) => const ProfileRegistrationScreen(),
        '/list': (_) => const ListScreen(),
        '/detail': (_) => const ContactDetailScreen(),
        '/celebration': (_) => const CelebrationScreen(),
        // '/sync-admin': Déprécié - Utiliser AdminStatsScreen via ProfileScreen
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        ZodiacScreen.routeName: (_) => const ZodiacScreen(),
      },
    );
  }
}

// Minimal MyApp used by widget tests (simple counter)
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _count = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: Center(child: Text('$_count')),
        floatingActionButton: FloatingActionButton(
            onPressed: () => setState(() => _count++),
            child: const Icon(Icons.add)),
      ),
    );
  }
}

class EntryPointStateful extends StatefulWidget {
  const EntryPointStateful({super.key});

  @override
  State<EntryPointStateful> createState() => _EntryPointStatefulState();
}

class _EntryPointStatefulState extends State<EntryPointStateful> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      // initialize background sync (best-effort)
      initializeBackgroundSync();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final contacts = Provider.of<ContactProvider>(context, listen: false);
      final locale = Provider.of<LocaleProvider>(context, listen: false);
      // Si l'utilisateur n'est pas connecté (Firebase), on va à l'onboarding
      if (!auth.isRegistered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        });
        return;
      }
      // start loading contacts (this will import messages)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await contacts.loadContacts(locale: locale.locale.languageCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = Provider.of<ContactProvider>(context);
    return Stack(
      children: [
        const HomeScreen(),
        if (contacts.loading)
          Container(
            color: Colors.black38,
            child: const Center(child: CircularProgressIndicator()),
          )
      ],
    );
  }
}
