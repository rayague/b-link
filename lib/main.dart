import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contact_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'screens/contact_detail_screen.dart';
import 'screens/celebration_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_registration_screen.dart';
import 'screens/same_day_screen.dart';
import 'screens/sync_admin_screen.dart';
import 'providers/profile_provider.dart';
import 'services/background_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform as dynamic);
  } catch (_) {
    // If Firebase isn't configured yet (no firebase_options.dart), continue without it.
  }
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
  const _App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final localeProv = Provider.of<LocaleProvider>(context);

    final dodgerBlue = const Color(0xFF1E90FF);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: dodgerBlue, brightness: Brightness.light),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: dodgerBlue, brightness: Brightness.dark),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Birthgram',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProv.mode,
      locale: localeProv.locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [AppLocalizationsDelegate()],
      home: const EntryPointStateful(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/auth': (_) => const AuthScreen(),
        '/': (_) => const HomeScreen(),
  '/same-day': (_) => const SameDayScreen(),
  '/profile-register': (_) => const ProfileRegistrationScreen(),
        '/list': (_) => const ListScreen(),
        '/detail': (_) => const ContactDetailScreen(),
        '/celebration': (_) => const CelebrationScreen(),
        '/sync-admin': (_) => const SyncAdminScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
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
        floatingActionButton: FloatingActionButton(onPressed: () => setState(() => _count++), child: const Icon(Icons.add)),
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
      // if not registered, navigate to onboarding immediately
      if (!auth.isRegistered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        });
        return;
      }
      // start loading contacts (this will import messages)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await contacts.loadContacts();
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
