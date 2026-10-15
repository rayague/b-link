import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:country_picker/country_picker.dart';
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
import 'services/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'screens/contact_detail_screen.dart';
import 'screens/celebration_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_registration_screen.dart';
import 'screens/same_day_screen.dart';
import 'screens/zodiac_screen.dart';
// import 'screens/public_profile_screen.dart'; // Unused
import 'providers/profile_provider.dart';
import 'services/background_sync.dart';
import 'widgets/consent_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform as dynamic);
  } catch (_) {
    // If Firebase isn't configured yet (no firebase_options.dart), continue without it.
  }

  // Connectivité (bannière hors ligne). La synchro est gérée par Firestore.
  ConnectivityService().initialize();
  // RGPD : applique le choix enregistré avant tout événement analytics.
  await AnalyticsService().loadConsent();

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
        // Noms de pays traduits (sélecteur de pays de résidence).
        CountryLocalizations.delegate,
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
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        ZodiacScreen.routeName: (_) => const ZodiacScreen(),
      },
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
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      // rappels : rafraîchissement quotidien en arrière-plan (best-effort)
      initializeBackgroundReminders();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Si l'utilisateur n'est pas connecté (Firebase), on va à l'onboarding
      if (!auth.isRegistered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        });
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    }
  }

  /// Charge le profil ; sans date de naissance l'app n'a pas de sens, donc on
  /// envoie vers l'inscription du profil avant d'afficher l'accueil.
  Future<void> _bootstrap() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final contacts = Provider.of<ContactProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);

    final reliable = await profile.load();
    if (!mounted) return;
    if (profile.profile == null && reliable) {
      Navigator.of(context).pushReplacementNamed('/profile-register');
      return;
    }
    setState(() => _ready = true);
    // RGPD : demander le consentement aux statistiques (une seule fois).
    await askAnalyticsConsentIfNeeded(context);
    if (!mounted) return;
    // start loading contacts (this will import messages)
    await contacts.loadContacts(locale: locale.locale.languageCode);

    // Toucher un rappel ouvre la fiche du contact (app ouverte ou lancée
    // depuis la notification).
    final notifications = NotificationService();
    _tapSub ??= notifications.contactTaps.listen(_openContact);
    final launchId = notifications.takeLaunchContactId();
    if (launchId != null) _openContact(launchId);
  }

  StreamSubscription<int>? _tapSub;

  void _openContact(int contactId) {
    if (!mounted) return;
    final contact =
        Provider.of<ContactProvider>(context, listen: false).byId(contactId);
    if (contact == null) return;
    Navigator.of(context).pushNamed('/detail', arguments: contact);
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
