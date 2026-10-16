# 📝 DOCUMENTATION - Système de Messages d'Anniversaire

## 📋 Table des Matières
1. [Vue d'ensemble](#vue-densemble)
2. [Format du fichier](#format-du-fichier)
3. [Parseur de messages](#parseur-de-messages)
4. [Flux d'importation](#flux-dimportation)
5. [Utilisation dans l'application](#utilisation-dans-lapplication)
6. [Exemples pratiques](#exemples-pratiques)

---

## 🎯 Vue d'ensemble

Le système de messages de B-Link permet de générer des messages d'anniversaire personnalisés selon la relation avec le contact (fils, fille, ami, etc.). Les messages sont stockés dans des fichiers texte puis importés dans une base de données SQLite locale.

### Fichiers concernés

1. **Fichiers de messages (Assets):**
   - `assets/messages.txt` - Fichier actif utilisé par l'app
   - `assets/messages_original_backup.txt` - Backup
   - `assets/messages_original_backup_2025-10-22T013451414350.txt` - Backup daté

2. **Code source:**
   - `lib/services/message_parser.dart` - Parser pour extraire les messages
   - `lib/services/db_helper.dart` - Importation en base de données
   - `lib/services/message_repository.dart` - Interface d'accès aux messages

---

## 📄 Format du fichier

### Structure générale

Le fichier `messages.txt` utilise un format délimité par des séparateurs spéciaux :

```
category1|category2¦relation¦message text
```

### Explication des délimiteurs

- **`|`** (pipe) - Sépare les catégories ou métadonnées
- **`¦`** (broken bar/¦) - Sépare la relation du texte du message

### Format actuel (messages.txt)

```plaintext
default|default¦son¦My dear son, today we celebrate not only the day of your birth...
default|default¦daughter¦Happy birthday to my precious daughter...
default|default¦friend¦To my amazing friend, happy birthday!...
```

**Structure:**
- **Champ 1:** Catégorie principale (généralement "default")
- **Champ 2:** Sous-catégorie (généralement "default")
- **Champ 3:** Relation (son, daughter, friend, etc.)
- **Champ 4:** Texte du message

### Format du backup (messages_original_backup_*.txt)

```plaintext
default|son¦My dear son, today we celebrate...
default|daughter¦Happy birthday to my precious daughter...
```

**Structure simplifiée:**
- **Champ 1:** Catégorie (généralement "default")
- **Champ 2:** Relation (son, daughter, friend, etc.)
- **Champ 3:** Texte du message

---

## ⚙️ Parseur de Messages

### Classe: `message_parser.dart`

Le parseur est responsable d'extraire les messages du fichier texte et de les transformer en structure de données exploitable.

#### Fonction principale: `parseMessagesFromContent()`

```dart
List<Map<String,String>> parseMessagesFromContent(String content)
```

**Retour:** Liste de maps avec les clés `relation` et `text`

#### Stratégies de parsing (ordre de priorité)

1. **Détection de catégories JavaScript/TypeScript:**
   ```regex
   const ([A-Za-z0-9_-]+) = [
   ```
   - Cherche des patterns comme `const son = [...]`
   - Extrait le nom de la catégorie comme relation

2. **Recherche de clés connues:**
   ```regex
   (?:content|text|message|body|description)\s*:\s*(?:`|"|')(.*)(?:`|"|')
   ```
   - Cherche des objets JSON avec clés spécifiques
   - Extrait le texte entre guillemets

3. **Capture de littéraux de chaîne:**
   ```regex
   `(.*)`|"(.*)"|'(.*)'
   ```
   - Capture tout texte entre backticks, guillemets doubles ou simples
   - Filtre les chaînes trop courtes (< 6 caractères)
   - Ignore les URLs et chemins de fichiers

4. **Fallback ligne par ligne:**
   - Si aucune des méthodes précédentes ne fonctionne
   - Traite chaque ligne comme un message potentiel

#### Normalisation: `normalizeForParse()`

```dart
String normalizeForParse(String s) {
  var out = s.replaceAll(RegExp(r'\r\n|\r|\n'), ' ');  // Supprime les retours ligne
  out = out.replaceAll(RegExp(r'\s+'), ' ').trim();     // Normalise les espaces
  // Supprime les guillemets extérieurs
  if ((out.startsWith('"') && out.endsWith('"')) || 
      (out.startsWith("'") && out.endsWith("'"))) {
    out = out.substring(1, out.length-1);
  }
  return out;
}
```

#### Mapping des relations: `_mapCategoryToRelation()`

Convertit les noms de catégories en relations standardisées :

```dart
{
  'son': 'son',
  'daughter': 'daughter',
  'sister': 'sister',
  'brother': 'brother',
  'friend': 'friend',
  'neighbor': 'neighbor',
  'bestfriend': 'bestfriend',
  'boyfriend': 'boyfriend',
  'girlfriend': 'girlfriend',
  'husband': 'husband',
  'wife': 'wife',
  'father': 'father',
  'mother': 'mother',
  'auntie': 'auntie',
  'uncle': 'uncle',
  'cousin': 'cousin',
  'niece': 'niece',
  'nephew': 'nephew',
  'grand-son': 'grand-son',
  'grand-daughter': 'grand-daughter',
  'grand-father': 'grand-father',
  'grand-mother': 'grand-mother',
  'god-father': 'god-father',
  'god-mother': 'god-mother'
}
```

---

## 🔄 Flux d'importation

### Classe: `DBHelper` (db_helper.dart)

#### Fonction: `importMessagesIfEmpty()`

**Processus complet:**

```
1. Vérification du flag 'messages_seeded'
   ↓
2. Si seeded = true → STOP (déjà importé)
   ↓
3. Compte les messages existants
   ↓
4. Si count > 0 → Marquer seeded et STOP
   ↓
5. Charger assets/messages.txt
   ↓
6. Parser le contenu avec message_parser
   ↓
7. Si parsing réussi → Import en transaction
   ↓
8. SINON → Fallback parsing ligne par ligne
   ↓
9. Marquer 'messages_seeded' = true
   ↓
10. Retourner nombre de messages insérés
```

#### Code simplifié:

```dart
Future<int> importMessagesIfEmpty() async {
  // 1. Vérifier si déjà seedé
  final seededFlag = await _getMeta('messages_seeded');
  if (seededFlag == 'true') return 0;
  
  // 2. Vérifier si messages existent
  final count = await _messagesCount();
  if (count > 0) {
    await _setMeta('messages_seeded', 'true');
    return 0;
  }
  
  var inserted = 0;
  try {
    // 3. Charger le fichier
    final content = await rootBundle.loadString('assets/messages.txt');
    
    // 4. Parser avec le parser dédié
    final parsed = parser.parseMessagesFromContent(content);
    
    if (parsed.isNotEmpty) {
      // 5. Import en transaction pour performance
      final db = await database;
      await db.transaction((txn) async {
        for (final row in parsed) {
          final rel = (row['relation'] ?? 'default').toString().toLowerCase();
          final txt = (row['text'] ?? '').toString();
          if (txt.isEmpty) continue;
          await txn.insert('messages', {'relation': rel, 'text': txt});
          inserted++;
        }
      });
    } else {
      // 6. Fallback: parsing ligne par ligne
      // (voir code complet dans db_helper.dart)
    }
  } catch (e) {
    // Ignore les erreurs: l'app fonctionne avec messages par défaut
  }
  
  // 7. Marquer comme seedé
  if (inserted > 0) await _setMeta('messages_seeded', 'true');
  return inserted;
}
```

#### Formats de ligne supportés (fallback)

1. **Format JSON:**
   ```json
   {"relation":"friend","text":"Happy birthday!"}
   ```

2. **Format pipe:**
   ```
   friend|Happy birthday!
   ```

3. **Format texte simple:**
   ```
   Happy birthday!
   ```
   → Relation = 'default'

---

## 🎮 Utilisation dans l'application

### 1. MessageRepository (Interface)

```dart
class MessageRepository {
  final DBHelper _db = DBHelper();

  Future<String> getRandomForRelation(String relation, String name) async {
    final t = await _db.getRandomMessageByRelation(relation);
    if (t == null) return 'Happy birthday, $name!';
    return t.replaceAll('{name}', name);
  }
}
```

**Fonctionnement:**
- Récupère un message aléatoire pour la relation donnée
- Remplace le placeholder `{name}` par le nom du contact
- Retourne un message par défaut si aucun message trouvé

### 2. Utilisation dans les écrans

#### AdminStatsScreen (Test de notifications)

```dart
final messageRepo = MessageRepository();
final message = await messageRepo.getRandomForRelation(category, 'Contact Test');
await notificationService.sendTestNotificationWithMessage(
  contact: testContact,
  message: message,
);
```

#### CelebrationScreen (Génération de messages)

```dart
void _generateAndCopy(Contact c) async {
  final repo = MessageRepository();
  final msg = await repo.getRandomForRelation(c.relation, c.name);
  await Clipboard.setData(ClipboardData(text: msg));
  
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Generated message'),
      content: Text(msg),
      // ...
    ),
  );
}
```

#### SameDayScreen (Messages pour profils du même jour)

```dart
final repo = MessageRepository();
final msg = await repo.getRandomForRelation('friend', profile['name']);
// Afficher ou copier le message
```

---

## 💡 Exemples pratiques

### Exemple 1: Ajouter un nouveau message

**Dans messages.txt:**
```plaintext
default|default¦son¦Happy birthday my amazing son! You make me proud every day.
```

**Résultat en base de données:**
```sql
INSERT INTO messages (relation, text) 
VALUES ('son', 'Happy birthday my amazing son! You make me proud every day.');
```

### Exemple 2: Message avec placeholder

**Dans messages.txt:**
```plaintext
default|default¦daughter¦{name}, you are the light of my life. Happy birthday!
```

**Utilisation:**
```dart
final repo = MessageRepository();
final msg = await repo.getRandomForRelation('daughter', 'Emma');
// Résultat: "Emma, you are the light of my life. Happy birthday!"
```

### Exemple 3: Message par défaut (fallback)

**Si aucun message trouvé pour la relation:**
```dart
final msg = await repo.getRandomForRelation('unknown_relation', 'John');
// Résultat: "Happy birthday, John!"
```

---

## 🗄️ Schéma de la table messages

```sql
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  relation TEXT NOT NULL,
  text TEXT NOT NULL
)
```

**Colonnes:**
- `id`: Identifiant unique auto-incrémenté
- `relation`: Type de relation (son, daughter, friend, etc.)
- `text`: Texte du message (peut contenir `{name}`)

---

## 🔧 Métadonnées (table meta)

```sql
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT
)
```

**Clé importante:**
- `messages_seeded`: 'true' si les messages ont été importés

**Fonctions d'accès:**
```dart
Future<String?> _getMeta(String key)
Future<void> _setMeta(String key, String value)
```

---

## 📊 Statistiques des messages

### Relations supportées (23 types)

1. son (fils)
2. daughter (fille)
3. sister (sœur)
4. brother (frère)
5. friend (ami/amie)
6. neighbor (voisin/voisine)
7. bestfriend (meilleur ami)
8. boyfriend (petit ami)
9. girlfriend (petite amie)
10. husband (mari)
11. wife (épouse)
12. father (père)
13. mother (mère)
14. auntie (tante)
15. uncle (oncle)
16. cousin (cousin/cousine)
17. niece (nièce)
18. nephew (neveu)
19. grand-son (petit-fils)
20. grand-daughter (petite-fille)
21. grand-father (grand-père)
22. grand-mother (grand-mère)
23. god-father (parrain)
24. god-mother (marraine)

### Fichier actuel

**messages.txt:**
- Environ **2500+ messages**
- Format: `default|default¦relation¦text`
- Plusieurs messages par relation pour variété

**messages_original_backup_*.txt:**
- Même contenu avec format simplifié
- Format: `default|relation¦text`

---

## 🚀 Optimisations

### Performance

1. **Import en transaction:**
   - Tous les inserts dans une seule transaction
   - Évite les commits multiples
   - Gain de performance significatif

2. **Flag de seeding:**
   - Vérification rapide avant import
   - Évite les imports redondants
   - Stocké dans table `meta`

3. **Requête aléatoire optimisée:**
   ```dart
   Future<String?> getRandomMessageByRelation(String relation) async {
     final db = await database;
     final res = await db.rawQuery(
       'SELECT text FROM messages WHERE relation = ? ORDER BY RANDOM() LIMIT 1',
       [relation.toLowerCase()]
     );
     return res.isEmpty ? null : res.first['text'] as String?;
   }
   ```

### Gestion des erreurs

- **Import silencieux:** Les erreurs d'import ne bloquent pas l'app
- **Fallback:** Message par défaut si aucun message trouvé
- **Parsing robuste:** Multiple stratégies de parsing

---

## 🔄 Workflow de mise à jour des messages

### 1. Modifier le fichier

```bash
# Éditer le fichier
nano assets/messages.txt

# Ou copier un nouveau fichier
cp new_messages.txt assets/messages.txt
```

### 2. Forcer le re-seeding

**Option A: Supprimer le flag (recommandé)**
```dart
await _deleteMeta('messages_seeded');
await importMessagesIfEmpty();
```

**Option B: Supprimer la base de données**
```dart
// L'app recréera tout au prochain lancement
await deleteDatabase(path);
```

**Option C: Truncate la table**
```sql
DELETE FROM messages;
DELETE FROM meta WHERE key = 'messages_seeded';
```

### 3. Redémarrer l'application

Les nouveaux messages seront importés automatiquement.

---

## 📝 Recommandations

### Bonnes pratiques

1. **Toujours faire un backup** avant modification
2. **Tester avec quelques messages** avant import massif
3. **Utiliser des placeholders** (`{name}`) pour personnalisation
4. **Vérifier la cohérence** des relations
5. **Éviter les messages trop longs** (lisibilité)

### Format recommandé

```plaintext
category1|category2¦relation¦message with {name} placeholder
```

**Exemple:**
```plaintext
default|default¦friend¦Happy birthday {name}! You're an amazing friend.
```

### Éviter

- ❌ Messages sans relation
- ❌ Textes vides
- ❌ Caractères spéciaux non échappés
- ❌ Lignes trop longues (> 500 caractères)
- ❌ URLs ou chemins de fichiers dans les messages

---

## 🐛 Debugging

### Vérifier l'import

```dart
final count = await _messagesCount();
print('Messages in DB: $count');

final seeded = await _getMeta('messages_seeded');
print('Seeded flag: $seeded');
```

### Tester le parsing

```dart
final content = await rootBundle.loadString('assets/messages.txt');
final parsed = parseMessagesFromContent(content);
print('Parsed ${parsed.length} messages');
for (final msg in parsed.take(5)) {
  print('${msg['relation']}: ${msg['text']}');
}
```

### Requêtes SQL directes

```sql
-- Compter les messages par relation
SELECT relation, COUNT(*) as count 
FROM messages 
GROUP BY relation 
ORDER BY count DESC;

-- Voir quelques messages
SELECT relation, SUBSTR(text, 1, 50) as preview 
FROM messages 
LIMIT 10;

-- Vérifier les doublons
SELECT text, COUNT(*) as count 
FROM messages 
GROUP BY text 
HAVING count > 1;
```

---

## 📚 Références

### Fichiers sources

- [message_parser.dart](lib/services/message_parser.dart)
- [db_helper.dart](lib/services/db_helper.dart)
- [message_repository.dart](lib/services/message_repository.dart)
- [messages.txt](assets/messages.txt)

### Écrans utilisant les messages

- [admin_stats_screen.dart](lib/screens/admin_stats_screen.dart) - Test de notifications
- [celebration_screen.dart](lib/screens/celebration_screen.dart) - Génération de messages
- [same_day_screen.dart](lib/screens/same_day_screen.dart) - Profils du même jour
- [home_screen.dart](lib/screens/home_screen.dart) - Actions rapides

---

**Dernière mise à jour:** 23 Décembre 2025  
**Version:** 1.0
