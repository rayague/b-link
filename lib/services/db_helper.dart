import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import '../models/contact.dart';
import 'message_parser.dart';

/// Base SQLite locale : contacts de l'utilisateur et banque de messages.
///
/// Le profil et la synchronisation ne passent plus par ici : Firestore gère
/// lui-même le cache hors-ligne et la file d'écriture sur mobile.
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  /// Incrémenter pour réimporter les banques de messages après une mise à jour.
  static const int messagesVersion = 6;

  /// Banques de messages par langue (la première sert de repli).
  static const Map<String, String> messageAssets = {
    'en': 'assets/messages_en.txt',
    'fr': 'assets/messages_fr.txt',
  };

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('contacts.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);
    return await openDatabase(path,
        version: schemaVersion,
        onCreate: createSchema,
        onUpgrade: upgradeSchema);
  }

  /// Version du schéma SQLite (voir [upgradeSchema] pour l'historique).
  static const int schemaVersion = 5;

  @visibleForTesting
  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contact (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        name TEXT,
        date TEXT,
        relation TEXT,
        imageUri TEXT,
        phone TEXT
      )
    ''');
    await _createUuidIndex(db);
    await _createMessagesAndMeta(db);
  }

  static Future<void> _createUuidIndex(Database db) => db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_contact_uuid ON contact(uuid)');

  static Future<void> _createMessagesAndMeta(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        relation TEXT,
        text TEXT,
        lang TEXT DEFAULT 'en'
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_messages_relation ON messages(relation)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  @visibleForTesting
  static Future<void> upgradeSchema(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // v1/v2 : copie SQLite du profil et file de synchro maison, remplacées
      // par le cache hors-ligne de Firestore.
      await db.execute('DROP TABLE IF EXISTS profiles');
      await db.execute('DROP TABLE IF EXISTS sync_queue');
      await _createMessagesAndMeta(db);
      final cols = await db.rawQuery("PRAGMA table_info('contact')");
      if (!cols.any((c) => c['name'] == 'phone')) {
        await db.execute('ALTER TABLE contact ADD COLUMN phone TEXT');
      }
    }
    if (oldVersion < 4) {
      // Identifiant stable entre appareils. Les contacts existants gardent
      // leur ancien ID local comme UUID : c'était aussi leur ID Firestore, ils
      // restent donc associés aux mêmes documents.
      await db.execute('ALTER TABLE contact ADD COLUMN uuid TEXT');
      await db.execute(
          'UPDATE contact SET uuid = CAST(id AS TEXT) WHERE uuid IS NULL');
      await _createUuidIndex(db);
    }
    if (oldVersion < 5) {
      // Messages multilingues : la table est réimportée (messagesVersion 3).
      final cols = await db.rawQuery("PRAGMA table_info('messages')");
      if (!cols.any((c) => c['name'] == 'lang')) {
        await db.execute("ALTER TABLE messages ADD COLUMN lang TEXT DEFAULT 'en'");
      }
    }
  }

  // ==================== CONTACTS ====================

  /// Insère le contact (un UUID est attribué s'il n'en a pas).
  /// L'ID local est toujours attribué par SQLite.
  Future<int> insertContact(Contact c) async {
    final db = await database;
    final row = c.toMap()
      ..remove('id')
      ..['uuid'] = c.uuid ?? Contact.newUuid();
    return await db.insert('contact', row);
  }

  /// Remplace l'UUID d'un contact (fusion avec le même contact créé sur un
  /// autre appareil).
  Future<void> setContactUuid(int id, String uuid) async {
    final db = await database;
    await db.update('contact', {'uuid': uuid},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Contact>> getContacts() async {
    final db = await database;
    final res = await db.query('contact', orderBy: 'name COLLATE NOCASE');
    return res.map((e) => Contact.fromMap(e)).toList();
  }

  Future<int> updateContact(Contact c) async {
    final db = await database;
    final row = c.toMap();
    // Un contact reconstruit par un écran d'édition n'a pas toujours son
    // UUID : ne jamais l'effacer en base.
    if (c.uuid == null) row.remove('uuid');
    return await db.update('contact', row, where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete('contact', where: 'id = ?', whereArgs: [id]);
  }

  /// Efface les données propres à l'utilisateur (déconnexion / suppression de
  /// compte). Les messages d'anniversaire, partagés, sont conservés.
  Future<void> clearUserData() async {
    final db = await database;
    await db.delete('contact');
  }

  // ==================== MESSAGES ====================

  /// Message aléatoire pour la relation, dans la langue demandée si
  /// possible (sinon en anglais). Préfère un message propre à la relation,
  /// puis un message générique ("default").
  Future<String?> getRandomMessageByRelation(String relation,
      {String lang = 'en'}) async {
    final db = await database;
    for (final l in {lang, 'en'}) {
      for (final rel in {relation.toLowerCase(), 'default'}) {
        final res = await db.rawQuery(
            'SELECT text FROM messages WHERE relation = ? AND lang = ? ORDER BY RANDOM() LIMIT 1',
            [rel, l]);
        if (res.isNotEmpty) return res.first['text'] as String?;
      }
    }
    return null;
  }

  Future<String?> _getMeta(String key) async {
    final db = await database;
    final res =
        await db.query('meta', where: 'key = ?', whereArgs: [key], limit: 1);
    if (res.isEmpty) return null;
    return res.first['value'] as String?;
  }

  Future<void> _setMeta(String key, String value) async {
    final db = await database;
    await db.insert('meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Importe les banques de messages ([messageAssets]) si cette version
  /// n'a pas encore été importée. Remplace la table entière (les anciennes
  /// versions n'avaient que 6 messages d'exemple, qui bloquaient l'import).
  /// Retourne le nombre de messages insérés.
  Future<int> importMessagesIfEmpty() async {
    if (await _getMeta('messages_version') == '$messagesVersion') return 0;

    final byLang = <String, List<ParsedMessage>>{};
    for (final entry in messageAssets.entries) {
      final content = await rootBundle.loadString(entry.value);
      byLang[entry.key] = parseMessagesFile(content);
    }
    final total = byLang.values.fold<int>(0, (n, l) => n + l.length);
    if (total == 0) return 0;

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('messages');
      final batch = txn.batch();
      byLang.forEach((lang, messages) {
        for (final m in messages) {
          batch.insert('messages',
              {'relation': m.relation, 'text': m.text, 'lang': lang});
        }
      });
      await batch.commit(noResult: true);
    });
    await _setMeta('messages_version', '$messagesVersion');
    return total;
  }
}
