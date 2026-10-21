import 'dart:io';

import 'package:b_link/services/db_helper.dart';
import 'package:flutter/services.dart';
import 'package:b_link/services/message_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Les messages d'anniversaire ne se répètent pas : vrai SQLite (FFI).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    // DBHelper place sa base dans le dossier de l'app (path_provider).
    final tmp = await Directory.systemTemp.createTemp('blink_msg_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => tmp.path);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await DBHelper().database;
    await db.delete('messages');
    for (final (rel, text) in [
      ('friend', 'Ami 1 {name}'),
      ('friend', 'Ami 2 {name}'),
      ('friend', 'Ami 3 {name}'),
      ('default', 'Général 1 {name}'),
      ('default', 'Général 2 {name}'),
    ]) {
      await db.insert('messages', {'relation': rel, 'text': text, 'lang': 'fr'});
    }
    await db.insert('messages',
        {'relation': 'friend', 'text': 'Friend EN {name}', 'lang': 'en'});
  });

  test('no message comes back before all of them were shown', () async {
    final repo = MessageRepository();
    final shown = [
      for (var i = 0; i < 5; i++)
        await repo.getRandomForRelation('FRIEND', 'Léa', lang: 'fr'),
    ];
    expect(shown.toSet().length, 5);
    // Ceux propres à la relation d'abord, puis les messages généraux.
    expect(shown.take(3).every((s) => s.startsWith('Ami')), isTrue);
    expect(shown.every((s) => s.endsWith('Léa')), isTrue);

    // Banque épuisée : un nouveau tour commence, toujours sans erreur.
    final sixth = await repo.getRandomForRelation('FRIEND', 'Léa', lang: 'fr');
    expect(shown, contains(sixth));
  });

  test('history is kept per relation and per language', () async {
    final repo = MessageRepository();
    await repo.getRandomForRelation('FRIEND', 'Léa', lang: 'fr');
    final en = await repo.getRandomForRelation('FRIEND', 'Léa', lang: 'en');
    expect(en, 'Friend EN Léa');
    final mother = await repo.getRandomForRelation('MOTHER', 'Maman', lang: 'fr');
    expect(mother, startsWith('Général'));
  });
}
