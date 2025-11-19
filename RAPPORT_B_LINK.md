# Rapport de Présentation – Application Flutter "b_link"

## Introduction

Ce document présente l’application mobile "b_link", développée avec Flutter et Firebase. Il s’adresse à un public académique (professeur, jury) et détaille le fonctionnement global, les parcours utilisateur et administrateur, ainsi que l’architecture technique et les étapes de déploiement.

---

## Table des matières
1. Présentation générale
2. Fonctionnement pour l’utilisateur
3. Fonctionnement pour l’administrateur
4. Architecture technique
5. Nettoyage et bonnes pratiques
6. Déploiement sur Google Play
7. Liens utiles

---

## 1. Présentation générale

"b_link" est une application sociale permettant de découvrir et de contacter des personnes partageant la même date d’anniversaire. L’utilisateur peut consulter des profils publics, générer et partager des messages personnalisés, tout en gardant le contrôle sur ses données personnelles.

---

## 2. Fonctionnement pour l’utilisateur

- **Accueil / Connexion** : L’utilisateur ouvre l’application, peut se connecter (optionnel) ou utiliser l’app en mode invité.
- **Affichage des profils** : L’utilisateur voit la liste des profils publics nés le même jour que lui (ou une date choisie).
- **Détail d’un profil** : En cliquant sur un profil, il accède à la fiche détaillée (infos publiques, réseaux sociaux, etc.).
- **Génération et partage de message** : Il peut générer un message personnalisé (bouton cadeau 🎁) et le partager via WhatsApp, SMS, email…
- **Pagination** : Si la liste est longue, il peut scroller pour charger plus de profils.
- **Thème clair/sombre** : L’interface s’adapte au thème du téléphone.
- **Vie privée** : L’utilisateur choisit quelles infos sont publiques (nom, ville, date, réseaux, etc.).

---

## 3. Fonctionnement pour l’administrateur

- **Connexion admin** : L’admin se connecte via un compte spécial.
- **Gestion des profils** : Peut voir tous les profils (publics et privés), modifier, supprimer ou masquer des profils.
- **Modération** : Peut signaler ou supprimer des contenus inappropriés, réinitialiser des comptes, gérer les droits d’accès.
- **Statistiques** : Accès à des statistiques d’utilisation (nombre de profils, messages générés, etc.).
- **Gestion des messages automatiques** : Peut éditer les modèles de messages proposés aux utilisateurs.

---

## 4. Architecture technique

- **Technologies principales** :
  - Flutter (Dart) pour l’interface mobile multiplateforme
  - Firebase Firestore pour le stockage des données
  - Firebase Auth (optionnel) pour l’authentification
  - Firebase Functions pour la logique serveur (optionnel)
  - Stockage local pour le fallback offline
- **Structure du projet** :

```
b_link/
├── android/                # Projet Android natif
├── assets/                 # Images, messages, etc.
├── Docs/                   # Documentation
├── functions/              # Fonctions cloud
├── ios/                    # Projet iOS natif
├── lib/                    # Code Flutter principal
│   ├── main.dart           # Entrée de l’app
│   ├── models/             # Modèles de données (UserProfile)
│   ├── screens/            # Écrans (UI)
│   ├── services/           # Accès DB, API
│   └── ...
├── test/                   # Tests unitaires
└── ...
```

- **Sécurité** :
  - Règles Firestore pour contrôler l’accès aux données
  - Contrôle dans l’app pour la visibilité des champs
- **Notifications** : (optionnel) via Firebase Cloud Messaging
- **Déploiement** : via Google Play Store

---

## 5. Nettoyage et bonnes pratiques

- Supprimer les fichiers inutiles (backups, anciens scripts, assets non utilisés)
- Nettoyer les imports et variables non utilisés dans chaque fichier Dart
- Vérifier les dépendances dans `pubspec.yaml` et retirer celles non utilisées
- Utiliser `flutter analyze` pour détecter le code mort ou les problèmes

---

## 6. Déploiement sur Google Play

### Prérequis
- Compte Google Play Console
- Application prête (icônes, nom, version, package name unique)
- Keystore de signature (release)

### Étapes
1. Générer l’AAB (Android App Bundle) :
   ```sh
   flutter build appbundle --release
   ```
2. Configurer la signature release (voir doc Flutter)
3. Tester l’AAB sur un vrai appareil
4. Se connecter à la Google Play Console
5. Créer une nouvelle application
6. Téléverser l’AAB dans la section "Production"
7. Remplir la fiche Play Store (infos, screenshots, politique, etc.)
8. Soumettre pour validation

### Conseils
- Utiliser le mode release pour les builds de production
- Vérifier les permissions Android dans `AndroidManifest.xml`
- Ajouter une politique de confidentialité si besoin
- Tester sur plusieurs appareils

---

## 7. Liens utiles
- [Déploiement Flutter Android](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console/about/)
- [Nettoyage Flutter](https://docs.flutter.dev/tools/clean-up)

---

**Pour toute question ou automatisation, demandez à Copilot !**
