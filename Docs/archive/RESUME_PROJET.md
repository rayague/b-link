# 7. Fonctionnement de l'application (Utilisateurs & Admin)

## Parcours Utilisateur (grand public)

1. **Accueil / Connexion (si activé)**
   - L’utilisateur ouvre l’application.
   - (Optionnel) Il peut se connecter ou utiliser l’app en mode invité.

2. **Affichage des profils du même jour**
   - L’utilisateur voit la liste des profils publics qui partagent la même date d’anniversaire que lui (ou la date sélectionnée).
   - Pour chaque profil, il voit le prénom, la ville (si public), le signe astro, etc.

3. **Détail d’un profil**
   - En cliquant sur un profil, il accède à la fiche détaillée (PublicProfileScreen) : infos publiques, réseaux sociaux, etc.

4. **Génération et partage de message**
   - L’utilisateur peut générer un message personnalisé (bouton cadeau 🎁) et le copier/coller dans WhatsApp, SMS, email…

5. **Pagination**
   - Si beaucoup de profils, l’utilisateur peut scroller pour charger plus de résultats (pagination automatique ou bouton).

6. **Thème clair/sombre**
   - L’interface s’adapte au thème du téléphone.

7. **Sécurité & vie privée**
   - L’utilisateur choisit quelles infos sont publiques (nom, ville, date, réseaux, etc.).
   - Les données privées ne sont jamais affichées sans consentement.

## Parcours Administrateur (admin)

1. **Accès admin**
   - L’admin se connecte via un compte spécial (Firebase Auth ou autre).

2. **Gestion des profils**
   - Peut voir tous les profils, y compris ceux non publics.
   - Peut modifier, supprimer ou masquer des profils.

3. **Modération**
   - Peut signaler ou supprimer des contenus inappropriés.
   - Peut réinitialiser des comptes ou gérer les droits d’accès.

4. **Statistiques**
   - Accès à des statistiques d’utilisation (nombre de profils, messages générés, etc.).

5. **Gestion des messages automatiques**
   - Peut éditer les modèles de messages proposés aux utilisateurs.

## Fonctionnement technique général

- **Données** : Stockées dans Firestore (profils, messages, logs)
- **Sécurité** : Règles Firestore + contrôle dans l’app
- **Notifications** : (optionnel) via Firebase Cloud Messaging
- **Sauvegarde locale** : fallback si offline
- **Mises à jour** : via le store (Play Store)

---

**Résumé** : L’application permet à tout utilisateur de découvrir et contacter des personnes nées le même jour, tout en gardant le contrôle sur ses données. Les admins assurent la sécurité, la modération et la gestion des contenus.
# Résumé de l'application Flutter "b_link"

## 1. Hiérarchie et structure du projet

```
b_link/
├── android/                # Projet Android natif (config, build, gradle)
├── assets/                 # Fichiers statiques (images, messages, etc.)
├── build/                  # Dossier de build (généré)
├── coverage/               # Rapports de couverture de tests
├── Docs/                   # Documentation technique et guides
├── functions/              # Fonctions cloud (Firebase Functions)
├── ios/                    # Projet iOS natif (config, build, Xcode)
├── lib/                    # Code source principal Flutter
│   ├── firebase_options.dart
│   ├── main.dart           # Point d'entrée de l'app
│   ├── l10n/               # Localisation
│   ├── models/             # Modèles de données (ex: user_profile.dart)
│   ├── providers/          # Providers (état, contextes)
│   ├── screens/            # Écrans principaux (UI)
│   ├── services/           # Services (DB, API, etc.)
│   └── utils/              # Utilitaires
├── linux/                  # Projet Linux natif
├── macos/                  # Projet macOS natif
├── scripts/                # Scripts d'automatisation (déploiement, fix, etc.)
├── test/                   # Tests unitaires et widget
├── tool/                   # Outils personnalisés
├── web/                    # Support web
├── windows/                # Projet Windows natif
├── pubspec.yaml            # Dépendances et config Flutter
├── package.json            # Dépendances JS (Firebase Functions)
├── README.md               # Documentation principale
└── ...
```

## 2. Fonctionnalités principales
- Authentification Firebase (optionnel)
- Affichage de profils publics partageant la même date d'anniversaire
- Détail d'un profil public (PublicProfileScreen)
- Génération et partage de messages personnalisés
- Pagination (optionnelle, à implémenter pour gros volumes)
- Localisation (l10n)
- Stockage Firestore + fallback local

## 3. Modèle principal : UserProfile
- uid, name, birthDate, birthTime, birthplace, birthCountry, birthCity, zodiac
- socialLinks (Map<String, String>), isPublic, publicName, publicBirthDate, etc.
- Méthodes : `fromMap`, `toMap`

## 4. Nettoyage du projet
- Supprimez les fichiers inutiles (backups, anciens scripts, assets non utilisés)
- Nettoyez les imports non utilisés dans chaque fichier Dart
- Supprimez les variables non utilisées (warnings dans l'IDE)
- Vérifiez les dépendances dans `pubspec.yaml` et retirez celles non utilisées
- Utilisez `flutter pub get` puis `flutter pub outdated` pour vérifier les dépendances
- Utilisez `flutter analyze` pour détecter le code mort ou les problèmes

## 5. Déploiement sur Google Play

### Prérequis
- Compte Google Play Console
- App prête (icônes, nom, version, package name unique)
- Keystore de signature (release)

### Étapes
1. **Générez l'APK ou l'AAB (Android App Bundle)**
   ```sh
   flutter build appbundle --release
   # ou pour APK
   flutter build apk --release
   ```
2. **Configurez la signature release**
   - Placez votre keystore dans `android/app/`
   - Modifiez `android/key.properties` et `android/app/build.gradle`
   - Exemple dans la doc Flutter : https://docs.flutter.dev/deployment/android#signing-the-app
3. **Testez l'AAB/APK sur un vrai appareil**
4. **Connectez-vous à la Google Play Console**
5. **Créez une nouvelle application**
6. **Téléversez l'AAB (ou APK) dans la section "Production"**
7. **Remplissez les infos (fiche Play Store, screenshots, politique, etc.)**
8. **Soumettez pour validation**

### Conseils
- Utilisez le mode release pour les builds de production
- Vérifiez les permissions Android dans `AndroidManifest.xml`
- Ajoutez une politique de confidentialité si besoin
- Testez sur plusieurs appareils

## 6. Liens utiles
- [Déploiement Flutter Android](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console/about/)
- [Nettoyage Flutter](https://docs.flutter.dev/tools/clean-up)

---

**Pour toute question ou automatisation, demandez à Copilot !**
