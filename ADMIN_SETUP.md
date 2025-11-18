# 🔐 Configuration Administrateur B-Link

## Étape 1: Créer le compte admin Firebase Auth

1. **Allez sur Firebase Console:**
   https://console.firebase.google.com/project/b-link-3b2d5/authentication/users

2. **Cliquez sur "Ajouter un utilisateur"**

3. **Remplissez:**
   ```
   Email: rayague03@gmail.com
   Mot de passe: Admin@BLink2025!
   ```
   ⚠️ **NOTEZ CE MOT DE PASSE!** C'est différent de votre mot de passe utilisateur normal.

4. **Copiez l'UID** généré (ex: `abc123def456...`)

---

## Étape 2: Créer l'entrée admin dans Firestore

1. **Allez sur Firestore:**
   https://console.firebase.google.com/project/b-link-3b2d5/firestore/data

2. **Créez une nouvelle collection:**
   - Nom: `admins`

3. **Ajoutez un document:**
   - ID du document: `[L'UID copié à l'étape 1]`

4. **Ajoutez ces champs:**
   ```
   uid (string): [L'UID copié]
   email (string): rayague03@gmail.com
   role (string): super_admin
   createdAt (string): 2025-11-17T10:00:00.000Z
   lastLogin (null): null
   ```

---

## Étape 3: Tester la connexion admin

1. **Ouvrez votre application B-Link**

2. **Déconnectez-vous** si vous êtes connecté

3. **Connectez-vous avec:**
   ```
   Email: rayague03@gmail.com
   Mot de passe: Admin@BLink2025!
   ```

4. **Allez dans "Mon Profil"**

5. **Vous devriez voir:**
   - Un bouton **ORANGE** avec l'icône ⚙️ en haut à droite
   - C'est le bouton "Statistiques Admin"!

6. **Cliquez dessus** → Accès à l'espace admin! 🎉

---

## 🔑 Credentials Admin

**Email:** rayague03@gmail.com  
**Mot de passe:** Admin@BLink2025!

⚠️ **IMPORTANT:** Ce mot de passe est **DIFFÉRENT** de votre mot de passe utilisateur normal!

---

## 📋 Ajouter d'autres admins plus tard

Via Firestore Console, créez un nouveau document dans `admins/` avec:
- ID: UID de l'utilisateur
- Champs: uid, email, role, createdAt

---

## 🛡️ Sécurité

Les règles Firestore empêchent:
- ✅ Lecture par l'admin lui-même uniquement
- ❌ Création/Modification depuis l'app (doit être fait via console)
- ❌ Accès par des non-admins
