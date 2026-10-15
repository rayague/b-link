# B-Link

B-Link connecte les personnes qui fêtent leur anniversaire le **même jour**,
partout dans le monde, et rappelle les anniversaires de vos proches.

- **Même jour** : un annuaire public (sur la base du volontariat) des
  personnes nées le même jour que vous, avec les liens de réseaux sociaux
  qu'elles ont choisi de partager.
- **Rappels** : une notification la veille et le jour J pour chacun de vos
  contacts, avec des messages d'anniversaire prêts à copier.

Application **Flutter** (Android / iOS) avec **Firebase** (Auth Google,
Firestore, Cloud Functions, Analytics). Interface en français et en anglais.

## Architecture

| Élément | Rôle |
|---|---|
| `users/{uid}` | Profil complet, **privé** (propriétaire et admins uniquement). |
| `users/{uid}/contacts/{id}` | Contacts de l'utilisateur, privés. |
| `public_profiles/{uid}` | Projection publique : uniquement les champs que l'utilisateur a choisi de montrer. N'existe que si le profil est public (16 ans minimum). |
| `reports/{id}` | Signalements de profils, lisibles par les admins. |
| `admins/{uid}` | Rôles admin, créés côté serveur (`grantAdmin`). |
| `app_stats/global` | Compteur d'utilisateurs, maintenu par les Cloud Functions. |

Côté app :

- `lib/providers/` : état (profil, contacts, langue, thème, authentification).
- `lib/services/firebase_sync_service.dart` : accès Firestore. Le SDK
  Firestore gère le cache et la file d'écriture hors ligne.
- `lib/services/notification_service.dart` : rappels (J-1 et J à 9h, fenêtre
  glissante de 30 jours), rafraîchis chaque jour par WorkManager
  (`background_sync.dart`).
- `lib/services/db_helper.dart` : SQLite local (contacts, banque de messages
  importée depuis `assets/messages_en.txt` et `assets/messages_fr.txt`).
- `lib/utils/birthday.dart` : calculs de dates (passage d'année, 29 février).

Les règles de sécurité sont dans [`firestore.rules`](firestore.rules) et les
Cloud Functions dans [`functions/index.js`](functions/index.js) (Node 22).

## Prérequis

- Flutter (stable) et Dart 3
- JDK 17 pour les builds Android (Android Gradle Plugin 9.1)
- JDK 21 et `firebase-tools` pour les émulateurs et les tests de règles
- Android SDK avec la plateforme 37 et le NDK demandé par Flutter

## Développement

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter analyze
flutter test
```

Tests des règles Firestore (émulateur, JDK 21) :

```bash
cd test_rules && npm ci && npm test
```

## Déploiement Firebase

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Le premier `super_admin` se crée hors de l'app (console Firebase ou script
Admin SDK) ; les suivants via la fonction `grantAdmin`. Aucun identifiant ne
doit jamais être stocké dans le dépôt.

Documentation complémentaire : dossier [`Docs/`](Docs/).
