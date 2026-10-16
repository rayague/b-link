import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:b_link/services/db_helper.dart';

/// Migrations de la base locale, exécutées sur un vrai SQLite (FFI) à partir
/// de bases reproduisant le schéma des anciennes versions de l'app.
void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('blink_db_');
  });
  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<List<String>> columns(Database db, String table) async =>
      [for (final c in await db.rawQuery("PRAGMA table_info('$table')")) c['name'] as String];

  Future<List<String>> tables(Database db) async => [
        for (final r in await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))
          r['name'] as String
      ];

  /// Schéma de la version 2 publiée (contacts, messages, meta, profils,
  /// file de synchro), avec ou sans la colonne `phone` (v1).
  Future<String> legacyDb({required int version, bool withPhone = true}) async {
    final path = p.join(tmp.path, 'contacts_v$version.db');
    final db = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: version,
          onCreate: (db, _) async {
            await db.execute('CREATE TABLE contact (id INTEGER PRIMARY KEY '
                'AUTOINCREMENT, name TEXT, date TEXT, relation TEXT, imageUri TEXT'
                '${withPhone ? ', phone TEXT' : ''})');
            await db.execute('CREATE TABLE messages (id INTEGER PRIMARY KEY '
                'AUTOINCREMENT, relation TEXT, text TEXT)');
            await db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)');
            await db.execute('CREATE TABLE profiles (id INTEGER PRIMARY KEY, uid TEXT)');
            await db.execute('CREATE TABLE sync_queue (id INTEGER PRIMARY KEY, action TEXT)');
            await db.insert('contact',
                {'id': 3, 'name': 'Alice', 'date': '1990-10-15', 'relation': 'FRIEND'});
            await db.insert('contact',
                {'id': 7, 'name': 'Maman', 'date': '1965-05-01', 'relation': 'MOTHER'});
            await db.insert('messages', {'relation': 'default', 'text': 'Happy birthday!'});
          },
        ));
    await db.close();
    return path;
  }

  Future<Database> openCurrent(String path) => factory.openDatabase(path,
      options: OpenDatabaseOptions(
        version: DBHelper.schemaVersion,
        onCreate: DBHelper.createSchema,
        onUpgrade: DBHelper.upgradeSchema,
      ));

  test('v2 -> current: obsolete tables dropped, contacts kept with legacy uuid',
      () async {
    final db = await openCurrent(await legacyDb(version: 2));

    expect(await tables(db), isNot(contains('profiles')));
    expect(await tables(db), isNot(contains('sync_queue')));
    expect(await columns(db, 'contact'), containsAll(['uuid', 'phone']));
    expect(await columns(db, 'messages'), contains('lang'));

    final contacts = await db.query('contact', orderBy: 'id');
    // L'UUID reprend l'ancien ID : c'était l'ID du document Firestore.
    expect(contacts.map((c) => c['uuid']), ['3', '7']);
    expect(contacts.map((c) => c['name']), ['Alice', 'Maman']);

    // Les anciens messages sont marqués en anglais jusqu'au réimport.
    final msg = await db.query('messages');
    expect(msg.single['lang'], 'en');
    await db.close();
  });

  test('v1 (no phone column) -> current', () async {
    final db = await openCurrent(await legacyDb(version: 1, withPhone: false));
    expect(await columns(db, 'contact'), containsAll(['phone', 'uuid']));
    expect((await db.query('contact')).length, 2);
    await db.close();
  });

  test('uuid is unique after migration (no duplicate Firestore ids)', () async {
    final db = await openCurrent(await legacyDb(version: 2));
    expect(
      () => db.insert('contact', {'uuid': '3', 'name': 'Doublon'}),
      throwsA(isA<DatabaseException>()),
    );
    await db.close();
  });

  test('fresh install creates the current schema', () async {
    final db = await openCurrent(p.join(tmp.path, 'fresh.db'));
    expect(await tables(db), containsAll(['contact', 'messages', 'meta']));
    expect(await tables(db), isNot(contains('profiles')));
    expect(await columns(db, 'contact'), containsAll(['uuid', 'phone']));
    expect(await columns(db, 'messages'), contains('lang'));
    expect(await db.getVersion(), DBHelper.schemaVersion);
    await db.close();
  });

  test('migration is idempotent across app restarts', () async {
    final path = await legacyDb(version: 2);
    await (await openCurrent(path)).close();
    final again = await openCurrent(path); // relance : aucune migration
    expect((await again.query('contact')).length, 2);
    await again.close();
  });
}
