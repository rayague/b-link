import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// dart:io not required here
import '../models/contact.dart';
import '../models/user_profile.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'message_parser.dart' as parser;
import 'db_interface.dart';

class DBHelper implements DBInterface {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

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
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
      // ensure a small meta table exists for fast flags
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meta (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      // also ensure new tables exist when opening older DBs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT UNIQUE,
          name TEXT,
          birthDate TEXT,
          birthTime TEXT,
          timezone TEXT,
          zodiac TEXT,
          birthplace TEXT,
          socialLinks TEXT,
          bio TEXT,
          isPublic INTEGER DEFAULT 0,
          publicName INTEGER DEFAULT 0,
          publicBirthDate INTEGER DEFAULT 0,
          publicBirthPlace INTEGER DEFAULT 0,
          publicSocials INTEGER DEFAULT 0,
          birthDayKey TEXT,
          lastSyncedAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action TEXT,
          uid TEXT,
          payload TEXT,
          status TEXT DEFAULT 'pending',
          attempts INTEGER DEFAULT 0,
          lastError TEXT,
          nextRetryAt TEXT,
          createdAt TEXT
        )
      ''');
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT UNIQUE,
          name TEXT,
          birthDate TEXT,
          birthTime TEXT,
          timezone TEXT,
          zodiac TEXT,
          socialLinks TEXT,
          bio TEXT,
          lastSyncedAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action TEXT,
          uid TEXT,
          payload TEXT,
          status TEXT DEFAULT 'pending',
          attempts INTEGER DEFAULT 0,
          lastError TEXT,
          nextRetryAt TEXT,
          createdAt TEXT
        )
      ''');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contact (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        date TEXT,
        relation TEXT,
        imageUri TEXT,
        phone TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        relation TEXT,
        text TEXT
      )
    ''');
    // seed some default messages
    final seed = [
      {'relation': 'default', 'text': 'Happy birthday, {name}! Wishing you a wonderful day.'},
      {'relation': 'default', 'text': 'Happy birthday {name}! Hope you have an amazing day ahead.'},
      {'relation': 'friend', 'text': 'Hey {name}, happy birthday! Let’s celebrate soon 🎉'},
      {'relation': 'friend', 'text': 'Happy birthday to my dear friend {name} — have a blast!'},
      {'relation': 'father', 'text': 'Happy birthday, Dad ({name}). Thank you for everything.'},
      {'relation': 'father', 'text': 'Wishing you a wonderful birthday, Father. Love you.'}
    ];
    for (final row in seed) {
      await db.insert('messages', row as Map<String, Object?>);
    }
    // create index to speed up lookups by relation
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_relation ON messages(relation)');
  }

  // Simple migration helper: if phone column missing, add it
  Future<void> ensurePhoneColumn() async {
    final db = await database;
    final res = await db.rawQuery("PRAGMA table_info('contact')");
    final hasPhone = res.any((r) => r['name'] == 'phone');
    if (!hasPhone) {
      await db.execute('ALTER TABLE contact ADD COLUMN phone TEXT');
    }
  }

  Future<int> insertContact(Contact c) async {
    final db = await database;
    return await db.insert('contact', c.toMap());
  }

  /// Insert or update a profile in the local SQLite `profiles` table.
  /// If profile.uid exists, try to update by uid, otherwise insert.
  Future<int> upsertProfileToDb(UserProfile p) async {
    final db = await database;
    final Map<String, Object?> row = {
      'uid': p.uid,
      'name': p.name,
      'birthDate': p.birthDate.toIso8601String(),
      'birthTime': p.birthTime,
      'timezone': p.timezone,
      'zodiac': p.zodiac,
      'birthplace': p.birthplace,
      'socialLinks': p.socialLinks == null ? null : p.toJson()['socialLinks'] == null ? null : p.toEncodedJson(),
      'bio': p.bio,
      'isPublic': p.isPublic ? 1 : 0,
      'publicName': p.publicName ? 1 : 0,
      'publicBirthDate': p.publicBirthDate ? 1 : 0,
      'publicBirthPlace': p.publicBirthPlace ? 1 : 0,
      'publicSocials': p.publicSocials ? 1 : 0,
      'birthDayKey': p.birthDayKey,
      'lastSyncedAt': p.lastSyncedAt?.toIso8601String(),
    };
    if (p.uid != null && p.uid!.isNotEmpty) {
      final existing = await db.query('profiles', where: 'uid = ?', whereArgs: [p.uid], limit: 1);
      if (existing.isNotEmpty) {
        return await db.update('profiles', row, where: 'uid = ?', whereArgs: [p.uid]);
      }
    }
    return await db.insert('profiles', row);
  }

  Future<UserProfile?> getProfileByUid(String uid) async {
    final db = await database;
    final res = await db.query('profiles', where: 'uid = ?', whereArgs: [uid], limit: 1);
    if (res.isEmpty) return null;
    final r = res.first;
      try {
        final socialRaw = r['socialLinks'] as String?;
        Map<String, String>? social;
        if (socialRaw != null) {
          try {
            final parsed = jsonDecode(socialRaw);
            if (parsed is Map) social = Map<String, String>.from(parsed.map((k, v) => MapEntry(k.toString(), v.toString())));
          } catch (_) {}
        }
        return UserProfile(
          uid: r['uid'] as String?,
          name: r['name'] as String? ?? '',
          birthDate: DateTime.parse(r['birthDate'] as String),
          birthTime: r['birthTime'] as String?,
          timezone: r['timezone'] as String?,
          zodiac: r['zodiac'] as String?,
          birthplace: r['birthplace'] as String?,
          socialLinks: social,
          bio: r['bio'] as String?,
          lastSyncedAt: r['lastSyncedAt'] == null ? null : DateTime.parse(r['lastSyncedAt'] as String),
          isPublic: (r['isPublic'] as int? ?? 0) == 1,
          publicName: (r['publicName'] as int? ?? 0) == 1,
          publicBirthDate: (r['publicBirthDate'] as int? ?? 0) == 1,
          publicBirthPlace: (r['publicBirthPlace'] as int? ?? 0) == 1,
          publicSocials: (r['publicSocials'] as int? ?? 0) == 1,
          birthDayKey: r['birthDayKey'] as String?,
        );
      } catch (e) {
        return null;
      }
  }


  /// Query public profiles by birthDayKey (format MM-DD)
  Future<List<Map<String, dynamic>>> queryPublicProfilesByDay(String birthDayKey, {int limit = 50}) async {
    final db = await database;
    final res = await db.query('profiles', where: 'isPublic = ? AND birthDayKey = ?', whereArgs: [1, birthDayKey], limit: limit);
    return res.map((r) => Map<String, dynamic>.from(r)).toList();
  }
  @override
  Future<int> enqueueSync(String action, String? uid, String payload) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'action': action,
      'uid': uid,
      'payload': payload,
      'status': 'pending',
      'attempts': 0,
      'lastError': null,
      'nextRetryAt': null,
      'createdAt': DateTime.now().toIso8601String()
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 50}) async {
    final db = await database;
    // Only select items that are pending and either have no nextRetryAt or nextRetryAt <= now
    final now = DateTime.now().toIso8601String();
    final res = await db.rawQuery(
        "SELECT * FROM sync_queue WHERE status = ? AND (nextRetryAt IS NULL OR nextRetryAt <= ?) ORDER BY createdAt ASC LIMIT ?",
        ['pending', now, limit]);
    return res.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  @override
  Future<void> markSyncItemDone(int id) async {
    final db = await database;
    await db.update('sync_queue', {'status': 'done'}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> markSyncItemFailed(int id, String error, {int attempts = 1, Duration? backoff}) async {
    final db = await database;
    final nextRetry = backoff == null ? null : DateTime.now().add(backoff).toIso8601String();
    await db.update('sync_queue', {'attempts': attempts, 'lastError': error, 'nextRetryAt': nextRetry}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> markSyncItemPermanentlyFailed(int id, String error) async {
    final db = await database;
    await db.update('sync_queue', {'status': 'failed', 'lastError': error}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> requeueSyncItem(int id) async {
    final db = await database;
    await db.update('sync_queue', {'status': 'pending', 'attempts': 0, 'lastError': null, 'nextRetryAt': null}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSyncItem(int id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setProfileLastSynced(String uid, String iso) async {
    final db = await database;
    await db.update('profiles', {'lastSyncedAt': iso}, where: 'uid = ?', whereArgs: [uid]);
  }

  Future<int> insertMessage(String relation, String text) async {
    final db = await database;
    return await db.insert('messages', {'relation': relation, 'text': text});
  }

  Future<List<String>> getMessagesByRelation(String relation) async {
    final db = await database;
    final res = await db.query('messages', where: 'relation = ? OR relation = ?', whereArgs: [relation.toLowerCase(), 'default']);
    return res.map((r) => r['text'] as String).toList();
  }

  Future<String?> getRandomMessageByRelation(String relation) async {
    final db = await database;
    final res = await db.rawQuery('SELECT text FROM messages WHERE relation = ? OR relation = ? ORDER BY RANDOM() LIMIT 1', [relation.toLowerCase(), 'default']);
    if (res.isEmpty) return null;
    return res.first['text'] as String?;
  }

  Future<int> _messagesCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM messages');
    return (res.first['c'] as int?) ?? 0;
  }

  /// Parse messages from a JS-like content string and return list of maps {relation, text}
  List<Map<String, String>> parseMessagesFromContent(String content) => parser.parseMessagesFromContent(content);

  /// Insert parsed messages into DB using a transaction. Returns number inserted.
  Future<int> importMessagesFromString(String content) async {
    final db = await database;
    final parsed = parseMessagesFromContent(content);
    var inserted = 0;
    await db.transaction((txn) async {
      for (final row in parsed) {
        await txn.insert('messages', {'relation': (row['relation'] ?? 'default'), 'text': row['text']});
        inserted++;
      }
    });
    // create index if missing
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_relation ON messages(relation)');
    return inserted;
  }

  Future<String?> _getMeta(String key) async {
    final db = await database;
    final res = await db.query('meta', where: 'key = ?', whereArgs: [key], limit: 1);
    if (res.isEmpty) return null;
    return res.first['value'] as String?;
  }

  Future<void> _setMeta(String key, String value) async {
    final db = await database;
    await db.insert('meta', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Import messages from assets/messages.txt if messages table is empty.
  /// File format: each line either JSON {"relation":"friend","text":"..."} or 'relation|text' or plain text (falls back to default).
  /// Returns number of messages inserted. Uses a transaction for performance.
  Future<int> importMessagesIfEmpty() async {
    // Fast-check: if we've already seeded messages, skip
    final seededFlag = await _getMeta('messages_seeded');
    if (seededFlag == 'true') return 0;
    final count = await _messagesCount();
    if (count > 0) {
      // mark as seeded for future runs
      await _setMeta('messages_seeded', 'true');
      return 0;
    }
    var inserted = 0;
    try {
      final content = await rootBundle.loadString('assets/messages.txt');
      // Use shared parser (pure Dart) to extract relation/text pairs
      final parsed = parser.parseMessagesFromContent(content);
      if (parsed.isNotEmpty) {
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
        // Fallback: line-by-line parsing (JSON lines, pipe format or plain text)
        final lines = content.split(RegExp(r'\r?\n'));
        final db = await database;
        await db.transaction((txn) async {
          for (final raw in lines) {
            final line = raw.trim();
            if (line.isEmpty) continue;
            try {
              if (line.startsWith('{')) {
                final m = Map<String, dynamic>.from(jsonDecode(line));
                final rel = (m['relation'] ?? 'default').toString().toLowerCase();
                final txt = (m['text'] ?? '').toString();
                if (txt.isNotEmpty) {
                  await txn.insert('messages', {'relation': rel, 'text': txt});
                  inserted++;
                }
                continue;
              }
            } catch (_) {}
            if (line.contains('|')) {
              final parts = line.split('|');
              final rel = parts.first.trim().toLowerCase();
              final txt = parts.sublist(1).join('|').trim();
              if (txt.isNotEmpty) {
                await txn.insert('messages', {'relation': rel, 'text': txt});
                inserted++;
              }
            } else {
              await txn.insert('messages', {'relation': 'default', 'text': line});
              inserted++;
            }
          }
        });
      }
    } catch (e) {
      // ignore errors silently; app can still work with built-in seeds
    }
    if (inserted > 0) await _setMeta('messages_seeded', 'true');
    return inserted;
  }

  String _mapCategoryToRelation(String cat) {
    final m = cat.toLowerCase();
    // map some known category variable names to relation keys used in DB
    final map = {
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
      'father': 'father',
      'mother': 'mother',
      'auntie': 'auntie',
      'uncle': 'uncle',
      'cousin': 'cousin',
      'niece': 'niece',
      'nephew': 'nephew',
      'grandson': 'grand-son',
      'granddaughter': 'grand-daughter',
      'grandfather': 'grand-father',
      'grandmother': 'grand-mother',
      'godfather': 'god-father',
      'godmother': 'god-mother',
      'best friend': 'bestfriend'
    };
    return map[m] ?? 'default';
  }

  Future<List<Contact>> getContacts() async {
    final db = await database;
    final res = await db.query('contact', orderBy: 'name COLLATE NOCASE');
    return res.map((e) => Contact.fromMap(e)).toList();
  }

  Future<int> updateContact(Contact c) async {
    final db = await database;
    return await db.update('contact', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete('contact', where: 'id = ?', whereArgs: [id]);
  }
}
