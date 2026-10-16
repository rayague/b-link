# Configuration iOS

Les réglages ci-dessous sont dans le dépôt mais **n'ont pas encore été
compilés ni testés** : il faut un Mac avec Xcode.

## Déjà fait dans le dépôt

- Identifiant de l'app : `com.rayague.b-link` (aligné sur
  `GoogleService-Info.plist` ; c'était `com.example.bLink`).
- Nom affiché : B-Link.
- Rafraîchissement quotidien des rappels (`ios/Runner/AppDelegate.swift`,
  `Info.plist`) :
  - tâche `com.rayague.b-link.reminders-refresh` déclarée dans
    `BGTaskSchedulerPermittedIdentifiers` ;
  - modes d'arrière-plan `fetch` et `processing` ;
  - plugins enregistrés dans le moteur Flutter d'arrière-plan.
- Rappels affichés même quand l'app est au premier plan.

## À faire

### 1. Connexion Google (bloquant)

Le `GoogleService-Info.plist` actuel ne contient ni `CLIENT_ID` ni
`REVERSED_CLIENT_ID` : la connexion Google ne peut pas fonctionner sur iPhone.

1. Console Firebase > Paramètres du projet > app iOS `com.rayague.b-link` :
   vérifier que la connexion Google est activée (Authentication > Sign-in
   method), puis **retélécharger** `GoogleService-Info.plist` et remplacer
   `ios/Runner/GoogleService-Info.plist`.
2. Dans `ios/Runner/Info.plist`, ajouter le schéma d'URL avec la valeur de
   `REVERSED_CLIENT_ID` :

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.XXXXXXXX</string>
       </array>
     </dict>
   </array>
   ```

### 2. Sur le Mac

1. Dans Xcode (Runner > Signing & Capabilities) : choisir l'équipe de
   signature, ajouter la capacité **Background Modes** (cocher « Background
   fetch » et « Background processing ») si Xcode ne la reprend pas depuis
   `Info.plist`.
2. `cd ios && pod install`, puis `flutter build ios`.
3. Tester : connexion Google, inscription, « Même jour », réception d'un
   rappel (le rafraîchissement d'arrière-plan peut se déclencher depuis
   Xcode : Debug > Simulate Background Fetch).

### 3. Notifications push (nouveau jumeau d'anniversaire)

1. Apple Developer : créer une clé APNs (Keys > Apple Push Notifications
   service), puis la téléverser dans la console Firebase (Paramètres du
   projet > Cloud Messaging > app iOS).
2. Dans Xcode (Runner > Signing & Capabilities) : ajouter **Push
   Notifications** (crée l'entitlement `aps-environment`). Le mode
   d'arrière-plan `remote-notification` est déjà déclaré dans `Info.plist`.
3. Tester sur un vrai iPhone (les notifications push ne fonctionnent pas sur
   le simulateur).
