import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/message_parser.dart';

void main() {
  group('parseMessageLine', () {
    test('current asset format: default|default¦relation¦text', () {
      final m = parseMessageLine(
          "default|default¦son¦Happy birthday, my son! You're my pride.");
      expect(m?.relation, 'son');
      expect(m?.text, "Happy birthday, my son! You're my pride.");
    });

    test('apostrophes are kept (old parser split text on quotes)', () {
      final m = parseMessageLine("default|default¦friend¦Let's celebrate, it's your day!");
      expect(m?.text, "Let's celebrate, it's your day!");
    });

    test('relation|text and JSON lines', () {
      expect(parseMessageLine('FRIEND|Joyeux anniversaire !')?.relation, 'friend');
      final json = parseMessageLine('{"relation":"mother","text":"Love you"}');
      expect(json?.relation, 'mother');
      expect(json?.text, 'Love you');
    });

    test('blank or textless lines are ignored', () {
      expect(parseMessageLine('   '), isNull);
      expect(parseMessageLine('default|default¦son¦  '), isNull);
    });
  });

  test('parseMessagesFile removes duplicates', () {
    final parsed = parseMessagesFile('a|a¦son¦Hi\na|a¦son¦Hi\na|a¦daughter¦Hi\n');
    expect(parsed.length, 2);
  });

  test('section comments in the banks are not imported as messages', () {
    final parsed =
        parseMessagesFile('# --- Fils ---\nson|Joyeux anniversaire !\n\n');
    expect(parsed.length, 1);
    expect(parsed.single.relation, 'son');
  });

  test('English and French banks cover exactly the same relations', () {
    final en = parseMessagesFile(
        File('assets/messages_en.txt').readAsStringSync());
    final fr = parseMessagesFile(
        File('assets/messages_fr.txt').readAsStringSync());
    final relationsEn = en.map((m) => m.relation).toSet();
    final relationsFr = fr.map((m) => m.relation).toSet();

    expect(relationsEn, contains('default'));
    expect(relationsEn, equals(relationsFr),
        reason: 'EN seul : ${relationsEn.difference(relationsFr)}, '
            'FR seul : ${relationsFr.difference(relationsEn)}');
    expect(en.length, greaterThanOrEqualTo(140));
    expect(fr.length, greaterThanOrEqualTo(140));
  });
}
