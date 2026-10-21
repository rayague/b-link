# 🚀 Guide de Déploiement - Firebase Sync

## 📋 Prérequis

1. ✅ Firebase project configuré
2. ✅ Firebase Auth activé (Anonymous + Email/Password)
3. ✅ Cloud Firestore activé
4. ✅ `google-services.json` (Android) et `GoogleService-Info.plist` (iOS) configurés

## 🔧 Configuration Firebase

### 1. Activer Cloud Firestore

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet `b-link`
3. Aller dans **Firestore Database**
4. Cliquer sur **Créer une base de données**
5. Choisir **Mode production**
6. Sélectionner la région (ex: `europe-west1` pour l'Europe)

### 2. Déployer les règles de sécurité

Deux méthodes:

#### Méthode A: Via la console Firebase
1. Aller dans **Firestore Database** > **Règles**
2. Copier le contenu de `firestore.rules.sync`
3. Cliquer sur **Publier**

#### Méthode B: Via Firebase CLI
```bash
# Copier les nouvelles règles
copy firestore.rules.sync firestore.rules

# Déployer
firebase deploy --only firestore:rules
```

### 3. Créer les indexes (si nécessaire)

Si vous voyez des erreurs dans la console Firebase concernant les indexes:

```bash
firebase deploy --only firestore:indexes
```

Ou créer manuellement dans la console:
- Collection: `users/{userId}/contacts`
- Champs: `userId` (Ascending), `lastUpdated` (Descending)

## 📱 Déploiement de l'application

### 1. Vérifier la compilation

```bash
flutter clean
flutter pub get
flutter analyze
```

### 2. Tester en mode debug

```bash
# Android
flutter run --debug

# iOS
flutter run --debug --device-id=<your-device-id>
```

### 3. Build pour production

#### Android (APK)
```bash
flutter build apk --release
```

APK généré dans: `build/app/outputs/flutter-apk/app-release.apk`

#### Android (App Bundle - recommandé pour Play Store)
```bash
flutter build appbundle --release
```

Bundle généré dans: `build/app/outputs/bundle/release/app-release.aab`

#### iOS
```bash
flutter build ios --release
```

Ensuite ouvrir `ios/Runner.xcworkspace` dans Xcode et archiver.

## 🧪 Tests de la synchronisation

### Test 1: Première installation
1. Installer l'app sur un appareil
2. S'inscrire avec un email
3. Ajouter un profil complet
4. Ajouter 3-4 contacts
5. Vérifier dans Firebase Console:
   - Collection `users/{uid}` créée
   - Sous-collection `contacts` avec 3-4 documents
   - Document `app_stats/global` avec `totalUsers: 1`

### Test 2: Synchronisation multi-appareils
1. Se connecter avec le même compte sur un autre appareil
2. Vérifier que:
   - Le profil est identique
   - Tous les contacts sont présents
   - Les photos sont chargées

### Test 3: Réinstallation
1. Désinstaller l'app d'un appareil
2. Réinstaller l'app
3. Se reconnecter avec le même compte
4. Vérifier que **toutes les données** sont restaurées

### Test 4: Modification en temps réel
1. Ouvrir l'app sur 2 appareils avec le même compte
2. Modifier un contact sur l'appareil A
3. Rafraîchir la liste sur l'appareil B
4. Vérifier que les changements sont synchronisés

### Test 5: Mode hors ligne
1. Activer le mode avion
2. Ajouter un contact
3. Modifier le profil
4. Désactiver le mode avion
5. Vérifier que les changements se synchronisent automatiquement

## 📊 Vérification des statistiques

### Accéder à l'interface Admin
1. Ouvrir l'app
2. Aller dans **Profil**
3. Cliquer sur l'icône **⚙️ Admin** (en haut à droite)
4. Vérifier:
   - Nombre total d'utilisateurs
   - Liste complète avec tous les détails

### Vérifier dans Firebase Console
1. Aller dans **Firestore Database**
2. Vérifier:
   - Collection `users`: nombre de documents = nombre d'utilisateurs
   - Document `app_stats/global`: `totalUsers` correct
   - Chaque utilisateur a sa sous-collection `contacts`

## 🔍 Monitoring et débogage

### Logs Firebase
```dart
// Les logs sont activés par défaut
// Pour voir les logs:
// - Android: `adb logcat | grep -i firebase`
// - iOS: Console de Xcode
```

### Console Firebase
1. **Firestore Usage**:
   - Aller dans **Firestore Database** > **Usage**
   - Vérifier le nombre de lectures/écritures
   
2. **Firestore Data**:
   - Explorer les collections
   - Vérifier la structure des données

### Debugging
Si la synchronisation ne fonctionne pas:

1. **Vérifier l'authentification**:
```dart
final user = FirebaseAuth.instance.currentUser;
print('User UID: ${user?.uid}');
print('User email: ${user?.email}');
```

2. **Vérifier les permissions Firestore**:
   - Tester les règles dans la console Firebase
   - Onglet **Règles** > **Simulateur de règles**

3. **Vérifier les logs**:
```dart
// Tous les logs commencent par:
// ✅ (succès), ❌ (erreur), 🔄 (en cours), ⚠️ (warning)
```

## 📈 Optimisations (Production)

### 1. Activer la persistence hors ligne
Déjà activé par défaut dans Flutter, mais vous pouvez configurer:

```dart
// Dans main.dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### 2. Pagination des contacts (si >100 contacts)
```dart
// Dans FirebaseSyncService
Future<List<Contact>> getContactsPaginated(int limit, DocumentSnapshot? lastDoc) async {
  var query = _firestore
      .collection('users')
      .doc(_userId)
      .collection('contacts')
      .limit(limit);
      
  if (lastDoc != null) {
    query = query.startAfterDocument(lastDoc);
  }
  
  final snapshot = await query.get();
  return snapshot.docs.map((doc) => Contact.fromJson(doc.data())).toList();
}
```

### 3. Cloud Functions pour les stats (Optionnel)
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateUserCount = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const statsRef = admin.firestore().collection('app_stats').doc('global');
    
    return statsRef.set({
      totalUsers: admin.firestore.FieldValue.increment(1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  });

exports.decrementUserCount = functions.firestore
  .document('users/{userId}')
  .onDelete(async (snap, context) => {
    const statsRef = admin.firestore().collection('app_stats').doc('global');
    
    return statsRef.update({
      totalUsers: admin.firestore.FieldValue.increment(-1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
  });
```

Déployer:
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## 🔐 Sécurité - Checklist

- ✅ Règles Firestore déployées (`firestore.rules.sync`)
- ✅ Utilisateurs isolés (lecture/écriture uniquement de leurs données)
- ✅ Firebase Auth activé (pas d'accès anonyme permanent)
- ✅ API Keys configurées dans Firebase Console
- ✅ `.gitignore` contient les fichiers sensibles:
  - `google-services.json`
  - `GoogleService-Info.plist`
  - `firebase_options.dart`

## 📝 Maintenance

### Backup Firestore (recommandé)
```bash
# Via gcloud CLI
gcloud firestore export gs://your-bucket-name/backups/$(date +%Y%m%d)
```

### Monitoring des coûts
1. Aller dans **Firebase Console** > **Usage and billing**
2. Configurer des alertes de budget
3. Plan gratuit Firestore:
   - 1 Go de stockage
   - 50k lectures/jour
   - 20k écritures/jour
   - 20k suppressions/jour

### Nettoyage des anciennes données (si nécessaire)
```dart
// Supprimer les contacts de plus de 2 ans sans modification
final twoYearsAgo = DateTime.now().subtract(Duration(days: 730));
final oldContacts = await _firestore
    .collection('users')
    .doc(_userId)
    .collection('contacts')
    .where('lastUpdated', isLessThan: twoYearsAgo)
    .get();

for (final doc in oldContacts.docs) {
  await doc.reference.delete();
}
```

## ✅ Checklist finale avant production

- [ ] Firebase project configuré
- [ ] Règles de sécurité Firestore déployées
- [ ] Tests de synchronisation effectués
- [ ] Interface Admin testée
- [ ] Mode hors ligne testé
- [ ] Multi-appareils testé
- [ ] Réinstallation testée
- [ ] Monitoring configuré
- [ ] Backup configuré (optionnel)
- [ ] Cloud Functions déployées (optionnel)
- [ ] Budget Firebase configuré

---

**🎉 Votre app est prête pour la production!**
