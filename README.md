# B-Link

B-Link connecte les personnes qui fêtent leur anniversaire le **même jour**,
partout dans le monde, et n'oublie jamais ceux de vos proches.

Application **Flutter** (Android, iOS) et **Firebase** (Auth Google,
Firestore, Storage, Cloud Functions, Cloud Messaging, Analytics avec
consentement). Interface en français et en anglais, thèmes clair et sombre.

## Fonctionnalités

**Vos proches**

- **Contacts et rappels** : notifications à l'heure choisie, du jour même à un
  mois avant (veille, 2 ou 3 jours, 1 ou 2 semaines, 1 mois, au choix).
- **Import du carnet** : les contacts qui ont un anniversaire sont cochés
  d'office ; une date se donne en un geste aux autres.
- **Messages d'anniversaire** : 154 messages écrits à la main par langue,
  selon la relation (ami, mère, conjoint…), jamais deux fois le même tant
  qu'il en reste ; envoi direct sur **WhatsApp**, copie, ou **carte en image**.
- **Enregistrer dans le téléphone** : la fiche d'un contact ouvre l'éditeur
  de contacts du système, pré-rempli.

**Vos jumeaux d'anniversaire**

- **Même jour** : annuaire volontaire des personnes nées le même jour (ou la
  même semaine, le même mois), dans le monde, votre pays ou votre ville.
- **Aujourd'hui dans le monde** : les membres dont c'est l'anniversaire ;
  on leur envoie un **vœu** choisi parmi 30 messages (jamais un message que
  la personne a déjà reçu), notifié par push. Le jour J, votre **mur de vœux**.
- **Mon jour** : ce que votre date a d'unique (environ 22 millions de
  personnes la partagent), les **personnalités nées le même jour**
  (Wikipédia), une carte à partager.
- **Constellation** : chaque jour de l'année est une étoile, d'autant plus
  brillante que des membres y sont nés ; jours les plus fêtés, homonymes,
  prénoms les plus portés.
- **Rencontres** entre jumeaux d'une même ville, avec conseils de sécurité.

**Confiance**

- Profil privé par défaut ; chaque information publique est choisie une à
  une ; annuaire réservé aux 16 ans et plus.
- Signalement et blocage ; masquage automatique après 3 signalements
  distincts ; écran de modération pour les admins.
- Statistiques d'utilisation seulement avec consentement, jamais reliées au
  compte. Suppression du compte depuis l'app ou par le site.

## Architecture

| Collection | Rôle |
|---|---|
| `users/{uid}` | Profil complet, **privé**. Sous-collections `contacts`, `blocks`, `devices` (jetons push). |
| `public_profiles/{uid}` | Projection publique : seulement les champs que la personne montre (16 ans et plus). |
| `wishes/{uid}/received/{expéditeur}_{année}` | Vœux reçus : message prédéfini, un par expéditeur et par an, lisibles par le seul destinataire. |
| `wishes/{uid}` | Numéros des messages déjà reçus dans l'année (pour ne pas les reproposer), écrit par le serveur. |
| `events/{id}` (+ `attendees`) | Rencontres entre jumeaux d'une même ville. |
| `reports/{id}`, `moderation/{uid}` | Signalements et décisions de modération. |
| `app_stats/constellation` | Agrégats anonymes : naissances par jour, prénoms et noms portés par au moins 3 profils. |
| `admins/{uid}` | Rôles admin, créés côté serveur (`grantAdmin`). |

Cloud Functions ([`functions/index.js`](functions/index.js), Node 22) :
nettoyage à la suppression d'un compte, masquage par signalements, push
« nouveau jumeau » et « vœu reçu », recalcul de la constellation toutes les
6 heures.

Côté app (`lib/`) :

| Dossier | Contenu |
|---|---|
| `theme/` | Système de design : jetons (grille de 4, rayons, typographie), couleurs du logo, verre dépoli (`Glass`). |
| `widgets/ui/` | Composants communs : `AppScaffold`, `GlassCard`, feuilles, badges, champs. |
| `screens/` | Écrans (accueil, contacts, Même jour, Mon jour, constellation, vœux, profil…). |
| `services/` | Firestore, SQLite (`db_helper.dart`), rappels (`notification_service.dart`), carnet du téléphone, Wikipédia, vœux. |
| `providers/` | État : profil, contacts, langue, thème, authentification. |
| `l10n/` | Textes français et anglais (`app_localizations.dart`). |

Règles de sécurité : [`firestore.rules`](firestore.rules),
[`storage.rules`](storage.rules). Rappels en arrière-plan :
[`Docs/BackgroundReminders.md`](Docs/BackgroundReminders.md).

## Prérequis

- Flutter 3.47 (Dart 3.13)
- JDK 17 pour les builds Android (Android Gradle Plugin 9.1)
- JDK 21, Node 22 et `firebase-tools` pour les émulateurs et les Cloud Functions

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

Cloud Functions :

```bash
cd functions && npm ci && npm test
```

Règles Firestore et Storage (émulateur, JDK 21) :

```bash
cd test_rules && npm ci && npm test
```

Tests de fumée sur un appareil branché :

```bash
flutter test integration_test
```

## Déploiement

Le script vérifie d'abord les règles sur l'émulateur, puis déploie règles,
index, Storage, Functions et site :

```bash
scripts/deploy_prod.sh b-link-3b2d5
```

- Forfait **Blaze** obligatoire (Storage, Cloud Functions, tâche planifiée).
- Au premier déploiement de `storage.rules`, accepter que Storage lise
  Firestore (visibilité des photos).
- Règles, index, Functions et app doivent être déployés ensemble.
- Le premier `super_admin` se crée hors de l'app (console Firebase ou script
  Admin SDK), les suivants avec `grantAdmin`. Aucun identifiant dans le dépôt.

Builds de publication : [`Docs/Android.md`](Docs/Android.md),
[`Docs/iOS.md`](Docs/iOS.md), [`Docs/RELEASE.md`](Docs/RELEASE.md).

## Reste à faire avant la publication

- **Connexion Google** : ajouter les empreintes SHA-1 (debug et release) de
  l'app Android dans la console Firebase, puis re-télécharger
  `google-services.json` (aujourd'hui sans client OAuth) et
  `GoogleService-Info.plist` ; renseigner ensuite l'identifiant client web
  dans l'app. Sur iOS, la connexion Apple est exigée par l'App Store.
- Compléter `hosting/privacy.html` et `hosting/delete-account.html` (nom de
  l'éditeur, adresse de contact) et retirer le bandeau « Brouillon ».
- Clé de signature Android dans les secrets GitHub (`Docs/Android.md`).
- Changer le mot de passe admin exposé dans l'historique du dépôt.
- Tester sur de vrais téléphones Android et iPhone.
