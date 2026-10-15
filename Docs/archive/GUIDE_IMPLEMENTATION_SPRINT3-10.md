# 🚀 GUIDE D'IMPLÉMENTATION - Sprint 3 à 10

**Objectif**: Implémenter toutes les fonctionnalités jusqu'à (mais excluant) l'Internationalisation

---

## ✅ ÉTAPE 1: Firebase Analytics (FAIT)

### Fichiers créés:
- ✅ `lib/services/analytics_service.dart` - Service centralisé
- ✅ `lib/main.dart` - NavigatorObserver ajouté
- ✅ `lib/screens/home_screen.dart` - Tracking ajouté

### Prochaines étapes Analytics:
Ajouter le tracking dans TOUS les écrans suivants:

```dart
// Template à copier dans chaque écran
@override
void initState() {
  super.initState();
  AnalyticsService().logScreenView(
    screenName: 'SCREEN_NAME',
    screenClass: 'SCREEN_NAME',
  );
}
```

**Liste des écrans à tracker:**
- [ ] `lib/screens/profile_screen.dart`
- [ ] `lib/screens/contacts_screen.dart` (ou list_screen.dart)
- [ ] `lib/screens/contact_detail_screen.dart`
- [ ] `lib/screens/celebration_screen.dart`
- [ ] `lib/screens/same_day_screen.dart`
- [ ] `lib/screens/zodiac_screen.dart`
- [ ] `lib/screens/public_profile_screen.dart`
- [ ] `lib/screens/admin_stats_screen.dart`
- [ ] `lib/screens/auth_screen.dart`
- [ ] `lib/screens/onboarding_screen.dart`

**Événements à tracker:**
```dart
// Dans ContactProvider.addContact()
AnalyticsService().logContactAdded(
  relation: contact.relation,
  hasPhone: contact.phone != null,
);

// Dans ProfileProvider.save()
AnalyticsService().logProfileUpdated(
  hasPhoto: profile.photo != null,
  isPublic: profile.isPublic,
);

// Dans CelebrationScreen._generateMessage()
AnalyticsService().logBirthdayMessageGenerated(
  relation: contact.relation,
  messageLength: message.length,
);

// Dans CelebrationScreen._makeCall()
AnalyticsService().logCallInitiated(
  relation: contact.relation,
  hasPhone: contact.phone != null,
);
```

---

## 📋 ÉTAPE 2: Tests Supplémentaires

### 2.1 Tests de Widgets

Créer ces fichiers:

#### `test/widgets/home_screen_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b_link/screens/home_screen.dart';
import 'package:b_link/providers/theme_provider.dart';
import 'package:b_link/providers/locale_provider.dart';
import 'package:b_link/providers/contact_provider.dart';

void main() {
  testWidgets('HomeScreen affiche les statistiques', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ContactProvider()),
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
            home: HomeScreen(),
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
}
```

#### `test/widgets/contact_card_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:b_link/models/contact.dart';
import 'package:b_link/widgets/contact_card.dart'; // Si existe

void main() {
  testWidgets('ContactCard affiche les informations', (tester) async {
    final contact = Contact(
      id: 1,
      name: 'Alice Dupont',
      date: '1995-03-15',
      relation: 'FRIEND',
      phone: '0612345678',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContactCard(contact: contact),
        ),
      ),
    );

    expect(find.text('Alice Dupont'), findsOneWidget);
    expect(find.text('FRIEND'), findsOneWidget);
  });
}
```

### 2.2 Tests d'Intégration

#### `integration_test/app_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:b_link/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('B-Link E2E Tests', () {
    testWidgets('Flux complet ajout contact', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Attendre chargement
      await tester.pumpAndSettle(Duration(seconds: 2));

      // 2. Naviguer vers contacts
      final contactsButton = find.byIcon(Icons.contacts);
      if (contactsButton.evaluate().isNotEmpty) {
        await tester.tap(contactsButton);
        await tester.pumpAndSettle();
      }

      // 3. Cliquer sur ajouter
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 4. Remplir formulaire
        await tester.enterText(
          find.byKey(Key('contact_name')),
          'Test Contact',
        );
        await tester.pumpAndSettle();

        // 5. Sauvegarder
        final saveButton = find.text('Sauvegarder');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          // 6. Vérifier succès
          expect(find.text('Test Contact'), findsWidgets);
        }
      }
    });
  });
}
```

Pour lancer: `flutter test integration_test/app_test.dart`

### 2.3 Ajouter dépendances
```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  fake_cloud_firestore: ^2.4.1+1
  firebase_auth_mocks: ^0.13.0
```

---

## 🌐 ÉTAPE 3: Mode Hors Ligne Complet

### 3.1 Ajouter dépendance
```yaml
# pubspec.yaml
dependencies:
  connectivity_plus: ^5.0.2
```

### 3.2 Créer ConnectivityService

#### `lib/services/connectivity_service.dart`
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void initialize() {
    _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      _connectionController.add(isConnected);
      print('🌐 Connectivity changed: $isConnected');
    });
  }

  void dispose() {
    _connectionController.close();
  }
}
```

### 3.3 Créer OfflineBanner Widget

#### `lib/widgets/offline_banner.dart`
```dart
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().onConnectivityChanged,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.orange[700],
          child: Row(
            children: const [
              Icon(Icons.cloud_off, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mode hors ligne - Vos modifications seront synchronisées',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 3.4 Ajouter au layout principal
```dart
// Dans home_screen.dart ou main layout
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        OfflineBanner(), // Ajouter ici
        Expanded(
          child: // ... votre contenu
        ),
      ],
    ),
  );
}
```

### 3.5 Queue de Synchronisation

#### `lib/services/sync_queue_service.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';
import 'connectivity_service.dart';

class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final DBHelper _db = DBHelper();
  final ConnectivityService _connectivity = ConnectivityService();

  Future<void> initialize() async {
    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        processSyncQueue();
      }
    });
  }

  Future<void> addToQueue(Map<String, dynamic> operation) async {
    final db = await _db.database;
    await db.insert('sync_queue', {
      'action': operation['action'],
      'data': operation['data'],
      'status': 'pending',
      'attempts': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    print('📤 Ajouté à la queue de sync: ${operation['action']}');
  }

  Future<void> processSyncQueue() async {
    if (!await _connectivity.isConnected()) {
      print('⚠️ Pas de connexion, sync annulée');
      return;
    }

    final db = await _db.database;
    final items = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );

    print('📥 Processing ${items.length} sync items');

    for (final item in items) {
      try {
        await _processItem(item);
        
        // Supprimer de la queue
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [item['id']]);
        print('✅ Sync réussie: ${item['action']}');
      } catch (e) {
        print('❌ Erreur sync: $e');
        
        // Incrémenter attempts
        await db.update(
          'sync_queue',
          {
            'attempts': (item['attempts'] as int) + 1,
            'lastError': e.toString(),
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }
    }
  }

  Future<void> _processItem(Map<String, dynamic> item) async {
    final action = item['action'] as String;
    final data = item['data'] as String; // JSON string

    switch (action) {
      case 'add_contact':
        // Envoyer à Firestore
        await FirebaseFirestore.instance.collection('contacts').add(data);
        break;
      
      case 'update_profile':
        // Mettre à jour profil
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(item['userId'])
            .update(data);
        break;
      
      // Ajouter autres actions...
    }
  }
}
```

### 3.6 Intégrer dans main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialiser services
  ConnectivityService().initialize();
  SyncQueueService().initialize();
  
  runApp(const RootApp());
}
```

---

## 📱 ÉTAPE 4: Collapse AppBar Autres Écrans

### 4.1 ContactDetailScreen

```dart
// lib/screens/contact_detail_screen.dart
SliverAppBar(
  expandedHeight: 200,
  floating: false,
  pinned: true,
  flexibleSpace: LayoutBuilder(
    builder: (context, constraints) {
      final isCollapsed = constraints.maxHeight <= kToolbarHeight + 50;
      
      return Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient (disparaît quand collapsé)
          if (!isCollapsed)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
            ),
          
          // Photo contact (change de taille)
          Positioned(
            bottom: isCollapsed ? 8 : 16,
            left: isCollapsed ? 12 : 20,
            child: Hero(
              tag: 'contact_${contact.id}',
              child: CircleAvatar(
                radius: isCollapsed ? 20 : 40,
                child: Text(contact.name[0]),
              ),
            ),
          ),
          
          // Nom (change de position et taille)
          Positioned(
            bottom: isCollapsed ? 12 : 20,
            left: isCollapsed ? 60 : 80,
            child: Text(
              contact.name,
              style: TextStyle(
                fontSize: isCollapsed ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  ),
)
```

### 4.2 ZodiacScreen

```dart
// lib/screens/zodiac_screen.dart
SliverAppBar(
  expandedHeight: 250,
  floating: false,
  pinned: true,
  flexibleSpace: LayoutBuilder(
    builder: (context, constraints) {
      final isCollapsed = constraints.maxHeight <= kToolbarHeight + 50;
      
      return Stack(
        fit: StackFit.expand,
        children: [
          // Étoiles en background (disparaissent)
          if (!isCollapsed)
            ...List.generate(20, (i) {
              final random = Random(i);
              return Positioned(
                left: random.nextDouble() * 400,
                top: random.nextDouble() * 250,
                child: Opacity(
                  opacity: isCollapsed ? 0 : 0.3,
                  child: Icon(
                    Icons.star,
                    size: 10 + random.nextDouble() * 15,
                    color: Colors.white,
                  ),
                ),
              );
            }),
          
          // Symbole zodiac (rétrécit)
          Center(
            child: Text(
              '♈', // Ou autre symbole
              style: TextStyle(
                fontSize: isCollapsed ? 30 : 80,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  ),
)
```

### 4.3 SameDayScreen

Similar approach avec les décorations circulaires.

---

## 🎨 ÉTAPE 5: Personnalisation Thèmes

### 5.1 Créer les thèmes

#### `lib/theme/app_themes.dart`
```dart
import 'package:flutter/material.dart';

enum AppTheme {
  purple,
  blue,
  green,
  orange,
  pink,
  red,
}

class AppThemes {
  static final Map<AppTheme, ThemeData> lightThemes = {
    AppTheme.purple: _buildTheme(Colors.purple, Brightness.light),
    AppTheme.blue: _buildTheme(Colors.blue, Brightness.light),
    AppTheme.green: _buildTheme(Colors.green, Brightness.light),
    AppTheme.orange: _buildTheme(Colors.orange, Brightness.light),
    AppTheme.pink: _buildTheme(Colors.pink, Brightness.light),
    AppTheme.red: _buildTheme(Colors.red, Brightness.light),
  };

  static final Map<AppTheme, ThemeData> darkThemes = {
    AppTheme.purple: _buildTheme(Colors.purple, Brightness.dark),
    AppTheme.blue: _buildTheme(Colors.blue, Brightness.dark),
    AppTheme.green: _buildTheme(Colors.green, Brightness.dark),
    AppTheme.orange: _buildTheme(Colors.orange, Brightness.dark),
    AppTheme.pink: _buildTheme(Colors.pink, Brightness.dark),
    AppTheme.red: _buildTheme(Colors.red, Brightness.dark),
  };

  static ThemeData _buildTheme(Color color, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }
}
```

### 5.2 Modifier ThemeProvider

```dart
// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  AppTheme _currentTheme = AppTheme.purple;

  ThemeMode get mode => _mode;
  AppTheme get currentTheme => _currentTheme;

  ThemeData get lightTheme => AppThemes.lightThemes[_currentTheme]!;
  ThemeData get darkTheme => AppThemes.darkThemes[_currentTheme]!;

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme.toString());
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('app_theme');
    if (themeName != null) {
      _currentTheme = AppTheme.values.firstWhere(
        (t) => t.toString() == themeName,
        orElse: () => AppTheme.purple,
      );
      notifyListeners();
    }
  }

  void toggleTheme() {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
```

### 5.3 Créer écran de sélection

#### `lib/screens/theme_settings_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un thème')),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeTile(
            theme: AppTheme.purple,
            name: 'Violet',
            color: Colors.purple,
            isSelected: themeProvider.currentTheme == AppTheme.purple,
          ),
          _ThemeTile(
            theme: AppTheme.blue,
            name: 'Bleu',
            color: Colors.blue,
            isSelected: themeProvider.currentTheme == AppTheme.blue,
          ),
          _ThemeTile(
            theme: AppTheme.green,
            name: 'Vert',
            color: Colors.green,
            isSelected: themeProvider.currentTheme == AppTheme.green,
          ),
          _ThemeTile(
            theme: AppTheme.orange,
            name: 'Orange',
            color: Colors.orange,
            isSelected: themeProvider.currentTheme == AppTheme.orange,
          ),
          _ThemeTile(
            theme: AppTheme.pink,
            name: 'Rose',
            color: Colors.pink,
            isSelected: themeProvider.currentTheme == AppTheme.pink,
          ),
          _ThemeTile(
            theme: AppTheme.red,
            name: 'Rouge',
            color: Colors.red,
            isSelected: themeProvider.currentTheme == AppTheme.red,
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppTheme theme;
  final String name;
  final Color color;
  final bool isSelected;

  const _ThemeTile({
    required this.theme,
    required this.name,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Provider.of<ThemeProvider>(context, listen: false).setTheme(theme);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
```

---

## ⚡ ÉTAPE 6: Optimisation Performances

### 6.1 Images optimisées

```dart
// Remplacer Image.network par:
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 200,
  memCacheHeight: 200,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)

// Ajouter dépendance
dependencies:
  cached_network_image: ^3.3.0
```

### 6.2 ListView optimisé

```dart
// Avant
ListView(
  children: contacts.map((c) => ContactCard(c)).toList(),
)

// Après
ListView.builder(
  itemCount: contacts.length,
  addAutomaticKeepAlives: false,
  addRepaintBoundaries: false,
  cacheExtent: 100,
  itemBuilder: (context, index) => ContactCard(contacts[index]),
)
```

### 6.3 Pagination

```dart
class ContactsScreenState extends State<ContactsScreen> {
  static const int PAGE_SIZE = 50;
  int _currentPage = 1;
  List<Contact> _displayedContacts = [];

  void _loadMore() {
    setState(() {
      _currentPage++;
      _displayedContacts = allContacts.take(_currentPage * PAGE_SIZE).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _displayedContacts.length,
        itemBuilder: (context, index) => ContactCard(_displayedContacts[index]),
      ),
    );
  }
}
```

---

## 💬 ÉTAPE 7: Messagerie In-App

### 7.1 Structure Firestore

Créer ces collections manuellement dans Firebase Console:
```
/chats/
  {chatId}/
    - participants: [user1_id, user2_id]
    - lastMessage: "..."
    - lastMessageTime: timestamp
    - unreadCount: {user1_id: 2, user2_id: 0}
    
    /messages/
      {messageId}/
        - senderId: user_id
        - text: "..."
        - timestamp: timestamp
        - read: false
```

### 7.2 Créer ChatService

Voir code détaillé dans `lib/services/chat_service.dart` (à créer)

### 7.3 Créer ChatsScreen

Voir code détaillé dans `lib/screens/chats_screen.dart` (à créer)

### 7.4 Créer ChatDetailScreen

Voir code détaillé dans `lib/screens/chat_detail_screen.dart` (à créer)

---

## 🔔 ÉTAPE 8: Notifications Push Avancées

### 8.1 Setup Firebase Cloud Functions

```bash
cd functions
npm install firebase-functions firebase-admin
```

### 8.2 Créer fonction

Voir code détaillé dans `functions/index.js`

### 8.3 Déployer

```bash
firebase deploy --only functions
```

---

## ✅ CHECKLIST FINALE

- [ ] Analytics tracking dans 10+ écrans
- [ ] Événements trackés (contact add/update/delete, messages, calls)
- [ ] 5+ tests de widgets créés
- [ ] 1+ test d'intégration E2E
- [ ] ConnectivityService implémenté
- [ ] OfflineBanner affiché
- [ ] SyncQueue fonctionnel
- [ ] Collapse ContactDetail, Zodiac, SameDay
- [ ] 6 thèmes disponibles
- [ ] ThemeSettingsScreen créé
- [ ] Images CachedNetworkImage
- [ ] ListView.builder partout
- [ ] Pagination contacts
- [ ] ChatService créé
- [ ] ChatsScreen créé
- [ ] ChatDetailScreen créé
- [ ] Cloud Function notifications déployée

---

**Estimation totale**: 68-91 heures
**Fichiers à créer**: ~20
**Fichiers à modifier**: ~15

C'est un très gros projet! Veux-tu que je continue l'implémentation étape par étape?
