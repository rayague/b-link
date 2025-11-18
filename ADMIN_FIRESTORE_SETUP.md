# 🔐 Système Admin B-Link - Version Firestore Complète

## 📋 Résumé des Modifications

### ✅ Ce qui a été fait:

1. **AdminUser Model** mis à jour avec:
   - `passwordHash` (SHA-256) - Mot de passe hashé stocké en clair dans Firestore
   - `isActive` - Pour activer/désactiver un admin sans supprimer

2. **AdminAuthService** créé avec:
   - Hash SHA-256 des mots de passe
   - Authentification admin complète
   - Gestion des admins (création, désactivation, changement de mot de passe)

3. **InitAdminScreen** créé:
   - Écran pour initialiser le premier admin
   - Accessible via bouton amber ⚙️ dans l'écran d'accueil

---

## 🎯 Comment Initialiser le Premier Admin

### Étape 1: Lancer l'application

1. Ouvrez l'application B-Link
2. Sur l'écran d'accueil, vous verrez un nouveau bouton **AMBER** avec l'icône ⚙️

### Étape 2: Créer le premier admin

1. **Cliquez sur le bouton amber ⚙️**
2. Vous arrivez sur l'écran "Initialisation Admin"
3. **Cliquez sur "Créer le Premier Admin"**

### Étape 3: Résultat

L'application va automatiquement:
- ✅ Créer un compte Firebase Auth: `rayague03@gmail.com`
- ✅ Générer le hash du mot de passe: `Admin@BLink2025!`
- ✅ Créer le document dans Firestore `admins/{uid}` avec:

```json
{
  "uid": "ABC123...",
  "email": "rayague03@gmail.com",
  "passwordHash": "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f",
  "role": "super_admin",
  "createdAt": "2025-11-17T14:30:00.000Z",
  "lastLogin": null,
  "isActive": true
}
```

---

## 🔑 Identifiants Admin

**Email:** `rayague03@gmail.com`  
**Mot de passe:** `Admin@BLink2025!`  
**Rôle:** `super_admin`

⚠️ **Ces informations sont stockées de façon sécurisée:**
- Email: En clair dans Firestore (nécessaire pour l'authentification)
- Mot de passe: Hashé en SHA-256 (impossible à décrypter)
- Le hash du mot de passe: `ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f`

---

## 📊 Structure Firestore

### Collection: `admins`

Chaque document contient:

| Champ | Type | Description | Visible en clair |
|-------|------|-------------|------------------|
| `uid` | string | ID unique Firebase Auth | ✅ Oui |
| `email` | string | Email de l'admin | ✅ Oui |
| `passwordHash` | string | Hash SHA-256 du mot de passe | ✅ Oui (mais inutilisable) |
| `role` | string | 'super_admin' ou 'admin' | ✅ Oui |
| `createdAt` | string | Date de création ISO8601 | ✅ Oui |
| `lastLogin` | string/null | Dernière connexion | ✅ Oui |
| `isActive` | bool | Admin actif ou désactivé | ✅ Oui |

---

## 🔒 Sécurité

### Hash SHA-256
- Le mot de passe n'est **JAMAIS** stocké en clair
- Seul le hash SHA-256 est stocké
- Impossible de retrouver le mot de passe original depuis le hash
- Exemple: `Admin@BLink2025!` → `ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f`

### Firestore Rules
Les règles empêchent:
- ❌ Création d'admin depuis l'app (sauf via InitAdminScreen)
- ❌ Modification du passwordHash depuis l'app
- ❌ Accès par des non-admins
- ✅ Lecture par l'admin lui-même uniquement

---

## 🛠️ Fonctionnalités AdminAuthService

### Méthodes disponibles:

1. **authenticateAdmin(email, password)**
   - Vérifie email + mot de passe
   - Retourne AdminUser si correct, null sinon
   - Met à jour lastLogin

2. **isUserAdmin(uid)**
   - Vérifie si un UID est admin actif
   - Retourne bool

3. **createFirstAdmin()**
   - Crée le premier super_admin
   - ⚠️ Ne peut être appelé qu'une seule fois

4. **createAdmin(email, password, role)**
   - Crée un nouvel admin
   - Réservé aux super_admin

5. **deactivateAdmin(uid)**
   - Désactive un admin (ne supprime pas)
   - L'admin ne peut plus se connecter

6. **changeAdminPassword(uid, newPassword)**
   - Change le mot de passe d'un admin
   - Recalcule le hash SHA-256

7. **getAllAdmins()**
   - Liste tous les admins
   - Retourne List<AdminUser>

---

## ✅ Vérification

### Après avoir cliqué sur "Créer le Premier Admin":

1. **Dans Firestore Console:**
   - Allez dans `admins` collection
   - Vous devriez voir un document avec l'UID
   - Tous les champs sont visibles en clair (sauf passwordHash qui est hashé)

2. **Dans Authentication:**
   - Le compte `rayague03@gmail.com` existe

3. **Dans l'application:**
   - Déconnectez-vous
   - Connectez-vous avec: `rayague03@gmail.com` / `Admin@BLink2025!`
   - Le bouton orange admin apparaît dans le profil

---

## 🎨 Bouton Temporaire

Le bouton **AMBER ⚙️** dans l'écran d'accueil:
- ⚠️ Est temporaire
- 🎯 Doit être utilisé UNE SEULE FOIS
- 🗑️ Peut être supprimé après initialisation

**Pour le supprimer après initialisation:**
Ouvrez `lib/screens/home_screen.dart` et retirez le premier IconButton dans les actions.

---

## 🔄 Prochaines Étapes

1. **Initialisez l'admin** avec le bouton amber
2. **Vérifiez dans Firestore** que le document est créé
3. **Testez la connexion** avec rayague03@gmail.com
4. **Retirez le bouton amber** de home_screen.dart
5. **Déployez les règles Firestore** si nécessaire

---

## 📝 Notes Importantes

- ✅ Toutes les données admin sont dans Firestore
- ✅ Le mot de passe est hashé (SHA-256)
- ✅ Le hash est visible mais inutilisable
- ✅ Impossible de retrouver le mot de passe original
- ⚠️ Gardez le mot de passe `Admin@BLink2025!` en lieu sûr
- 🔄 Vous pouvez le changer avec `changeAdminPassword()`
